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

`timescale 1ns / 1ps

module tb;
    logic rst;
    logic clk = 0;
    integer i;

    logic [3:0] mem_we;
    logic [31:0] mem_addr;
    logic [31:0] mem_write;
    logic [31:0] mem_read;

    cpu #(
        .SIMULATION(1'b1),
        .CLK_FREQ(33000000)
    ) cpu0 (
        .clk(clk),
        .rst(rst),

        .uart_rx(),
        .uart_tx(),

        .button(),
        .leds(),
        .ws2812(),

        .mem_access(),
        .actual_mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .bus_stall(1'b0)
    );

    bram bram0 (
        .clk(clk),
        .we(mem_we),
        .addr(mem_addr),
        .write(mem_write),
        .read(mem_read)
    );

    always #3 clk = ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb);

        for (i = 0; i < 32; i++)
            $dumpvars(0, cpu0.regs[i]);

        rst = 1;
        @(negedge clk);
        rst = 0;

        #100000;
        $finish;
    end
endmodule
