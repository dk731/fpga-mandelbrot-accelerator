#!/usr/bin/env python3
from vunit import VUnit
from vunit.ui.results import Results
from os import path
import mand
import numpy as np
from fixedpoint import FixedPoint

import matplotlib

matplotlib.use("tkagg")
import matplotlib.pyplot as plt

RUN_PATH = path.abspath(path.dirname(__file__))
MAND_CORE_PATH = path.join(RUN_PATH, "..")
MULTIPLY_PATH = path.join(RUN_PATH, "..", "..", "multiply_block")

# create VUnit project
prj = VUnit.from_argv()

# add OSVVM library
prj.add_osvvm()
prj.add_verification_components()

# add custom libraries
prj.add_library("mand")

# add sources and testbenches
prj.library("mand").add_source_file(
    path.join(MAND_CORE_PATH, "src", "mandelbrot_core.vhd")
)
prj.library("mand").add_source_file(
    path.join(MULTIPLY_PATH, "src", "multiply_block.vhd")
)

# Add testbench
prj.library("mand").add_source_file(path.join(MAND_CORE_PATH, "tb", "tb.vhd"))


def generate_test_benches(
    width=10,
    aspect=4 / 3,
    mand_width=3.4,
    start_point=(-0.65, 0),
    fixed_size=16,
    fixed_integer_size=4,
    max_iterations=10,
    itterations_size=64,
) -> tuple[list, np.ndarray]:
    # frame parameters

    height = round(width / aspect)
    mand_height = mand_width / aspect

    start_x = start_point[0] - mand_width / 2
    start_y = start_point[1] + mand_height / 2
    floating_size = fixed_size - fixed_integer_size

    python_mand_image = np.zeros((height, width), dtype=np.float64)
    vuint_configs = []

    for row in range(height):
        for col in range(width):
            x = start_x + col * mand_width / width
            y = start_y - row * mand_height / height

            itterations = mand.calculate_mandelbrot(x, y, max_iterations)

            input_x = str(
                FixedPoint(
                    x, signed=1, m=fixed_integer_size, n=floating_size, str_base=2
                )
            ).rjust(2048, "0")

            input_y = str(
                FixedPoint(
                    y, signed=1, m=fixed_integer_size, n=floating_size, str_base=2
                )
            ).rjust(2048, "0")

            vuint_configs.append(
                {
                    "name": f"{fixed_size}_{fixed_integer_size}___{row};{col};{max_iterations}___",
                    "generics": {
                        "FIXED_SIZE": fixed_size,
                        "FIXED_INTEGER_SIZE": fixed_integer_size,
                        "ITERATIONS_SIZE": itterations_size,
                        "INPUT_X": input_x,
                        "INPUT_Y": input_y,
                        "INPUT_ITERATIONS_MAX": "".join(
                            [
                                "1" if max_iterations & (1 << i) > 0 else "0"
                                for i in range(2048)
                            ]
                        )[::-1],
                    },
                }
            )

            python_mand_image[row, col] = itterations

    return vuint_configs, python_mand_image


def plot_tests_result(tests_result: list, original_image: np.ndarray) -> None:
    hdl_image = np.zeros_like(original_image)
    for result in tests_result:
        col, row, result = result
        hdl_image[row, col] = result

    _, ax = plt.subplots(1, 2, figsize=(10, 5))
    ax[0].imshow(original_image)
    ax[0].set_title("Python Mandelbrot")
    ax[0].grid(False)
    ax[1].imshow(hdl_image)
    ax[1].set_title("HDL Mandelbrot")
    ax[1].grid(False)

    plt.savefig(path.join(RUN_PATH, "results-comp.png"))
    plt.show()


def test_result_parser(original_image):

    def inner(results: Results):
        RESULT_START_TAG = "%MAND_CORE_RESULT_START%"
        RESULT_END_TAG = "%MAND_CORE_RESULT_END%"

        tests = results.get_report().tests
        results = []

        for test_name, test_result in tests.items():
            output_path = path.join(test_result.path, "output.txt")

            with open(output_path, "r") as f:
                test_output = f.read()

            result_start_ind = test_output.find(RESULT_START_TAG) + len(
                RESULT_START_TAG
            )
            result_end_ind = test_output.find(RESULT_END_TAG)

            result_value = test_output[result_start_ind:result_end_ind]
            result_value = int(result_value, 2)

            point_coords = test_name.split("___")[1]
            row, col, max_itterations = point_coords.split(";")
            col = int(col)
            row = int(row)
            max_itterations = int(max_itterations)

            result_value = result_value / max_itterations

            results.append((col, row, result_value))

        plot_tests_result(results, original_image)

    return inner


test_configs, python_mand_image = generate_test_benches(
    width=5, fixed_integer_size=4, fixed_size=64, max_iterations=100
)
for config in test_configs:
    prj.library("mand").test_bench("tb").test("test_point_calculation").add_config(
        **config
    )


# run VUnit simulation
prj.main(test_result_parser(python_mand_image))
