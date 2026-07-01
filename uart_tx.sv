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

module uart_tx(
    input logic clk,
    input logic rst,
    input logic [15:0] clks_per_bit,
    input logic [7:0] tx_data,
    input logic tx_write,
    output logic tx_busy,
    output logic tx_pin
);
    typedef enum logic [1:0] {
        STATE_IDLE,
        STATE_START,
        STATE_DATA,
        STATE_STOP
    } state_t;

    state_t state;
    logic [15:0] clk_count;
    logic [2:0] bit_index;
    logic [7:0] tx_data_reg;

    assign tx_busy = (state != STATE_IDLE);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            clk_count <= 0;
            bit_index <= 0;
            tx_data_reg <= 0;
            tx_pin <= 1'b1;
        end else begin
            case (state)
                STATE_IDLE: begin
                    tx_pin  <= 1'b1;
                    clk_count <= 0;
                    bit_index <= 0;

                    if (tx_write) begin
                        tx_data_reg <= tx_data;
                        state <= STATE_START;
                    end
                end

                STATE_START: begin
                    tx_pin <= 1'b0;

                    if (clk_count < clks_per_bit - 1) begin
                        clk_count <= clk_count + 16'd1;
                    end else begin
                        clk_count <= 0;
                        state <= STATE_DATA;
                    end
                end

                STATE_DATA: begin
                    tx_pin <= tx_data_reg[bit_index];

                    if (clk_count < clks_per_bit - 1) begin
                        clk_count <= clk_count + 16'd1;
                    end else begin
                        clk_count <= 0;

                        if (bit_index < 7) begin
                            bit_index <= bit_index + 3'd1;
                        end else begin
                            bit_index <= 0;
                            state <= STATE_STOP;
                        end
                    end
                end

                STATE_STOP: begin
                    tx_pin <= 1'b1;

                    if (clk_count < clks_per_bit - 1) begin
                        clk_count <= clk_count + 16'd1;
                    end else begin
                        clk_count <= 0;
                        state <= STATE_IDLE;
                    end
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end
endmodule
