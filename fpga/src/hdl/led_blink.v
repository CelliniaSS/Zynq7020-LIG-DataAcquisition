// led_blink.v
module led_blink (
    input  wire clk,      // 板载时钟输入，比如 50MHz/100MHz
    input  wire rst_n,    // 低电平复位
    input  wire blink_enable, // 由 PS 控制：1=允许闪烁，0=关闭并熄灭
    output reg  led,      // LED 输出
    output reg [31:0] status_cnt // 由 PL 回读给 PS：每次 LED 翻转计数 +1
);
    // 50MHz 时钟下，让 LED 每 0.5s 翻转一次（即 1s 完整亮灭周期）
    // half_period_cycles = 50_000_000 * 0.5 = 25_000_000
    localparam integer HALF_PERIOD_CYCLES = 25_000_000;

    // HALF_PERIOD_CYCLES = 25_000_000 < 2^25，所以计数器用 25bit 即可
    reg [24:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 25'd0;
            led <= 1'b0;
            status_cnt <= 32'd0;
        end else if (!blink_enable) begin
            // 关闭时：熄灭 LED，并清零计数（便于 PS 读取“当前会话计数”）
            cnt <= 25'd0;
            led <= 1'b0;
            status_cnt <= 32'd0;
        end else begin
            if (cnt == HALF_PERIOD_CYCLES - 1) begin
                cnt <= 25'd0;
                led <= ~led;
                status_cnt <= status_cnt + 32'd1;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end
    end

endmodule