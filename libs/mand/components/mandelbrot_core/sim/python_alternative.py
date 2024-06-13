from fixedpoint import FixedPoint

# -- Algorithm:
# -- https://en.wikipedia.org/wiki/Mandelbrot_set
# --
# --   x0 - real part of the initial value
# --   y0 - imaginary part of the initial value
# --
# --     x := 0.0
# --     y := 0.0
# --     iteration := 0
# --     max_iteration := 1000
# --
# --     while (                                                                  # while_check_start
# --              x^2 +                                                           # square_x
# --              y^2 ≤                                                           # square_y
# --              2^2 AND iteration < max_iteration)                              # while_check_end
# --     do
# --
# --         xtemp := x^2 - y^2 + x0                                              # loop_body
# --         y := 2*x*y + y0
# --         x := xtemp
# --         iteration := iteration + 1


def mandelbrot_core(x0: FixedPoint, y0: FixedPoint, max_iter: int) -> int:
    INTEGER_SIZE = x0.m
    FRACTION_SIZE = x0.n

    x = FixedPoint(0, signed=1, m=INTEGER_SIZE, n=FRACTION_SIZE)
    y = FixedPoint(0, signed=1, m=INTEGER_SIZE, n=FRACTION_SIZE)

    for itt in range(max_iter):
        x_squared = x * x
        y_squared = y * y

        if x_squared + y_squared > 4:
            return itt

        xtemp = x_squared - y_squared + x0
        y = 2 * x * y + y0
        x = xtemp

    return max_iter
