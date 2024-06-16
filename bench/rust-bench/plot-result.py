import matplotlib

matplotlib.use("tkagg")
import matplotlib.pyplot as plt

# AMD Ryzen 7 7700 8-Core Processor, 4.3 GHz
# Ubuntu 20.04, Linux 6.5.0
# 32GB DDR5
# 1TB NVMe SSD
pc_results = [
    (8, 656360660),
    (16, 591629608),
    (32, 556760071),
    (64, 339173176),
    (128, 129761740),
]

# DE10-Nano, Cyclone V SoC
# Debian 12, Linux 6.1.68
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
