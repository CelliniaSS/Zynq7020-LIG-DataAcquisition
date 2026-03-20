# 定义时钟：名字叫 clk，周期是 20.0ns (对应 50MHz)，对应端口是 clk
create_clock -period 20.000 -name clk -waveform {0.000 10.000} [get_ports clk]

set_property PACKAGE_PIN U18 [get_ports clk]
set_property PACKAGE_PIN H15 [get_ports led]
set_property PACKAGE_PIN N16 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
