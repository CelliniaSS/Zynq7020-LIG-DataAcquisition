// top.v
module top (
    input  wire clk,      // 连接到板上的全局时钟引脚
    input  wire rst_n,    // 连接到板上的按键/复位引脚（低有效）
    output wire led       // 连接到板上的某个 LED 引脚
);

    // 当前点灯 demo：先默认永远使能；后续用 AXI GPIO 接入 PS->PL 的 blink_enable
    wire [31:0] status_cnt;

    led_blink u_led_blink (
        .clk   (clk),
        .rst_n (rst_n),
        .blink_enable (1'b1),
        .led          (led),
        .status_cnt   (status_cnt)
    );

endmodule