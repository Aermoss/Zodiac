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

module bus #(
    parameter int CLK_FREQ = 54000000
) (
    input logic clk,
    input logic rst,

    input logic [31:0] cpu_fetch_addr,
    output logic [31:0] cpu_fetch_read,

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
    output logic [31:0] bram_fetch_addr,
    input logic [31:0] bram_fetch_read,

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
    wire is_sdram_fetch = (cpu_fetch_addr[31:30] == 2'b01);
    wire is_sdram_data = cpu_mem_access && (cpu_mem_addr[31:30] == 2'b01);
    wire is_sdram_load = is_sdram_data && (cpu_mem_we == 4'b0000);
    wire is_sdram_store = is_sdram_data && (cpu_mem_we != 4'b0000);
    wire is_flash_data = cpu_mem_access && (cpu_mem_addr[31:30] == 2'b10) && (cpu_mem_we == 4'b0000);
    wire is_bram_data = cpu_mem_access && (cpu_mem_addr[31:30] != 2'b01) && (cpu_mem_addr[31:30] != 2'b10);

    wire [20:0] sdram_word_addr = {cpu_mem_addr[22:21], cpu_mem_addr[20:10], cpu_mem_addr[9:2]};
    wire [20:0] fetch_word_addr = {cpu_fetch_addr[22:21], cpu_fetch_addr[20:10], cpu_fetch_addr[9:2]};
    wire [23:0] flash_byte_addr = {cpu_mem_addr[23:2], 2'b00};

    localparam int CACHE_LINES = 1024;
    localparam int LINE_WORDS = 4;
    localparam int OFFSET_BITS = $clog2(LINE_WORDS);
    localparam int INDEX_BITS = $clog2(CACHE_LINES);
    localparam int TAG_BITS = 21 - INDEX_BITS - OFFSET_BITS;
    localparam int DCACHE_LINES = 256;
    localparam int DINDEX_BITS = $clog2(DCACHE_LINES);
    localparam int DTAG_BITS = 21 - DINDEX_BITS - OFFSET_BITS;

    wire [OFFSET_BITS - 1:0] fetch_offset = fetch_word_addr[OFFSET_BITS - 1:0];
    wire [INDEX_BITS - 1:0] fetch_index = fetch_word_addr[OFFSET_BITS +: INDEX_BITS];
    wire [TAG_BITS - 1:0] fetch_tag = fetch_word_addr[20 -: TAG_BITS];
    wire [OFFSET_BITS - 1:0] data_offset = sdram_word_addr[OFFSET_BITS - 1:0];
    wire [DINDEX_BITS - 1:0] data_index = sdram_word_addr[OFFSET_BITS +: DINDEX_BITS];
    wire [DTAG_BITS - 1:0] data_tag = sdram_word_addr[20 -: DTAG_BITS];

    localparam int REFRESH_CYCLES = CLK_FREQ / 1000000 * 15;

    typedef enum logic [3:0] {
        S_IDLE,
        S_ACTIVATE_WAIT,
        S_SDRAM_WAIT,
        S_READ_DELAY,
        S_WRITE_DELAY,
        S_SDRAM_DONE,
        S_FLASH_WAIT,
        S_FLASH_DONE,
        S_FILL,
        S_REFRESH
    } state_t;

    state_t state;
    logic [2:0] read_delay_counter;
    logic [2:0] write_delay_counter;

    logic [31:0] flash_read_reg;
    logic flash_read_active;

    logic [$clog2(REFRESH_CYCLES) - 1:0] refresh_counter;
    logic refresh_pending;

    logic [31:0] read_data;
    logic [31:0] read_hold;
    logic read_held;

    logic [31:0] fetch_data;
    logic [31:0] fetch_hold;
    logic fetch_held;

    logic [20:0] r_sdrc_addr;
    logic [31:0] r_sdrc_data_w;
    logic [2:0] r_sdrc_cmd;
    logic [3:0] r_sdrc_dqm;
    logic r_sdrc_is_read;

    assign sdrc_addr = r_sdrc_addr;
    assign sdrc_data_w = r_sdrc_data_w;
    assign sdrc_cmd = r_sdrc_cmd;
    assign sdrc_dqm = r_sdrc_dqm;

    logic [31:0] cache_data [0:CACHE_LINES * LINE_WORDS - 1];
    logic [TAG_BITS:0] cache_tags [0:CACHE_LINES - 1];
    logic [31:0] cache_read;
    logic [TAG_BITS - 1:0] cache_read_tag;
    logic cache_read_valid;
    logic clearing;
    logic [INDEX_BITS - 1:0] clear_index;

    logic lookup;
    logic [OFFSET_BITS - 1:0] lookup_offset;
    logic [INDEX_BITS - 1:0] lookup_index;
    logic [TAG_BITS - 1:0] lookup_tag;
    logic miss_pending;
    logic filling;
    logic [OFFSET_BITS - 1:0] fill_offset;

    logic [31:0] dcache_data [0:DCACHE_LINES * LINE_WORDS - 1];
    logic [DTAG_BITS - 1:0] dcache_tags [0:DCACHE_LINES - 1];
    logic [DCACHE_LINES - 1:0] dcache_valid;
    logic [31:0] dcache_read;
    logic [DTAG_BITS - 1:0] dcache_read_tag;

    logic dlookup;
    logic dlookup_valid;
    logic [OFFSET_BITS - 1:0] dlookup_offset;
    logic [DINDEX_BITS - 1:0] dlookup_index;
    logic [DTAG_BITS - 1:0] dlookup_tag;
    logic dmiss_pending;
    logic filling_data;
    logic store_check;

    wire [OFFSET_BITS - 1:0] sdrc_offset = r_sdrc_addr[OFFSET_BITS - 1:0];
    wire [DINDEX_BITS - 1:0] sdrc_index = r_sdrc_addr[OFFSET_BITS +: DINDEX_BITS];
    wire [DTAG_BITS - 1:0] sdrc_tag = r_sdrc_addr[20 -: DTAG_BITS];
    wire [INDEX_BITS - 1:0] sdrc_code_index = r_sdrc_addr[OFFSET_BITS +: INDEX_BITS];

    wire cache_miss = lookup && !(cache_read_valid && cache_read_tag == lookup_tag);
    wire dcache_miss = dlookup && !(dlookup_valid && dcache_read_tag == dlookup_tag);
    wire fill_write = filling && state == S_READ_DELAY && read_delay_counter <= 3'd1;

    wire store_hit = store_check && dcache_valid[sdrc_index] && dcache_read_tag == sdrc_tag;
    logic [31:0] store_word;

    always_comb begin
        for (int i = 0; i < 4; i++)
            store_word[8 * i +: 8] = r_sdrc_dqm[i] ? dcache_read[8 * i +: 8] : r_sdrc_data_w[8 * i +: 8];
    end

    always_ff @(posedge clk) begin
        if (fill_write && !filling_data)
            cache_data[{lookup_index, fill_offset}] <= sdrc_data_r;

        if (clearing)
            cache_tags[clear_index] <= '0;
        else if (store_check)
            cache_tags[sdrc_code_index] <= '0;
        else if (fill_write && !filling_data && fill_offset == {OFFSET_BITS{1'b1}})
            cache_tags[lookup_index] <= {1'b1, lookup_tag};

        cache_read <= cache_data[{fetch_index, fetch_offset}];
        {cache_read_valid, cache_read_tag} <= cache_tags[fetch_index];
    end

    always_ff @(posedge clk) begin
        if ((fill_write && filling_data) || store_hit)
            dcache_data[{sdrc_index, sdrc_offset}] <= store_hit ? store_word : sdrc_data_r;

        if (fill_write && filling_data && fill_offset == {OFFSET_BITS{1'b1}})
            dcache_tags[sdrc_index] <= sdrc_tag;

        dcache_read <= dcache_data[{data_index, data_offset}];
        dcache_read_tag <= dcache_tags[data_index];
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            sdrc_cmd_en <= 1'b0;
            r_sdrc_cmd <= 3'b000;
            r_sdrc_addr <= 21'b0;
            r_sdrc_data_w <= 32'b0;
            r_sdrc_dqm <= 4'b0000;
            r_sdrc_is_read <= 1'b0;
            read_delay_counter <= 3'b0;
            write_delay_counter <= 3'b0;
            flash_req <= 1'b0;
            flash_addr <= 24'b0;
            flash_read_reg <= 32'b0;
            flash_read_active <= 1'b0;
            refresh_counter <= '0;
            refresh_pending <= 1'b0;
            read_hold <= 32'b0;
            read_held <= 1'b0;
            fetch_hold <= 32'b0;
            fetch_held <= 1'b0;
            clearing <= 1'b1;
            clear_index <= '0;
            lookup <= 1'b0;
            lookup_offset <= '0;
            lookup_index <= '0;
            lookup_tag <= '0;
            miss_pending <= 1'b0;
            filling <= 1'b0;
            fill_offset <= '0;
            dcache_valid <= '0;
            dlookup <= 1'b0;
            dlookup_valid <= 1'b0;
            dlookup_offset <= '0;
            dlookup_index <= '0;
            dlookup_tag <= '0;
            dmiss_pending <= 1'b0;
            filling_data <= 1'b0;
            store_check <= 1'b0;
        end else begin
            flash_read_active <= 1'b0;
            flash_req <= 1'b0;
            store_check <= 1'b0;

            if (clearing) begin
                clear_index <= clear_index + 1'b1;

                if (clear_index == {INDEX_BITS{1'b1}})
                    clearing <= 1'b0;
            end

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
                    fetch_held <= 1'b1;
                end
            end

            if (!cpu_stall) begin
                lookup <= is_sdram_fetch;
                lookup_offset <= fetch_offset;
                lookup_index <= fetch_index;
                lookup_tag <= fetch_tag;

                dlookup <= is_sdram_load;
                dlookup_valid <= dcache_valid[data_index];
                dlookup_offset <= data_offset;
                dlookup_index <= data_index;
                dlookup_tag <= data_tag;
            end else begin
                lookup <= 1'b0;
                dlookup <= 1'b0;
            end

            if (cache_miss && state != S_IDLE)
                miss_pending <= 1'b1;

            if (dcache_miss && state != S_IDLE)
                dmiss_pending <= 1'b1;

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
                    if (dcache_miss || dmiss_pending) begin
                        dmiss_pending <= 1'b0;
                        miss_pending <= miss_pending || cache_miss;
                        filling <= 1'b1;
                        filling_data <= 1'b1;
                        fill_offset <= '0;
                        state <= S_FILL;
                    end else if (cache_miss || miss_pending) begin
                        miss_pending <= 1'b0;
                        filling <= 1'b1;
                        filling_data <= 1'b0;
                        fill_offset <= '0;
                        state <= S_FILL;
                    end else if (refresh_pending) begin
                        refresh_pending <= 1'b0;
                        sdrc_cmd_en <= 1'b1;
                        r_sdrc_cmd <= 3'b001;
                        state <= S_REFRESH;
                    end else if (is_sdram_store && sdrc_init_done) begin
                        sdrc_cmd_en <= 1'b1;
                        r_sdrc_addr <= sdram_word_addr;
                        r_sdrc_data_w <= cpu_mem_write;
                        r_sdrc_dqm <= ~cpu_mem_we;
                        r_sdrc_is_read <= 1'b0;
                        r_sdrc_cmd <= 3'b011;
                        store_check <= 1'b1;
                        state <= S_ACTIVATE_WAIT;
                    end else if (is_flash_data) begin
                        flash_req <= 1'b1;
                        flash_addr <= flash_byte_addr;
                        state <= S_FLASH_WAIT;
                    end
                end

                S_FILL: begin
                    if (sdrc_init_done) begin
                        sdrc_cmd_en <= 1'b1;
                        r_sdrc_addr <= filling_data ? {dlookup_tag, dlookup_index, fill_offset} : {lookup_tag, lookup_index, fill_offset};
                        r_sdrc_dqm <= 4'b0000;
                        r_sdrc_is_read <= 1'b1;
                        r_sdrc_cmd <= 3'b011;
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

                        if (r_sdrc_is_read)
                            r_sdrc_cmd <= 3'b101;
                        else
                            r_sdrc_cmd <= 3'b100;

                        state <= S_SDRAM_WAIT;
                    end
                end

                S_SDRAM_WAIT: begin
                    sdrc_cmd_en <= 1'b0;

                    if (sdrc_cmd_ack) begin
                        if (r_sdrc_is_read) begin
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
                        if (filling_data && fill_offset == dlookup_offset)
                            read_hold <= sdrc_data_r;
                        else if (!filling_data && fill_offset == lookup_offset)
                            fetch_hold <= sdrc_data_r;

                        if (fill_offset == {OFFSET_BITS{1'b1}}) begin
                            if (filling_data)
                                dcache_valid[dlookup_index] <= 1'b1;

                            filling <= 1'b0;
                            state <= S_IDLE;
                        end else begin
                            fill_offset <= fill_offset + 1'b1;
                            state <= S_FILL;
                        end
                    end
                end

                S_WRITE_DELAY: begin
                    if (write_delay_counter > 3'd1)
                        write_delay_counter <= write_delay_counter - 3'd1;
                    else
                        state <= S_SDRAM_DONE;
                end

                S_SDRAM_DONE: state <= S_IDLE;

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
        if (clearing)
            cpu_stall = 1'b1;
        else if (state == S_IDLE || state == S_REFRESH)
            cpu_stall = cache_miss || miss_pending || dcache_miss || dmiss_pending || is_sdram_store || is_flash_data;
        else if (state == S_SDRAM_DONE || state == S_FLASH_DONE)
            cpu_stall = 1'b0;
        else
            cpu_stall = 1'b1;

        bram_addr = cpu_mem_addr;
        bram_write = cpu_mem_write;
        bram_fetch_addr = cpu_fetch_addr;
        bram_we = 4'b0000;

        if (is_bram_data && !cpu_stall)
            bram_we = cpu_mem_we;

        if (dlookup)
            read_data = dcache_read;
        else if (flash_read_active)
            read_data = flash_read_reg;
        else
            read_data = bram_read;

        fetch_data = lookup ? cache_read : bram_fetch_read;
        cpu_fetch_read = fetch_held ? fetch_hold : fetch_data;

        if (!read_held && !dlookup && !flash_read_active)
            cpu_mem_read = bram_read;
        else if (read_held)
            cpu_mem_read = read_hold;
        else
            cpu_mem_read = read_data;
    end
endmodule
