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
    output logic ws2812
);
    logic rst_reg;
    logic [7:0] counter = 0;

    always_ff @(posedge clk) begin
        if (counter < 8'hFF) begin
            counter <= counter + 8'd1;
            rst_reg <= 1'b1;
        end else begin
            rst_reg <= rst;
        end
    end

    cpu #(
        .SIMULATION(1'b0),
        .CLK_FREQ(27000000)
    ) cpu0 (
        .clk(clk),
        .rst(rst_reg),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .button(button),
        .leds(leds),
        .ws2812(ws2812)
    );
endmodule
