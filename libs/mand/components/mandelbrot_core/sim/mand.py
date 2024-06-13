import colorsys
import math
import os
import numpy as np


def power_color(distance, exp, const, scale) -> np.ndarray:  # [uint8, uint8, uint8]
    color = distance**exp
    rgb = colorsys.hsv_to_rgb(const + scale * color, 1 - 0.6 * color, 0.9)
    return np.array(
        [int(rgb[0] * 255), int(rgb[1] * 255), int(rgb[2] * 255)], dtype=np.uint8
    )


# https://en.wikipedia.org/wiki/Mandelbrot_set
# Returns normalized value between 0 and 1
def calculate_mandelbrot(x0, y0, max_itterations) -> float:
    x = 0
    y = 0

    for itt in range(max_itterations):

        tmp_x = x**2 - y**2 + x0

        print(f"{itt}:   x: {x}; y: {y}; temp_x: {tmp_x}; x^2: {x**2}; y^2: {y**2}")

        y = 2 * x * y + y0
        x = tmp_x

        if x**2 + y**2 > 2**2:
            return itt / max_itterations

    return 1
