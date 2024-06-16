---
marp: true
theme: uncover
class: invert
---

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

Float Size: **640** Bytes!!!

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

![bg right w:600](project-structure.png)
