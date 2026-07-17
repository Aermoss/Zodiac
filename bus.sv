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
    input logic sdrc_cmd_ack,

    output logic flash_req,
    output logic [23:0] flash_addr,
    input logic [31:0] flash_rdata,
    input logic flash_ready
);
    wire is_sdram_addr = (cpu_mem_addr[31:30] == 2'b01);
    wire is_flash_addr = (cpu_mem_addr[31:30] == 2'b10);

    wire [20:0] sdram_word_addr = {cpu_mem_addr[22:21], cpu_mem_addr[20:10], cpu_mem_addr[9:2]};
    wire [23:0] flash_byte_addr = cpu_mem_addr[23:0];

    typedef enum logic [2:0] {
        S_IDLE,
        S_ACTIVATE_WAIT,
        S_SDRAM_WAIT,
        S_READ_DELAY,
        S_WRITE_DELAY,
        S_SDRAM_DONE,
        S_FLASH_WAIT,
        S_FLASH_DONE
    } state_t;

    state_t state;
    logic [2:0] read_delay_counter;
    logic [2:0] write_delay_counter;
    logic [31:0] sdram_read_reg;
    logic sdram_read_active;
    
    logic [31:0] flash_read_reg;
    logic flash_read_active;

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
            sdram_read_active <= 1'b0;
            read_delay_counter <= 3'b0;
            write_delay_counter <= 3'b0;
            flash_req <= 1'b0;
            flash_addr <= 24'b0;
            flash_read_reg <= 32'b0;
            flash_read_active <= 1'b0;
        end else begin
            sdram_read_active <= 1'b0;
            flash_read_active <= 1'b0;
            flash_req <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (is_sdram_addr && sdrc_init_done) begin
                        sdrc_cmd_en <= 1'b1;
                        r_sdrc_addr <= sdram_word_addr;
                        r_sdrc_data_w <= cpu_mem_write;
                        r_sdrc_dqm <= (cpu_mem_we != 4'b0000) ? ~cpu_mem_we : 4'b0000; 
                        r_sdrc_cmd <= 3'b011;
                        state <= S_ACTIVATE_WAIT;
                    end else if (is_flash_addr && cpu_mem_access && (cpu_mem_we == 4'b0000)) begin
                        flash_req <= 1'b1;
                        flash_addr <= flash_byte_addr;
                        state <= S_FLASH_WAIT;
                    end
                end

                S_ACTIVATE_WAIT: begin
                    sdrc_cmd_en <= 1'b0;

                    if (sdrc_cmd_ack) begin
                        sdrc_cmd_en <= 1'b1;

                        if (cpu_mem_we != 4'b0000)
                            r_sdrc_cmd <= 3'b100;
                        else
                            r_sdrc_cmd <= 3'b101;

                        state <= S_SDRAM_WAIT;
                    end
                end

                S_SDRAM_WAIT: begin
                    sdrc_cmd_en <= 1'b0;

                    if (sdrc_cmd_ack) begin
                        if (r_sdrc_cmd == 3'b101) begin
                            read_delay_counter <= 3'd5;
                            state <= S_READ_DELAY;
                        end else begin
                            write_delay_counter <= 3'd5;
                            state <= S_WRITE_DELAY;
                        end
                    end
                end

                S_READ_DELAY: begin
                    if (read_delay_counter > 3'd1) begin
                        read_delay_counter <= read_delay_counter - 3'd1;
                    end else begin
                        sdram_read_reg <= sdrc_data_r;
                        state <= S_SDRAM_DONE;
                    end
                end

                S_WRITE_DELAY: begin
                    if (write_delay_counter > 3'd1)
                        write_delay_counter <= write_delay_counter - 3'd1;
                    else
                        state <= S_SDRAM_DONE;
                end

                S_SDRAM_DONE: begin
                    if (r_sdrc_cmd == 3'b101)
                        sdram_read_active <= 1'b1;

                    state <= S_IDLE;
                end

                S_FLASH_WAIT: begin
                    if (flash_ready) begin
                        flash_read_reg <= flash_rdata;
                        state <= S_FLASH_DONE;
                    end
                end

                S_FLASH_DONE: begin
                    flash_read_active <= 1'b1;
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

        if (cpu_mem_access && !is_sdram_addr && !is_flash_addr && state == S_IDLE)
            bram_we = cpu_mem_we;

        if (state == S_SDRAM_DONE || sdram_read_active)
            cpu_mem_read = sdram_read_reg;
        else if (state == S_FLASH_DONE || flash_read_active)
            cpu_mem_read = flash_read_reg;
        else
            cpu_mem_read = bram_read;

        if (state == S_IDLE)
            cpu_stall = is_sdram_addr || is_flash_addr;
        else if (state == S_SDRAM_DONE || state == S_FLASH_DONE)
            cpu_stall = 1'b0;
        else
            cpu_stall = 1'b1;
    end
endmodule
