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

module flash (
    input logic clk,
    input logic rst,

    input logic flash_req,
    input logic [23:0] flash_addr,
    output logic [31:0] flash_rdata,
    output logic flash_ready,

    output logic flash_cs,
    output logic flash_sck,
    output logic flash_mosi,
    input logic flash_miso
);
    localparam logic [7:0] READ_CMD = 8'h03;

    typedef enum logic [1:0] {
        S_IDLE,
        S_XFER,
        S_DONE
    } state_t;

    state_t state;

    logic [5:0] bit_cnt;
    logic phase, stage;
    logic [31:0] tx_shift;
    logic [31:0] rx_shift;

    assign flash_sck = flash_cs ? 1'b0 : phase;
    assign flash_mosi = tx_shift[31];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            flash_cs <= 1'b1;
            flash_ready <= 1'b0;
            flash_rdata <= 32'h0;
            phase <= 1'b0;
            bit_cnt <= 6'd0;
            tx_shift <= 32'h0;
            rx_shift <= 32'h0;
            stage <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    flash_ready <= 1'b0;
                    if (flash_req) begin
                        flash_cs <= 1'b0;
                        tx_shift <= {READ_CMD, flash_addr};
                        bit_cnt <= 6'd32;
                        phase <= 1'b0;
                        stage <= 1'b0;
                        state <= S_XFER;
                    end else begin
                        flash_cs <= 1'b1;
                    end
                end

                S_XFER: begin
                    if (!phase) begin
                        phase <= 1'b1;
                    end else begin
                        rx_shift <= {rx_shift[30:0], flash_miso};
                        tx_shift <= {tx_shift[30:0], 1'b0};
                        phase <= 1'b0;

                        if (bit_cnt == 6'd1) begin
                            if (!stage) begin
                                tx_shift <= 32'h0;
                                bit_cnt <= 6'd32;
                                stage <= 1'b1;
                            end else begin
                                state <= S_DONE;
                            end
                        end else begin
                            bit_cnt <= bit_cnt - 6'd1;
                        end
                    end
                end

                S_DONE: begin
                    flash_cs <= 1'b1;
                    flash_rdata <= rx_shift;
                    flash_ready <= 1'b1;
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
