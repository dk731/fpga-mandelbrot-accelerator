---
marp: true
theme: uncover
class: invert
paginate: true
html: true
---

<style>
section::after {
  content: attr(data-marpit-pagination) "/" attr(data-marpit-pagination-total);
}
</style>

![w:280](https://www.rtu.lv/images/logo_en.svg?v=1.0)

Fundamentals of Digital Electronic Systems Design using HDL(1),23/24-P

### Study Project

_Demid Kaidalov_
_3rd course, bachelor's_
_211REC096_


---
<style scoped>section { justify-content: start; }</style>

# Mandelbrot Set

![bg h:400](https://miro.medium.com/v2/resize:fit:1100/1*EE2hSYq5WNRP9pt7Qx_qiQ.png)
![bg h:300](https://img.cdn.cratecode.com/info/headerimg/mandelbrot-set.fvku.webp?format=webp)
![bg h:400](https://i.ytimg.com/vi/b005iHf8Z3g/maxresdefault.jpg)

---
<style scoped>section { justify-content: start; }</style>

# Problem

![bg left](https://upload.wikimedia.org/wikipedia/commons/a/a4/Mandelbrot_sequence_new.gif)
$f_c(z) = z^2 + c$

$z_0 = 0$

<br/>
<br/>

$2^{64} = 1.845e19$

---

![bg right](./deepest-zoom.png)


Center Point: 
$-1.74...75 - j0.00...55$

<br/>

Zoom: $1.7x10^{301}$

<br/>

Float Size: **_640_** Bytes !!!

<br/>

Calculation Time: **_Months_** !!!

---

<style scoped>section { justify-content: start; }</style>

# Solution
#### **Custom Hardware:**
- _ASIC_ - Custom Chip
- _TinyTapeout_ - Small ASIC
- _**FPGA**_ - HDL Design

![bg vertical left](https://www.macrofab.com/assets/uploads/og/how-to-build-a-chip-factory.webp)
![bg](https://hackaday.com/wp-content/uploads/2023/03/Tiny-Tapeout-3.png?w=800)
![bg](https://upload.wikimedia.org/wikipedia/commons/f/fa/Altera_StratixIVGX_FPGA.jpg)

--- 

<style scoped>section { justify-content: start; }</style>

# FPGA Design

- Multiply Block
- Mandelbrot Core
- Mandelbrot Cluster Avalon-MM
- HTTP Proxy

![bg right w:600](./project-structure.png)

---
<style scoped>section { justify-content: start;  }</style>

# Multiply Block

![h:500](./multiply-block-rtl.png)

---
<style scoped>section { justify-content: start; }</style>

# Mandelbrot Core

```python
def mandelbrot_core(x0, y0, max_iter):
    x = 0
    y = 0

    for itt in range(max_iter):
        if x ** 2 + y ** 2 > 2 ** 2:
            return itt
            
        xtemp =  x ** 2 - y ** 2 + x0
        y = 2 * x * y + y0
        x = xtemp

    return max_iter
```

![bg left](./mand-core-rtl.png)

---
<style scoped>section { justify-content: start; background-position: 100px 0; background-size: cover; }</style>

# Simulation

VHDL Test Bench
```vhdl
while test_suite loop
    if run("test_point_calculation") then
        -- Reset core
        core_reset <= '1';
        wait for 50 ns;
        core_reset <= '0';
        wait for 50 ns;

        ...

        check(not timeout_occurred, "Timeout occurred during calculation");

        log("%MAND_CORE_RESULT_START%" & to_string(core_result) & "%MAND_CORE_RESULT_END%" & LF);

    end if;
end loop;
```

Python Runner
```python
test_configs, python_mand_image = generate_test_benches(
    width=20, fixed_integer_size=4, fixed_size=124, max_iterations=24
)
for config in test_configs:
    prj.library("mand").test_bench("tb").test("test_point_calculation").add_config(
        **config
    )


# run VUnit simulation
prj.main(test_result_parser(python_mand_image))
```


![bg right](./questa-simulation.png)

---
<style scoped>section { justify-content: start; background-position: 100px 0; background-size: cover; }</style>

# Simulation Results

1) Wihout overflow check or rounding logic
2) Without overflow check
3) Final version

![bg left vertical h:280](../libs/mand/components/mandelbrot_core/sim/results-comp-without-overflow.png)
![bg h:280](../libs/mand/components/mandelbrot_core/sim/results-comp-without-round.png)
![bg h:280](../libs/mand/components/mandelbrot_core/sim/results-comp.png)

--- 
<style scoped>section { justify-content: start; background-position: 100px 0; background-size: cover; }</style>

# Cluster Avalon-MM

Final Configuration:
- **6** Cores
- **128** Bit Fixed Point
- Compilation time: ~**15** minutes

![bg right vertical h:400](./cluster-custom-ip.png)
![bg h:150](./cluster-avalon-rtl.png)
![bg h:250](./cluster-platform-designer.png)

---
<style scoped>section { justify-content: start; }</style>

# HPC Runtime

<br/>

Full Custom (latest):
1) Boot loader: **U-Boot**
2) Linux Kernel: **6.1.68**
3) RootFS: **Debian 12**

![bg left vertical w:400](https://vazaha.blog/storage/BOcYcQUB7NnnZp27efZcQ2JkMOlUEQM2HGJKSajw.png)
![bg h:200](https://i.ytimg.com/vi/JDfo2Lc7iLU/maxresdefault.jpg)
![bg h:200](https://upload.wikimedia.org/wikipedia/commons/thumb/9/9e/U-Boot_Logo.svg/1200px-U-Boot_Logo.svg.png)

---

<style scoped>section { justify-content: start; } </style>

# C Test

![bg right](https://upload.wikimedia.org/wikipedia/commons/thumb/1/18/C_Programming_Language.svg/1853px-C_Programming_Language.svg.png)

```C
struct __attribute__((__packed__)) mand_cluster
{
    uint64_t cores_count;
    uint64_t fixed_size;
    uint64_t fixed_integer_size;

    uint64_t command;
    uint64_t command_status;
    uint64_t core_address;
    uint8_t cores_busy_flag[128 / 8];
    uint8_t cores_valid_flag[128 / 8];

    uint64_t core_result;
    uint64_t core_busy;
    uint64_t core_valid;

    uint64_t core_max_itterations;
    uint8_t core_x[128 / 8];
    uint8_t core_y[128 / 8];
};
```

---
<style scoped>section { justify-content: start; } </style>

# /dev/mem

![bg right w:600](https://www.clear.rice.edu/comp321/html/laboratories/new-lab2/Image.png)

```C
int main(int argc, char **argv)
{

    uint8_t *bridge_map = NULL;

    int fd = 0;
    int result = 0;

    fd = open("/dev/mem", O_RDWR | O_SYNC);

    if (fd < 0)
    {
        perror("Couldn't open /dev/mem\n");
        return -2;
    }

    bridge_map = (uint8_t *)mmap(NULL, sizeof(struct mand_cluster), PROT_READ | PROT_WRITE,
                                 MAP_SHARED, fd, BRIDGE);

    if (bridge_map == MAP_FAILED)
    {
        perror("mmap failed.");
        close(fd);
        return -3;
    }

    struct mand_cluster *cluster = (struct mand_cluster *)(bridge_map + 0);

    result = munmap(bridge_map, BRIDGE_SPAN);

    if (result < 0)
    {
        perror("Couldnt unmap bridge.");
        close(fd);
        return -4;
    }

    close(fd);
    return 0;
}
```

--- 

<style scoped>section { justify-content: start; } </style>

# Rust HTTP Proxy

Simple Web Server
```rust
#[post("/calculate")]
async fn calculate(
    Json(request): Json<CalculateRequest>,
    cluster: Arc<ClusterScheduler>,
) -> impl IntoResponse {
    let result = cluster.run_callculation(x, y, max_itterations).await;

    match result {
        Ok(result) => (StatusCode::OK, Json(CalculateResponse {result}))
        Err(err) => (StatusCode::INTERNAL_SERVER_ERROR, err.to_string())
    }
}

```

![bg left vertical w:400](https://www.rust-lang.org/static/images/rust-logo-blk.svg)
![bg w:300](https://upload.wikimedia.org/wikipedia/commons/thumb/6/60/Tokio_logo.svg/640px-Tokio_logo.svg.png)

---
<style scoped>section { justify-content: start; } </style>

# Final Result

<br />

Python request

```python
resp = requests.post(
    "http://fpga:8000/calculate",
    json={
        "x": x_f,   # Hexadecimal
        "y": y_f,   # Hexadecimal
        "max_itterations": MAX_ITTERATIONS,
    },
)
```

![bg right w:740](../bench/fpga-test-result.png)

--- 
<style scoped>section { justify-content: start; } </style>

# Benchmark Setup (PC)

- AMD Ryzen 7 7700 8-Core Processor, 4.3 GHz
- 32GB DDR5

```rust
fn calculate_mandelbrot<T: Fixed>(x0: T, y0: T, max_itterations: u64) -> u64 {
    let mut x = T::from_num(0);
    let mut y = T::from_num(0);
    for itteration in 0..max_itterations {
        if x_s * x_s + y_s * y_s > bound_radius { return itteration; }
        let x_temp = x_s * x_s - y_s * y_s + x0;
        y = fixed_2 * x * y + y0;
        x = x_temp;
    }
    max_itterations
}
```

---
<style scoped>section { justify-content: start; } </style>

# Benchmark Results

<br />

- **FPGA** - **0.5** M ittr/s
- **PC** - **600** -> **120** M ittr/s

![bg left w:620](../bench/pc-vs-fpga-performance.png)

---
<style scoped>section { justify-content: start; } </style>

# Problems

<br />

1) Very limited FPGA resources
2) Free IP Cores
3) Lite version of Quartus:
    - Limited VHDL 2008 support
    - Extremely slow compilation
    - No advanced features
4) No enough time for optimization

---
<style scoped>section { justify-content: start; } </style>

# Design Problems

1) **Multiply Block**: 
    - Rounding logic
    - Time optimization
2) **Cluster**: 
    - Avalon-MM bus
    - Cores synchronization
3) **HPS**:
    - FPGA communication lacks synchronization

---

# Thank you for your attention!

<br />

Useful Links:
- [Absolute beginner's guide](https://github.com/zangman/de10-nano)
- [Mandelbrot Set](https://en.wikipedia.org/wiki/Mandelbrot_set)
- [Project REPO](https://github.com/dk731/fpga-mandelbrot-accelerator)