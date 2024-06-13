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

# FIXED_SIZE : natural := 16; -- Size of the input i_x and i_y values
# FIXED_INTEGER_SIZE : natural := 4; -- Fixed floating point integer bits for the i_x and i_y inputs
# ITERATIONS_SIZE : natural := 64; -- Size of the output iterations value (unsigned long by default)

# INPUT_X : natural := 58696; -- X coordinate of the input
# INPUT_Y : natural := 2474; -- Y coordinate of the input
# INPUT_ITERATIONS_MAX : natural := 5; -- Maximum number of iterations

# test_points = [
#     (0xE548, 0x09AA, 3, 5),
#     (0xF029, 0x09AA, 4, 5),
#     (0xF256, 0x09AA, 5, 5),
# ]

# for i, test_point in enumerate(test_points):
#     prj.library("mand").test_bench("tb").test("test_point_calculation").add_config(
#         **{
#             "name": f"___{i};{i}___",
#             "generics": {
#                 "FIXED_SIZE": 16,
#                 "FIXED_INTEGER_SIZE": 4,
#                 "ITERATIONS_SIZE": 64,
#                 "INPUT_X": test_point[0],
#                 "INPUT_Y": test_point[1],
#                 "INPUT_ITERATIONS_MAX": test_point[3],
#             },
#         }
#     )


# prj.library("rtu").test_bench("tb").test("position_coverage").add_config(
#     name="data_width=32", generics=dict(DATA_WIDTH=32)
# )


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

    python_mand_image = np.zeros((height, width), dtype=np.uint8)
    vuint_configs = []

    for row in range(height):
        for col in range(width):
            x = start_x + col * mand_width / width
            y = start_y - row * mand_height / height

            itterations = mand.calculate_mandelbrot(x, y, max_iterations)
            vuint_configs.append(
                {
                    "name": f"___{row};{col};{max_iterations}___",
                    "generics": {
                        "FIXED_SIZE": fixed_size,
                        "FIXED_INTEGER_SIZE": fixed_integer_size,
                        "ITERATIONS_SIZE": itterations_size,
                        "INPUT_X": 2147483647,
                        "INPUT_Y": 1,
                        "INPUT_ITERATIONS_MAX": max_iterations,
                    },
                }
            )

            python_mand_image[row, col] = 255 - itterations * 255

    print(vuint_configs)

    return vuint_configs, python_mand_image


def plot_tests_result(tests_result: list, original_image: np.ndarray) -> None:
    hdl_image = np.zeros_like(original_image)
    for result in tests_result:
        col, row, result = result
        hdl_image[row, col] = 255 - result * 255

    _, ax = plt.subplots(1, 2, figsize=(10, 5))
    ax[0].imshow(original_image)
    ax[0].set_title("Python Mandelbrot")
    ax[0].grid()
    ax[1].imshow(hdl_image)
    ax[1].set_title("HDL Mandelbrot")

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
    width=5, fixed_integer_size=4, fixed_size=64
)
for config in test_configs:
    prj.library("mand").test_bench("tb").test("test_point_calculation").add_config(
        **config
    )

# run VUnit simulation
prj.main(test_result_parser(python_mand_image))
