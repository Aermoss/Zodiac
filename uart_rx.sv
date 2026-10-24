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

module uart_rx #(
    parameter int FIFO_DEPTH = 16
) (
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

    localparam int POINTER_BITS = $clog2(FIFO_DEPTH);

    state_t state;
    logic [15:0] clk_count;
    logic [2:0] bit_index;
    logic [7:0] rx_data_reg;
    logic rx_sync0, rx_sync1;
    logic byte_received;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_sync0 <= 1'b1;
            rx_sync1 <= 1'b1;
        end else begin
            rx_sync0 <= rx_pin;
            rx_sync1 <= rx_sync0;
        end
    end

    assign byte_received = state == S_STOP && !(clk_count < clks_per_bit - 1);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            clk_count <= 0;
            bit_index <= 0;
            rx_data_reg <= 0;
        end else begin
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
                        state <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    logic [7:0] fifo [0:FIFO_DEPTH - 1];
    logic [POINTER_BITS - 1:0] fifo_head;
    logic [POINTER_BITS - 1:0] fifo_tail;
    logic [POINTER_BITS:0] fifo_count;
    logic fifo_push;
    logic fifo_pop;

    assign fifo_pop = read_ack && fifo_count != 0;
    assign fifo_push = byte_received && (fifo_count != FIFO_DEPTH || fifo_pop);
    assign rx_byte = fifo[fifo_head];
    assign rx_ready = fifo_count != 0;

    always_ff @(posedge clk) begin
        if (fifo_push)
            fifo[fifo_tail] <= rx_data_reg;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            fifo_head <= 0;
            fifo_tail <= 0;
            fifo_count <= 0;
        end else begin
            if (fifo_push)
                fifo_tail <= fifo_tail + 1'b1;

            if (fifo_pop)
                fifo_head <= fifo_head + 1'b1;

            case ({fifo_push, fifo_pop})
                2'b10: fifo_count <= fifo_count + 1'b1;
                2'b01: fifo_count <= fifo_count - 1'b1;
            endcase
        end
    end
endmodule
