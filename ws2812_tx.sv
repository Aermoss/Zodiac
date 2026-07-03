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

module ws2812_tx #(
    parameter int CLK_FREQ = 33000000
) (
    input logic clk,
    input logic rst,
    input logic strobe,
    input logic [23:0] write,
    output logic busy,
    output logic out
);
    typedef enum logic [1:0] {
        S_IDLE,
        S_SEND,
        S_RESET
    } state_t;

    state_t state;
    logic [4:0] bit_counter;
    logic [15:0] cycle_counter;
    logic [23:0] shift_reg;

    localparam int CYCLES_TOTAL = int'(1250.0 * CLK_FREQ / 1000000000.0);
    localparam int CYCLES_T1H = int'(800.0 * CLK_FREQ / 1000000000.0);
    localparam int CYCLES_T0H = int'(400.0 * CLK_FREQ / 1000000000.0);
    localparam int CYCLES_RESET = int'(250000.0 * CLK_FREQ / 1000000000.0);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            bit_counter <= 5'b0;
            cycle_counter <= 16'b0;
            shift_reg <= 24'b0;
            out <= 1'b0;
            busy <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    out <= 1'b0;
                    cycle_counter <= 16'b0;

                    if (strobe) begin
                        state <= S_SEND;
                        bit_counter <= 5'd24;
                        shift_reg <= write;
                        busy <= 1'b1;
                    end else begin
                        busy <= 1'b0;
                    end
                end

                S_SEND: begin
                    if (shift_reg[23]) begin
                        out <= (cycle_counter < CYCLES_T1H);
                    end else begin
                        out <= (cycle_counter < CYCLES_T0H);
                    end

                    if (cycle_counter < CYCLES_TOTAL) begin
                        cycle_counter <= cycle_counter + 16'd1;
                    end else begin
                        cycle_counter <= 16'b0;
                        shift_reg <= shift_reg << 1;

                        if (bit_counter > 5'd1) begin
                            bit_counter <= bit_counter - 5'd1;
                        end else begin
                            bit_counter <= 5'b0;
                            state <= S_RESET;
                        end
                    end
                end

                S_RESET: begin
                    out <= 1'b0;

                    if (cycle_counter < CYCLES_RESET) begin
                        cycle_counter <= cycle_counter + 16'd1;
                    end else begin
                        cycle_counter <= 16'b0;
                        busy <= 1'b0;
                        state <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
