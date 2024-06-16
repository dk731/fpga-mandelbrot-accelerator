import time
import requests
from fixedpoint import FixedPoint
import numpy as np

import matplotlib

matplotlib.use("tkagg")
import matplotlib.pyplot as plt
import concurrent.futures
import threading


WIDTH = 1000
ASPECT_RATIO = 4 / 3
MAND_WIDTH = 3.4
MAX_ITTERATIONS = 1000

HEIGHT = round(WIDTH / ASPECT_RATIO)
MAND_HEIGHT = MAND_WIDTH / ASPECT_RATIO

START_X = -0.65 - MAND_WIDTH / 2
START_Y = 0 + MAND_HEIGHT / 2

FIXED_SIZE = 128
FIXED_INT = 5
FIXED_FRAC = FIXED_SIZE - FIXED_INT
F = lambda x: FixedPoint(x, signed=1, m=FIXED_INT, n=FIXED_FRAC)

result_image = np.zeros((HEIGHT, WIDTH), dtype=np.float64)


def make_request(col, row):
    x = START_X + col * MAND_WIDTH / WIDTH
    y = START_Y - row * MAND_HEIGHT / HEIGHT

    x_f = F(x)
    y_f = F(y)

    resp = requests.post(
        "http://fpga:8000/calculate",
        json={
            "x": hex(x_f),
            "y": hex(y_f),
            "max_itterations": hex(MAX_ITTERATIONS),
        },
    )

    if resp.status_code != 200:
        print("Error response for calculation request: ", resp.text)
        return None, None, None

    itterations = int(resp.json()["itterations"], base=16) / MAX_ITTERATIONS
    return row, col, itterations


TOTAL_POINTS = WIDTH * HEIGHT
finished_points = 0


def print_status():
    while True:
        print("Status: ", round(finished_points / TOTAL_POINTS * 100, 2), "%")
        time.sleep(1)


threading.Thread(target=print_status).start()


# threading.Thread(target=draw_progress).start()
last_update = time.time()

with concurrent.futures.ThreadPoolExecutor(max_workers=16) as executor:
    # Create a list of futures
    futures = [
        executor.submit(make_request, col, row)
        for col in range(WIDTH)
        for row in range(HEIGHT)
    ]

    # Process the results as they complete
    for future in concurrent.futures.as_completed(futures):
        row, col, itterations = future.result()
        if row is not None and col is not None:
            finished_points += 1
            result_image[row, col] = itterations


plt.imshow(result_image)
plt.show()
