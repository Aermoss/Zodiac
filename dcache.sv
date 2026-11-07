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

module dcache #(
    parameter int LINES = 256,
    parameter int LINE_WORDS = 4,
    parameter int TAG_BITS = 11
) (
    input logic clk,
    input logic rst,

    input logic capture,
    input logic request,
    input logic [31:0] address,
    input logic [TAG_BITS - 1:0] tag,
    output logic lookup,
    output logic [31:0] read_data,
    output logic fill_request,
    output logic clearing,

    input logic flush,
    input logic store,
    input logic [20:0] store_address,
    input logic [31:0] store_data,
    input logic [3:0] store_dqm,

    input logic grant,
    input logic memory_ready,
    input logic memory_valid,
    input logic [31:0] memory_data,
    output logic memory_start,
    output logic [20:0] memory_address,
    output logic word_valid,
    output logic fill_done
);
    localparam int OFFSET_BITS = $clog2(LINE_WORDS);
    localparam int INDEX_BITS = $clog2(LINES);

    wire [OFFSET_BITS - 1:0] offset = address[2 +: OFFSET_BITS];
    wire [INDEX_BITS - 1:0] index = address[2 + OFFSET_BITS +: INDEX_BITS];

    logic [31:0] data [0:LINES * LINE_WORDS - 1];
    logic [TAG_BITS:0] tags [0:LINES - 1];
    logic read_valid;
    logic [TAG_BITS - 1:0] read_tag;

    logic [OFFSET_BITS - 1:0] lookup_offset;
    logic [INDEX_BITS - 1:0] lookup_index;
    logic [TAG_BITS - 1:0] lookup_tag;
    logic pending;
    logic issued;
    logic [OFFSET_BITS - 1:0] fill_offset;
    logic [INDEX_BITS - 1:0] clear_index;

    wire miss = lookup && !(read_valid && read_tag == lookup_tag);
    wire fill_write = grant && issued && memory_valid;
    wire store_hit = store && read_valid && read_tag == store_address[20 -: TAG_BITS];
    logic [31:0] store_word;

    always_comb begin
        for (int i = 0; i < 4; i++)
            store_word[8 * i +: 8] = store_dqm[i] ? read_data[8 * i +: 8] : store_data[8 * i +: 8];
    end

    assign fill_request = miss || pending;
    assign memory_start = grant && !issued && memory_ready;
    assign memory_address = {lookup_tag, lookup_index, fill_offset};
    assign word_valid = fill_write && fill_offset == lookup_offset;
    assign fill_done = fill_write && fill_offset == {OFFSET_BITS{1'b1}};

    always_ff @(posedge clk) begin
        if (fill_write)
            data[{lookup_index, fill_offset}] <= memory_data;
        else if (store_hit)
            data[store_address[OFFSET_BITS + INDEX_BITS - 1:0]] <= store_word;

        if (clearing)
            tags[clear_index] <= '0;
        else if (fill_done)
            tags[lookup_index] <= {1'b1, lookup_tag};

        read_data <= data[{index, offset}];
        {read_valid, read_tag} <= tags[index];
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            lookup <= 1'b0;
            lookup_offset <= '0;
            lookup_index <= '0;
            lookup_tag <= '0;
            pending <= 1'b0;
            issued <= 1'b0;
            fill_offset <= '0;
            clearing <= 1'b1;
            clear_index <= '0;
        end else begin
            if (clearing) begin
                clear_index <= clear_index + 1'b1;

                if (clear_index == {INDEX_BITS{1'b1}})
                    clearing <= 1'b0;
            end

            if (flush) begin
                clearing <= 1'b1;
                clear_index <= '0;
            end

            if (capture) begin
                lookup <= request;
                lookup_offset <= offset;
                lookup_index <= index;
                lookup_tag <= tag;
            end else begin
                lookup <= 1'b0;
            end

            if (grant)
                pending <= 1'b0;
            else if (miss)
                pending <= 1'b1;

            if (memory_start)
                issued <= 1'b1;

            if (fill_write) begin
                issued <= 1'b0;
                fill_offset <= fill_offset + 1'b1;
            end
        end
    end
endmodule
