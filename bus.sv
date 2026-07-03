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

module bus (
    input logic clk,
    input logic rst,

    input logic cpu_mem_access,
    input logic [3:0] cpu_mem_we,
    input logic [31:0] cpu_mem_addr,
    input logic [31:0] cpu_mem_write,
    output logic [31:0] cpu_mem_read,
    output logic cpu_stall,

    output logic [3:0] bram_we,
    output logic [31:0] bram_addr,
    output logic [31:0] bram_write,
    input logic [31:0] bram_read,

    output logic sdrc_cmd_en,
    output logic [2:0] sdrc_cmd,
    output logic [20:0] sdrc_addr,
    output logic [31:0] sdrc_data_w,
    output logic [3:0] sdrc_dqm,
    input logic [31:0] sdrc_data_r,
    input logic sdrc_init_done,
    input logic sdrc_cmd_ack
);
    wire is_sdram_addr = (cpu_mem_addr[31:30] == 2'b01) && cpu_mem_access;
    wire [20:0] sdram_word_addr = cpu_mem_addr[22:2];

    typedef enum logic [1:0] {
        S_IDLE,
        S_SDRAM_WAIT,
        S_DONE
    } state_t;

    state_t state;
    logic [31:0] sdram_read_reg;

    logic r_hold_sdram_data; 

    logic [20:0] r_sdrc_addr;
    logic [31:0] r_sdrc_data_w;
    logic [2:0] r_sdrc_cmd;
    logic [3:0] r_sdrc_dqm;

    assign sdrc_addr = r_sdrc_addr;
    assign sdrc_data_w = r_sdrc_data_w;
    assign sdrc_cmd = r_sdrc_cmd;
    assign sdrc_dqm = r_sdrc_dqm;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            sdrc_cmd_en <= 1'b0;
            r_sdrc_cmd <= 3'b000;
            r_sdrc_addr <= 21'b0;
            r_sdrc_data_w <= 32'b0;
            r_sdrc_dqm <= 4'b0000;
            sdram_read_reg <= 32'b0;
            r_hold_sdram_data <= 1'b0;
        end else begin
            r_hold_sdram_data <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (is_sdram_addr && sdrc_init_done) begin
                        sdrc_cmd_en <= 1'b1;
                        r_sdrc_addr <= sdram_word_addr;
                        r_sdrc_data_w <= cpu_mem_write;
                        r_sdrc_dqm <= (cpu_mem_we != 4'b0000) ? ~cpu_mem_we : 4'b0000; 
                        
                        if (cpu_mem_we != 4'b0000) begin
                            r_sdrc_cmd <= 3'b100;
                        end else begin
                            r_sdrc_cmd <= 3'b101;
                        end
                        
                        state <= S_SDRAM_WAIT;
                    end
                end

                S_SDRAM_WAIT: begin
                    if (sdrc_cmd_ack) begin
                        sdrc_cmd_en <= 1'b0;

                        if (r_sdrc_cmd == 3'b101)
                            sdram_read_reg <= sdrc_data_r;

                        state <= S_DONE;
                    end
                end

                S_DONE: begin
                    if (r_sdrc_cmd == 3'b101)
                        r_hold_sdram_data <= 1'b1;

                    state <= S_IDLE;
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end

    always_comb begin
        bram_addr = cpu_mem_addr;
        bram_write = cpu_mem_write;
        bram_we = 4'b0000;
        
        if (cpu_mem_access && !is_sdram_addr && state == S_IDLE) begin
            bram_we = cpu_mem_we;
        end

        if (r_hold_sdram_data) begin
            cpu_mem_read = sdram_read_reg;
        end else begin
            cpu_mem_read = bram_read;
        end

        if (state == S_IDLE) begin
            cpu_stall = (cpu_mem_access && is_sdram_addr);
        end else if (state == S_DONE) begin
            cpu_stall = 1'b0;
        end else begin
            cpu_stall = 1'b1;
        end
    end
endmodule
