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

module mmu #(
    parameter int TLB_ENTRIES = 16
) (
    input logic clk,
    input logic rst,
    input logic stall,

    input logic user_mode,
    input logic [31:0] ptbase,
    input logic [3:0] asid,
    input logic flush,

    input logic [31:0] fetch_address,
    input logic [31:0] fetch_next,
    input logic [31:0] fetch_current,
    input logic fetch_repeat,
    input logic fetch_lookup,
    output logic [10:0] fetch_frame,
    output logic fetch_translated,
    output logic fetch_fault,
    output logic fetch_request,

    input logic [31:0] ex_address,
    input logic [31:0] data_address,
    input logic data_access,
    input logic data_write,
    output logic [10:0] data_frame,
    output logic data_request,
    output logic data_denied,
    output logic data_fault,

    input logic grant_data,
    input logic grant_fetch,
    input logic memory_ready,
    input logic memory_valid,
    input logic [31:0] memory_data,
    output logic memory_start,
    output logic [20:0] memory_address,
    output logic walk_done,
    output logic walk_resolved,
    output logic walk_failed,
    output logic [10:0] walk_frame
);
    logic [TLB_ENTRIES - 1:0] tlb_valid;
    logic [3:0] tlb_asid [0:TLB_ENTRIES - 1];
    logic [17:0] tlb_page [0:TLB_ENTRIES - 1];
    logic [10:0] tlb_frame [0:TLB_ENTRIES - 1];
    logic [TLB_ENTRIES - 1:0] tlb_writable;
    logic [TLB_ENTRIES - 1:0] tlb_executable;
    logic [$clog2(TLB_ENTRIES) - 1:0] tlb_next;

    logic next_hit;
    logic [10:0] next_frame;
    logic next_executable;
    logic current_hit;
    logic [10:0] current_frame;
    logic current_executable;
    logic ex_hit;
    logic [10:0] ex_frame;
    logic ex_writable;

    always_comb begin
        next_hit = 1'b0;
        next_frame = '0;
        next_executable = 1'b0;
        current_hit = 1'b0;
        current_frame = '0;
        current_executable = 1'b0;
        ex_hit = 1'b0;
        ex_frame = '0;
        ex_writable = 1'b0;

        for (int i = 0; i < TLB_ENTRIES; i++) begin
            if (tlb_valid[i] && tlb_asid[i] == asid && tlb_page[i] == fetch_next[29:12]) begin
                next_hit = 1'b1;
                next_frame = next_frame | tlb_frame[i];
                next_executable = next_executable | tlb_executable[i];
            end

            if (tlb_valid[i] && tlb_asid[i] == asid && tlb_page[i] == fetch_current[29:12]) begin
                current_hit = 1'b1;
                current_frame = current_frame | tlb_frame[i];
                current_executable = current_executable | tlb_executable[i];
            end

            if (tlb_valid[i] && tlb_asid[i] == asid && tlb_page[i] == ex_address[29:12]) begin
                ex_hit = 1'b1;
                ex_frame = ex_frame | tlb_frame[i];
                ex_writable = ex_writable | tlb_writable[i];
            end
        end
    end

    wire fetch_window = fetch_address[31:30] == 2'b11;
    wire fetch_hit = fetch_repeat ? current_hit : next_hit;
    wire fetch_executable = fetch_repeat ? current_executable : next_executable;

    assign fetch_frame = fetch_repeat ? current_frame : next_frame;

    logic lookup_window;
    logic lookup_hit;
    logic lookup_executable;
    logic lookup_denied;
    logic [17:0] lookup_page;
    logic fetch_pending;

    wire fetch_miss = fetch_lookup && lookup_window && !lookup_hit;

    assign fetch_translated = !(lookup_window && (!lookup_hit || !lookup_executable));
    assign fetch_fault = lookup_denied || (fetch_lookup && lookup_window && lookup_hit && !lookup_executable);
    assign fetch_request = fetch_miss || fetch_pending;

    logic data_hit;
    logic data_writable;

    wire data_window = data_address[31:30] == 2'b11;

    assign data_request = data_access && data_window && !data_hit;
    assign data_denied = data_access && data_write && data_window && data_hit && !data_writable;

    typedef enum logic [1:0] {
        W_IDLE,
        W_REQUEST,
        W_WAIT,
        W_CHECK
    } walk_state_t;

    walk_state_t walk_state;
    logic walk_data;
    logic walk_leaf;
    logic [17:0] walk_page;
    logic [31:0] walk_entry;

    assign memory_start = walk_state == W_REQUEST && memory_ready;
    assign walk_done = walk_state == W_CHECK && (!walk_entry[0] || walk_leaf);
    assign walk_resolved = walk_done && !walk_data && walk_entry[0] && walk_entry[2];
    assign walk_failed = walk_done && !walk_data && !(walk_entry[0] && walk_entry[2]);
    assign walk_frame = walk_entry[22:12];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            tlb_valid <= '0;
            tlb_next <= '0;
            lookup_window <= 1'b0;
            lookup_hit <= 1'b0;
            lookup_executable <= 1'b0;
            lookup_denied <= 1'b0;
            lookup_page <= '0;
            fetch_pending <= 1'b0;
            data_hit <= 1'b0;
            data_frame <= '0;
            data_writable <= 1'b0;
            data_fault <= 1'b0;
            walk_state <= W_IDLE;
            walk_data <= 1'b0;
            walk_leaf <= 1'b0;
            walk_page <= '0;
            walk_entry <= '0;
            memory_address <= '0;
        end else begin
            if (flush)
                tlb_valid <= '0;

            if (!stall) begin
                lookup_window <= fetch_window;
                lookup_hit <= fetch_hit;
                lookup_executable <= fetch_executable;
                lookup_denied <= user_mode && !fetch_window;
                lookup_page <= fetch_address[29:12];

                data_hit <= ex_hit && !flush;
                data_frame <= ex_frame;
                data_writable <= ex_writable;
                data_fault <= 1'b0;
            end

            if (grant_fetch)
                fetch_pending <= 1'b0;
            else if (fetch_miss)
                fetch_pending <= 1'b1;

            if (data_denied)
                data_fault <= 1'b1;

            case (walk_state)
                W_IDLE: begin
                    if (grant_data || grant_fetch) begin
                        walk_data <= grant_data;
                        walk_leaf <= 1'b0;
                        walk_page <= grant_data ? data_address[29:12] : lookup_page;
                        memory_address <= {ptbase[22:10], grant_data ? data_address[29:22] : lookup_page[17:10]};

                        if (ptbase[0]) begin
                            walk_state <= W_REQUEST;
                        end else begin
                            walk_entry <= '0;
                            walk_state <= W_CHECK;
                        end
                    end
                end

                W_REQUEST: begin
                    if (memory_ready)
                        walk_state <= W_WAIT;
                end

                W_WAIT: begin
                    if (memory_valid) begin
                        walk_entry <= memory_data;
                        walk_state <= W_CHECK;
                    end
                end

                W_CHECK: begin
                    if (!walk_entry[0]) begin
                        walk_state <= W_IDLE;

                        if (walk_data)
                            data_fault <= 1'b1;
                    end else if (!walk_leaf) begin
                        walk_leaf <= 1'b1;
                        memory_address <= {walk_entry[22:12], walk_page[9:0]};
                        walk_state <= W_REQUEST;
                    end else begin
                        tlb_valid[tlb_next] <= 1'b1;
                        tlb_asid[tlb_next] <= asid;
                        tlb_page[tlb_next] <= walk_page;
                        tlb_frame[tlb_next] <= walk_entry[22:12];
                        tlb_writable[tlb_next] <= walk_entry[1];
                        tlb_executable[tlb_next] <= walk_entry[2];
                        tlb_next <= tlb_next + 1'b1;
                        walk_state <= W_IDLE;

                        if (walk_data) begin
                            data_hit <= 1'b1;
                            data_frame <= walk_entry[22:12];
                            data_writable <= walk_entry[1];
                        end
                    end
                end
            endcase
        end
    end
endmodule
