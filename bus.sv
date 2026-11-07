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

    input logic [31:0] cpu_fetch_addr,
    output logic [31:0] cpu_fetch_read,
    output logic cpu_fetch_fault,

    input logic cpu_mem_access,
    input logic [3:0] cpu_mem_we,
    input logic [31:0] cpu_mem_addr,
    input logic [31:0] cpu_mem_write,
    output logic [31:0] cpu_mem_read,
    output logic cpu_stall,

    input logic cpu_user_mode,

    output logic [3:0] bram_we,
    output logic [31:0] bram_addr,
    output logic [31:0] bram_write,
    input logic [31:0] bram_read,
    output logic [31:0] bram_fetch_addr,
    input logic [31:0] bram_fetch_read,

    output logic flash_req,
    output logic [23:0] flash_addr,
    input logic [31:0] flash_rdata,
    input logic flash_ready,

    output logic sdram_start,
    output logic sdram_write,
    output logic [20:0] sdram_address,
    output logic [31:0] sdram_data,
    output logic [3:0] sdram_dqm,
    input logic sdram_ready,
    input logic sdram_write_done,
    input logic [31:0] sdram_read_data,
    output logic store_check,

    output logic icache_request,
    output logic [10:0] icache_tag,
    input logic icache_lookup,
    input logic [31:0] icache_read,
    input logic icache_fill_request,
    input logic icache_clearing,
    output logic icache_grant,
    input logic icache_start,
    input logic [20:0] icache_address,
    input logic icache_word,
    input logic icache_done,

    output logic dcache_request,
    output logic [10:0] dcache_tag,
    input logic dcache_lookup,
    input logic [31:0] dcache_read,
    input logic dcache_fill_request,
    input logic dcache_clearing,
    output logic dcache_grant,
    input logic dcache_start,
    input logic [20:0] dcache_address,
    input logic dcache_word,
    input logic dcache_done,

    input logic [10:0] mmu_fetch_frame,
    input logic mmu_fetch_fault,
    input logic mmu_fetch_request,
    input logic [10:0] mmu_data_frame,
    input logic mmu_data_request,
    input logic mmu_data_denied,
    output logic mmu_grant_data,
    output logic mmu_grant_fetch,
    input logic mmu_start,
    input logic [20:0] mmu_address,
    input logic mmu_walk_done,
    input logic mmu_walk_failed
);
    wire fetch_window = cpu_fetch_addr[31:30] == 2'b11;
    wire data_window = cpu_mem_addr[31:30] == 2'b11;
    wire fetch_denied = cpu_user_mode && !fetch_window;

    wire is_sdram_fetch = (cpu_fetch_addr[31:30] == 2'b01 || fetch_window) && !fetch_denied;
    wire is_sdram_data = cpu_mem_access && (cpu_mem_addr[31:30] == 2'b01 || data_window);
    wire is_sdram_load = is_sdram_data && (cpu_mem_we == 4'b0000);
    wire is_sdram_store = is_sdram_data && (cpu_mem_we != 4'b0000);
    wire is_flash_data = cpu_mem_access && (cpu_mem_addr[31:30] == 2'b10) && (cpu_mem_we == 4'b0000);
    wire is_bram_data = cpu_mem_access && (cpu_mem_addr[31:30] == 2'b00);

    wire [10:0] data_frame = data_window ? mmu_data_frame : cpu_mem_addr[22:12];
    wire [20:0] sdram_word_addr = {data_frame, cpu_mem_addr[11:2]};

    assign icache_request = is_sdram_fetch;
    assign icache_tag = fetch_window ? mmu_fetch_frame : cpu_fetch_addr[22:12];
    assign dcache_request = is_sdram_load;
    assign dcache_tag = data_frame;

    typedef enum logic [2:0] {
        S_IDLE,
        S_DCACHE,
        S_WALK_DATA,
        S_ICACHE,
        S_WALK_FETCH,
        S_STORE,
        S_FLASH_WAIT,
        S_FLASH_DONE
    } state_t;

    state_t state;

    logic [31:0] flash_read_reg;
    logic flash_read_active;

    logic [31:0] read_data;
    logic [31:0] read_hold;
    logic read_held;

    logic [31:0] fetch_data;
    logic [31:0] fetch_hold;
    logic fetch_held;
    logic fetch_fault_hold;

    wire store_go = state == S_IDLE && !dcache_fill_request && !mmu_data_request && !icache_fill_request && !mmu_fetch_request &&
        is_sdram_store && !mmu_data_denied && sdram_ready;

    assign icache_grant = state == S_ICACHE;
    assign dcache_grant = state == S_DCACHE;
    assign mmu_grant_data = state == S_WALK_DATA;
    assign mmu_grant_fetch = state == S_WALK_FETCH;
    assign cpu_fetch_fault = fetch_held ? fetch_fault_hold : mmu_fetch_fault;

    always_comb begin
        sdram_start = 1'b0;
        sdram_write = 1'b0;
        sdram_address = sdram_word_addr;
        sdram_data = cpu_mem_write;
        sdram_dqm = 4'b0000;

        case (state)
            S_IDLE: begin
                sdram_start = store_go;
                sdram_write = 1'b1;
                sdram_dqm = ~cpu_mem_we;
            end

            S_DCACHE: begin
                sdram_start = dcache_start;
                sdram_address = dcache_address;
            end

            S_ICACHE: begin
                sdram_start = icache_start;
                sdram_address = icache_address;
            end

            S_WALK_DATA, S_WALK_FETCH: begin
                sdram_start = mmu_start;
                sdram_address = mmu_address;
            end

            default: ;
        endcase
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            flash_req <= 1'b0;
            flash_addr <= 24'b0;
            flash_read_reg <= 32'b0;
            flash_read_active <= 1'b0;
            read_hold <= 32'b0;
            read_held <= 1'b0;
            fetch_hold <= 32'b0;
            fetch_held <= 1'b0;
            fetch_fault_hold <= 1'b0;
            store_check <= 1'b0;
        end else begin
            flash_read_active <= 1'b0;
            flash_req <= 1'b0;
            store_check <= 1'b0;

            if (!cpu_stall) begin
                read_held <= 1'b0;
                fetch_held <= 1'b0;
            end else begin
                if (!read_held) begin
                    read_hold <= read_data;
                    read_held <= 1'b1;
                end

                if (!fetch_held) begin
                    fetch_hold <= fetch_data;
                    fetch_fault_hold <= mmu_fetch_fault;
                    fetch_held <= 1'b1;
                end
            end

            if (dcache_word)
                read_hold <= sdram_read_data;

            if (icache_word)
                fetch_hold <= sdram_read_data;

            if (mmu_walk_failed)
                fetch_fault_hold <= 1'b1;

            case (state)
                S_IDLE: begin
                    if (dcache_fill_request) begin
                        state <= S_DCACHE;
                    end else if (mmu_data_request) begin
                        state <= S_WALK_DATA;
                    end else if (icache_fill_request) begin
                        state <= S_ICACHE;
                    end else if (mmu_fetch_request) begin
                        state <= S_WALK_FETCH;
                    end else if (store_go) begin
                        store_check <= 1'b1;
                        state <= S_STORE;
                    end else if (is_flash_data) begin
                        flash_req <= 1'b1;
                        flash_addr <= {cpu_mem_addr[23:2], 2'b00};
                        state <= S_FLASH_WAIT;
                    end
                end

                S_DCACHE: begin
                    if (dcache_done)
                        state <= S_IDLE;
                end

                S_ICACHE: begin
                    if (icache_done)
                        state <= S_IDLE;
                end

                S_WALK_DATA, S_WALK_FETCH: begin
                    if (mmu_walk_done)
                        state <= S_IDLE;
                end

                S_STORE: begin
                    if (sdram_write_done)
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
        if (icache_clearing || dcache_clearing)
            cpu_stall = 1'b1;
        else if (state == S_IDLE)
            cpu_stall = icache_fill_request || dcache_fill_request || mmu_data_request || mmu_fetch_request || is_sdram_store || is_flash_data;
        else if (state == S_STORE)
            cpu_stall = !sdram_write_done;
        else if (state == S_FLASH_DONE)
            cpu_stall = 1'b0;
        else
            cpu_stall = 1'b1;

        bram_addr = cpu_mem_addr;
        bram_write = cpu_mem_write;
        bram_fetch_addr = cpu_fetch_addr;
        bram_we = 4'b0000;

        if (is_bram_data && !cpu_stall)
            bram_we = cpu_mem_we;

        if (dcache_lookup)
            read_data = dcache_read;
        else if (flash_read_active)
            read_data = flash_read_reg;
        else
            read_data = bram_read;

        fetch_data = icache_lookup ? icache_read : bram_fetch_read;
        cpu_fetch_read = fetch_held ? fetch_hold : fetch_data;

        if (!read_held && !dcache_lookup && !flash_read_active)
            cpu_mem_read = bram_read;
        else if (read_held)
            cpu_mem_read = read_hold;
        else
            cpu_mem_read = read_data;
    end
endmodule
