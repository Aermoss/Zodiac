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

module sdram #(
    parameter int CLK_FREQ = 54000000
) (
    input logic clk,
    input logic rst,

    input logic start,
    input logic write,
    input logic [20:0] address,
    input logic [31:0] data,
    input logic [3:0] dqm,
    output logic ready,
    output logic read_valid,
    output logic [31:0] read_data,
    output logic write_done,
    output logic [20:0] active_address,
    output logic [31:0] active_data,
    output logic [3:0] active_dqm,

    output logic sdrc_cmd_en,
    output logic [2:0] sdrc_cmd,
    output logic [20:0] sdrc_addr,
    output logic [31:0] sdrc_data_w,
    output logic [3:0] sdrc_dqm,
    input logic [31:0] sdrc_data_r,
    input logic sdrc_init_done,
    input logic sdrc_cmd_ack
);
    localparam int REFRESH_CYCLES = CLK_FREQ / 1000000 * 15;

    typedef enum logic [2:0] {
        S_IDLE,
        S_REFRESH,
        S_ACTIVATE_WAIT,
        S_COMMAND_WAIT,
        S_READ_DELAY,
        S_WRITE_DELAY,
        S_WRITE_DONE
    } state_t;

    state_t state;
    logic reading;
    logic [2:0] delay;
    logic [$clog2(REFRESH_CYCLES) - 1:0] refresh_counter;
    logic refresh_pending;

    assign ready = state == S_IDLE && !refresh_pending && sdrc_init_done;
    assign read_valid = state == S_READ_DELAY && delay <= 3'd1;
    assign read_data = sdrc_data_r;
    assign write_done = state == S_WRITE_DONE;

    assign sdrc_addr = active_address;
    assign sdrc_data_w = active_data;
    assign sdrc_dqm = active_dqm;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            reading <= 1'b0;
            delay <= 3'b0;
            refresh_counter <= '0;
            refresh_pending <= 1'b0;
            sdrc_cmd_en <= 1'b0;
            sdrc_cmd <= 3'b000;
            active_address <= 21'b0;
            active_data <= 32'b0;
            active_dqm <= 4'b0000;
        end else begin
            if (sdrc_init_done) begin
                if (refresh_counter == REFRESH_CYCLES - 1) begin
                    refresh_counter <= '0;
                    refresh_pending <= 1'b1;
                end else begin
                    refresh_counter <= refresh_counter + 1'b1;
                end
            end

            case (state)
                S_IDLE: begin
                    if (refresh_pending) begin
                        refresh_pending <= 1'b0;
                        sdrc_cmd_en <= 1'b1;
                        sdrc_cmd <= 3'b001;
                        state <= S_REFRESH;
                    end else if (start) begin
                        sdrc_cmd_en <= 1'b1;
                        sdrc_cmd <= 3'b011;
                        active_address <= address;
                        active_data <= data;
                        active_dqm <= dqm;
                        reading <= !write;
                        state <= S_ACTIVATE_WAIT;
                    end
                end

                S_REFRESH: begin
                    sdrc_cmd_en <= 1'b0;

                    if (sdrc_cmd_ack)
                        state <= S_IDLE;
                end

                S_ACTIVATE_WAIT: begin
                    sdrc_cmd_en <= 1'b0;

                    if (sdrc_cmd_ack) begin
                        sdrc_cmd_en <= 1'b1;
                        sdrc_cmd <= reading ? 3'b101 : 3'b100;
                        state <= S_COMMAND_WAIT;
                    end
                end

                S_COMMAND_WAIT: begin
                    sdrc_cmd_en <= 1'b0;

                    if (sdrc_cmd_ack) begin
                        delay <= 3'd5;

                        if (reading)
                            state <= S_READ_DELAY;
                        else
                            state <= S_WRITE_DELAY;
                    end
                end

                S_READ_DELAY: begin
                    if (delay > 3'd1)
                        delay <= delay - 3'd1;
                    else
                        state <= S_IDLE;
                end

                S_WRITE_DELAY: begin
                    if (delay > 3'd1)
                        delay <= delay - 3'd1;
                    else
                        state <= S_WRITE_DONE;
                end

                S_WRITE_DONE: state <= S_IDLE;
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
