日期： 2026-03-19
项目阶段： 基础架构搭建与“Hello World”逻辑实现
硬件平台： Zynq-7020 (xc7z020clg400-1)
开发工具： Cursor (AI Code Editor) + Vivado 2024.2

一、 核心成就（里程碑）
标准化工程架构搭建：建立了 fpga/、ps/、docs/、scripts/ 的多级目录。实现了“源码”与“编译工程”的物理隔离，为后续 Git 版本管理打下了专业基础。
跨工具集成流打通：实现了 Cursor 写码 <-> Vivado 编译 的双向联动。通过“引用（Reference）”而非“复制（Copy）”的方式管理源文件，确保了代码的唯一性。
全流程闭环验证：经历了 RTL 编写 -> 逻辑综合 -> 布局布线 -> 引脚约束 -> 比特流生成 -> JTAG 下载 的完整 FPGA 开发链条，并在硬件上成功观察到预期现象。

二、 重要知识点总结（技术沉淀）
1. 工程管理逻辑Git 策略：学会了配置专业的 .gitignore 规则，过滤 Vivado 产生的海量临时文件（如 .runs, .log, .jou），只保留核心的 .v 和 .xdc。模块命名：掌握了 “模块名 = 文件名” 的行业铁律，以及 snake_case（小写字母+下划线）的命名规范。
2. FPGA 核心概念HDL 与 RTL：理解了 Verilog 并不是软件指令，而是“硬件描述语言”，通过描述寄存器传输级（RTL）逻辑来“构建”电路。层级架构：理解了 top.v 类似主控室（例化/接线），子模块（如 led_blink.v）类似功能插件的“搭积木”逻辑。挥发性：明确了 FPGA 基于 SRAM 存储，具有断电即失的特性，后续需要通过 SD 卡或 Flash 进行固化。
3. 约束与时序（Constraints）引脚电平标准：认识到 IOSTANDARD 的重要性。对于 7020 常用 IO，必须手动设置为 LVCMOS33（3.3V）以匹配硬件电路。时序约束：理解了时钟不仅是引脚物理连接（U18），还需要在 .xdc 中使用 create_clock 显式定义频率（50MHz 对应 20ns 周期）。

三、 避坑经验谈蓝色问号：
看到问号不要慌，通常是模块名对不上或文件没加进 Sources。
1.8V 陷阱：软件默认电平往往与硬件不符，烧录前必须核对原理图电平。

根据原理图找对应引脚的电源电压!!!!!!!!!

网表与网口：Synthesis 产生的是电路网表（Netlist），不是网线的网口。

Cursor:
搭好了工程目录结构

在项目根目录下规划并创建了 fpga/、ps/、docs/、scripts/ 等子目录。
在 fpga 下细分了 src/hdl（RTL 源码）、src/constraints（XDC 约束）、sim、bitstream 等，为后续 Vivado/PS 开发打好基础。
完成了第一个工程化的点灯 RTL 结构

在 hdl 中实现了功能模块 led_blink（计数分频+LED 闪烁），和顶层模块 top（只做端口收口+例化）：
top 端口：clk、rst_n、led，内部例化 led_blink。
led_blink 基于 50MHz 时钟，用计数器实现 每 0.5 秒翻转一次 LED（1Hz 闪烁） 的逻辑。
完成基本的板级约束（XDC）并检查正确性

在 constraints 里写了 led_blank.xdc，对 clk、led、rst_n 做了：
时钟约束：create_clock -period 20ns 对应 50MHz。
管脚/电平约束：为三者配置了 PACKAGE_PIN 和 IOSTANDARD LVCMOS33。
确认了 XDC 写法、接口命名和顶层端口是一致的。





日期：2026-03-20
工程师：XZ
项目：LIG 柔性传感器多通道数据采集系统（PL 侧验证与总线对接）

🛠️ 1. 环境治理与规范化
Git 仓库深度清理：通过配置“暴力版”.gitignore，排除了 Vivado 产生的 60+ 个工程过程文件（.runs, .dcp, .vds 等），使仓库体积从百 MB 级降至 KB 级。

网络与权限调通：解决了 GitHub 推送时的代理冲突与凭据管理问题，确立了 git push 秒传的稳定流。

文档同步：确立了以 docs/dev_log.md 为核心的开发记录习惯。

🏗️ 2. 硬件架构设计（Vivado Block Design）
完成了从 纯 Verilog 逻辑 到 PS-PL 协同系统 的跨越。

A. 逻辑模块升级
模块名：led_blink

新增特性：

控制接口：blink_enable (由 ARM 决定何时开启/关闭闪烁)。

状态反馈：status_cnt (由 FPGA 实时统计翻转次数，供 ARM 回读)。

时钟方案：抛弃外部晶振，完全同步至 PS 侧的 FCLK_CLK0 (50MHz)。

B. Block Design (BD) 集成
在画布上成功完成了“乐高式”组装：

ZYNQ7 PS：配置了 DDR3 内存与固定 I/O。

AXI GPIO (Dual Channel)：

通道 1 (Output)：映射至 blink_enable。

通道 2 (Input)：映射至 status_cnt。

关键修正：解决了 Reset Polarity (复位极性) 不匹配问题，将 rst_n 重新连接至低电平有效的 peripheral_aresetn。

📊 3. 核心接口映射表 (Memory Map)

物理对象          信号方向                     AXI 端口         逻辑功能
Blink Enable      PS -> PL,gpio_io_o (CH1)    ARM             下达运行/停止指令
Status Counter    PL -> PS,gpio2_io_i (CH2)   ARM             读取 PL 内部计数器状态
LED Port          PL -> Pad                   led (External)  外部物理引脚观察

🚀 4. 今日产出交付
Bitstream：已生成，证明硬件逻辑与布局布线无误。

Hardware Platform：导出了包含比特流的 top.xsa 文件。

里程碑：硬件“大坝”已筑起，ARM 与 FPGA 之间的“物流通路”已从物理层面打通。


📅 下一步计划 (Next Step)
1.Vitis 环境初始化：导入 top.xsa，建立 Platform 和 Application 工程。

2.C 语言驱动编写：

调用 XGpio_Initialize 握手“翻译官”。

实现逻辑：每隔 10 秒切换一次 blink_enable。

实时回读 status_cnt 并通过串口（UART）打印，验证数据采集回传的准确性。

3.LIG 传感器逻辑预研：开始考虑如何将 AXI 接口扩展到多通道 ADC 的控制上。