/*
 * Copyright 2026 Yusuf Rençber
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module top (
    input logic clk,
    input logic rst,

    input logic uart_rx,
    output logic uart_tx,

    input logic button,
    output logic [5:0] leds,
    output logic ws2812,

    output logic O_sdram_clk,
    output logic O_sdram_cke,
    output logic O_sdram_cs_n,
    output logic O_sdram_cas_n,
    output logic O_sdram_ras_n,
    output logic O_sdram_wen_n,
    output logic [3:0] O_sdram_dqm,
    output logic [10:0] O_sdram_addr,
    output logic [1:0] O_sdram_ba,
    inout wire [31:0] IO_sdram_dq
);
    logic sys_clk;
    logic sdram_clk;
    logic pll_lock;

    Gowin_rPLL pll0 (
        .clkin(clk),
        .reset(rst),
        .clkout(sys_clk),
        .clkoutp(sdram_clk),
        .lock(pll_lock)
    );

    logic rst_reg;
    logic [7:0] counter = 8'd0;

    always_ff @(posedge sys_clk) begin
        if (!pll_lock) begin
            counter <= 8'd0;
            rst_reg <= 1'b1;
        end else if (counter < 8'hFF) begin
            counter <= counter + 8'd1;
            rst_reg <= 1'b1;
        end else begin
            rst_reg <= rst;
        end
    end

    logic cpu_mem_access;
    logic [3:0] cpu_mem_we;
    logic [31:0] cpu_mem_addr;
    logic [31:0] cpu_mem_write;
    logic [31:0] cpu_mem_read;
    logic cpu_stall;

    cpu #(
        .SIMULATION(1'b0),
        .CLK_FREQ(33000000)
    ) cpu0 (
        .clk(sys_clk),
        .rst(rst_reg),

        .uart_rx(uart_rx),
        .uart_tx(uart_tx),

        .button(button),
        .leds(leds),
        .ws2812(ws2812),

        .mem_access(cpu_mem_access),
        .actual_mem_we(cpu_mem_we),
        .mem_addr(cpu_mem_addr),
        .mem_write(cpu_mem_write),
        .mem_read(cpu_mem_read),
        .bus_stall(cpu_stall)
    );

    logic [3:0] bram_we;
    logic [31:0] bram_addr;
    logic [31:0] bram_write;
    logic [31:0] bram_read;

    bram bram0 (
        .clk(sys_clk),
        .we(bram_we),
        .addr(bram_addr),
        .write(bram_write),
        .read(bram_read)
    );

    logic sdrc_cmd_en;
    logic [2:0] sdrc_cmd;
    logic [20:0] sdrc_addr;
    logic [3:0] sdrc_dqm;
    logic [31:0] sdrc_data_w;
    logic [31:0] sdrc_data_r;
    logic sdrc_init_done;
    logic sdrc_cmd_ack;

    SDRAM_Controller_HS_Top sdrc0 (
        .O_sdram_clk(O_sdram_clk),
        .O_sdram_cke(O_sdram_cke),
        .O_sdram_cs_n(O_sdram_cs_n),
        .O_sdram_cas_n(O_sdram_cas_n),
        .O_sdram_ras_n(O_sdram_ras_n),
        .O_sdram_wen_n(O_sdram_wen_n),
        .O_sdram_dqm(O_sdram_dqm),
        .O_sdram_addr(O_sdram_addr),
        .O_sdram_ba(O_sdram_ba),
        .IO_sdram_dq(IO_sdram_dq),

        .I_sdrc_rst_n(~rst_reg),
        .I_sdrc_clk(sys_clk),
        .I_sdram_clk(sdram_clk),
        .I_sdrc_cmd_en(sdrc_cmd_en),
        .I_sdrc_cmd(sdrc_cmd),
        .I_sdrc_precharge_ctrl(1'b0),
        .I_sdram_power_down(1'b0),
        .I_sdram_selfrefresh(1'b0),
        .I_sdrc_addr(sdrc_addr),
        .I_sdrc_dqm(sdrc_dqm),
        .I_sdrc_data(sdrc_data_w),
        .I_sdrc_data_len(8'd0),
        .O_sdrc_data(sdrc_data_r), 
        .O_sdrc_init_done(sdrc_init_done),
        .O_sdrc_cmd_ack(sdrc_cmd_ack)
    );

    bus bus0 (
        .clk(sys_clk),
        .rst(rst_reg),

        .cpu_mem_access(cpu_mem_access),
        .cpu_mem_we(cpu_mem_we),
        .cpu_mem_addr(cpu_mem_addr),
        .cpu_mem_write(cpu_mem_write),
        .cpu_mem_read(cpu_mem_read),
        .cpu_stall(cpu_stall),

        .bram_we(bram_we),
        .bram_addr(bram_addr),
        .bram_write(bram_write),
        .bram_read(bram_read),

        .sdrc_cmd_en(sdrc_cmd_en),
        .sdrc_cmd(sdrc_cmd),
        .sdrc_addr(sdrc_addr),
        .sdrc_dqm(sdrc_dqm),
        .sdrc_data_w(sdrc_data_w),
        .sdrc_data_r(sdrc_data_r),
        .sdrc_init_done(sdrc_init_done),
        .sdrc_cmd_ack(sdrc_cmd_ack)
    );
endmodule
