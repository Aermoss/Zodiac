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

module uart_rx(
    input logic clk,
    input logic rst,
    input logic [15:0] clks_per_bit,
    input logic rx_pin,
    input logic read_ack,
    output logic [7:0] rx_byte,
    output logic rx_ready
);
    typedef enum logic [1:0] {
        S_IDLE,
        S_START,
        S_DATA,
        S_STOP
    } state_t;

    state_t state;
    logic [15:0] clk_count;
    logic [2:0] bit_index;
    logic [7:0] rx_data_reg;
    logic rx_sync0, rx_sync1;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_sync0 <= 1'b1;
            rx_sync1 <= 1'b1;
        end else begin
            rx_sync0 <= rx_pin;
            rx_sync1 <= rx_sync0;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            clk_count <= 0;
            bit_index <= 0;
            rx_data_reg <= 0;
            rx_byte <= 0;
            rx_ready <= 1'b0;
        end else begin
            if (read_ack) begin
                rx_ready <= 1'b0;
            end

            case (state)
                S_IDLE: begin
                    clk_count <= 0;
                    bit_index <= 0;

                    if (rx_sync1 == 1'b0) begin
                        state <= S_START;
                    end
                end

                S_START: begin
                    if (clk_count < (clks_per_bit >> 1) - 1) begin
                        clk_count <= clk_count + 16'd1;
                    end else begin
                        clk_count <= 0;

                        if (rx_sync1 == 1'b0) begin
                            state <= S_DATA;
                        end else begin
                            state <= S_IDLE;
                        end
                    end
                end

                S_DATA: begin
                    if (clk_count < clks_per_bit - 1) begin
                        clk_count <= clk_count + 16'd1;
                    end else begin
                        clk_count <= 0;
                        rx_data_reg[bit_index] <= rx_sync1;

                        if (bit_index < 7) begin
                            bit_index <= bit_index + 3'd1;
                        end else begin
                            bit_index <= 0;
                            state <= S_STOP;
                        end
                    end
                end

                S_STOP: begin
                    if (clk_count < clks_per_bit - 1) begin
                        clk_count <= clk_count + 16'd1;
                    end else begin
                        clk_count <= 0;
                        rx_byte <= rx_data_reg;
                        rx_ready <= 1'b1;
                        state <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
