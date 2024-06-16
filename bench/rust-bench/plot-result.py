import matplotlib

matplotlib.use("tkagg")
import matplotlib.pyplot as plt

pc_results = [
    # (8, 98823994465856.31),
    (16, 497014305.3470466),
    (32, 525937757.869748),
    (64, 328267428.9593108),
    (128, 104028539.73886263),
]

fpga_results = [
    (8, 500_000),
    (16, 500_000),
    (32, 500_000),
    (64, 500_000),
    (128, 500_000),
    (256, 500_000),
]


fig, ax1 = plt.subplots()

# ax1.title("Fixed Point Size vs Performance")

(line1,) = ax1.plot(
    [x[0] for x in pc_results],
    [x[1] / 1_000_000 for x in pc_results],
    label="PC",
    color="red",
)

ax1.set_xlabel("Fixed Point Size, bits")
ax1.set_ylabel("M Itterations / Per Second", color="red")
ax1.legend()

ax2 = ax1.twinx()

ax2.set_xlabel("Fixed Point Size, bits")
ax2.set_ylabel("M Itterations / Per Second", color="blue")
ax2.legend()

(line2,) = ax2.plot(
    [x[0] for x in fpga_results],
    [x[1] / 1_000_000 for x in fpga_results],
    label="FPGA",
    color="blue",
)

ax2.grid()
ax2.set_xticks([x[0] for x in fpga_results])

lines = [line1, line2]
labels = [line.get_label() for line in lines]
ax1.legend(lines, labels, loc="best")

fig.suptitle("Fixed Point Size vs Performance")

fig.tight_layout()
plt.show()
