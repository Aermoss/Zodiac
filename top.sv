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

module top (
    input logic clk,
    input logic rst,

    input logic uart_rx,
    output logic uart_tx,

    input logic button,
    output logic [5:0] leds,
    output logic ws2812,

    output logic tmds_clk_p,
    output logic tmds_clk_n,
    output logic [2:0] tmds_d_p,
    output logic [2:0] tmds_d_n,

    output wire spi_cs_pin,
    output wire spi_clk_pin,
    output wire spi_mosi_pin,
    input wire spi_miso_pin,

    output logic O_sdram_clk,
    output logic O_sdram_cke,
    output logic O_sdram_cs_n,
    output logic O_sdram_cas_n,
    output logic O_sdram_ras_n,
    output logic O_sdram_wen_n,
    output logic [3:0] O_sdram_dqm,
    output logic [10:0] O_sdram_addr,
    output logic [1:0] O_sdram_ba,
    inout wire [31:0] IO_sdram_dq
);
    logic sys_clk;
    logic sdram_clk;
    logic pll_lock;

    Gowin_rPLL pll0 (
        .clkin(clk),
        .reset(rst),
        .clkout(sys_clk),
        .clkoutp(sdram_clk),
        .lock(pll_lock)
    );

    logic rst_reg;
    logic [7:0] counter = 8'd0;

    always_ff @(posedge sys_clk) begin
        if (!pll_lock) begin
            counter <= 8'd0;
            rst_reg <= 1'b1;
        end else if (counter < 8'hFF) begin
            counter <= counter + 8'd1;
            rst_reg <= 1'b1;
        end else begin
            rst_reg <= rst;
        end
    end

    localparam int CLK_FREQ = 54000000;

    logic [31:0] cpu_fetch_addr;
    logic [31:0] cpu_fetch_next;
    logic [31:0] cpu_fetch_current;
    logic cpu_fetch_repeat;
    logic [31:0] cpu_fetch_read;
    logic cpu_mem_access;
    logic [3:0] cpu_mem_we;
    logic [31:0] cpu_mem_addr;
    logic [31:0] cpu_ex_addr;
    logic [31:0] cpu_mem_write;
    logic [31:0] cpu_mem_read;
    logic cpu_stall;
    logic flash_raw_enable;
    logic flash_raw_start;
    logic [7:0] flash_raw_tx;
    logic [7:0] flash_raw_rx;
    logic flash_raw_busy;
    logic video_write;
    logic [11:0] video_address;
    logic [15:0] video_data;
    logic [15:0] video_cursor;
    logic [4:0] video_scroll;
    logic cpu_fetch_fault;
    logic cpu_data_fault;
    logic cpu_user_mode;
    logic [31:0] cpu_ptbase;
    logic [3:0] cpu_asid;
    logic cpu_tlb_flush;
    logic cpu_cache_flush;

    cpu #(
        .SIMULATION(1'b0),
        .CLK_FREQ(CLK_FREQ)
    ) cpu0 (
        .clk(sys_clk),
        .rst(rst_reg),

        .uart_rx(uart_rx),
        .uart_tx(uart_tx),

        .button(button),
        .leds(leds),
        .ws2812(ws2812),

        .flash_raw_enable(flash_raw_enable),
        .flash_raw_start(flash_raw_start),
        .flash_raw_tx(flash_raw_tx),
        .flash_raw_rx(flash_raw_rx),
        .flash_raw_busy(flash_raw_busy),

        .video_write(video_write),
        .video_address(video_address),
        .video_data(video_data),
        .video_cursor(video_cursor),
        .video_scroll(video_scroll),

        .fetch_addr(cpu_fetch_addr),
        .fetch_next(cpu_fetch_next),
        .fetch_current(cpu_fetch_current),
        .fetch_repeat(cpu_fetch_repeat),
        .fetch_read(cpu_fetch_read),
        .fetch_fault(cpu_fetch_fault),

        .mem_access(cpu_mem_access),
        .actual_mem_we(cpu_mem_we),
        .mem_addr(cpu_mem_addr),
        .ex_addr(cpu_ex_addr),
        .mem_write(cpu_mem_write),
        .mem_read(cpu_mem_read),
        .data_fault(cpu_data_fault),

        .user_mode(cpu_user_mode),
        .csr_ptbase(cpu_ptbase),
        .csr_asid(cpu_asid),
        .tlb_flush(cpu_tlb_flush),
        .cache_flush(cpu_cache_flush),

        .bus_stall(cpu_stall)
    );

    logic [3:0] bram_we;
    logic [31:0] bram_addr;
    logic [31:0] bram_write;
    logic [31:0] bram_read;
    logic [31:0] bram_fetch_addr;
    logic [31:0] bram_fetch_read;

    bram bram0 (
        .clk(sys_clk),
        .we(bram_we),
        .addr(bram_addr),
        .write(bram_write),
        .read(bram_read),
        .fetch_addr(bram_fetch_addr),
        .fetch_read(bram_fetch_read)
    );

    logic sdrc_cmd_en;
    logic [2:0] sdrc_cmd;
    logic [20:0] sdrc_addr;
    logic [3:0] sdrc_dqm;
    logic [31:0] sdrc_data_w;
    logic [31:0] sdrc_data_r;
    logic sdrc_init_done;
    logic sdrc_cmd_ack;

    SDRAM_Controller_HS_Top sdrc0 (
        .O_sdram_clk(O_sdram_clk),
        .O_sdram_cke(O_sdram_cke),
        .O_sdram_cs_n(O_sdram_cs_n),
        .O_sdram_cas_n(O_sdram_cas_n),
        .O_sdram_ras_n(O_sdram_ras_n),
        .O_sdram_wen_n(O_sdram_wen_n),
        .O_sdram_dqm(O_sdram_dqm),
        .O_sdram_addr(O_sdram_addr),
        .O_sdram_ba(O_sdram_ba),
        .IO_sdram_dq(IO_sdram_dq),

        .I_sdrc_rst_n(~rst_reg),
        .I_sdrc_clk(sys_clk),
        .I_sdram_clk(sdram_clk),
        .I_sdrc_cmd_en(sdrc_cmd_en),
        .I_sdrc_cmd(sdrc_cmd),
        .I_sdrc_precharge_ctrl(1'b1),
        .I_sdram_power_down(1'b0),
        .I_sdram_selfrefresh(1'b0),
        .I_sdrc_addr(sdrc_addr),
        .I_sdrc_dqm(sdrc_dqm),
        .I_sdrc_data(sdrc_data_w),
        .I_sdrc_data_len(8'd0),
        .O_sdrc_data(sdrc_data_r), 
        .O_sdrc_init_done(sdrc_init_done),
        .O_sdrc_cmd_ack(sdrc_cmd_ack)
    );

    video video0 (
        .clk(clk),
        .cpu_clk(sys_clk),
        .rst(rst_reg),
        .text_write(video_write),
        .text_address(video_address),
        .text_data(video_data),
        .cursor(video_cursor),
        .scroll(video_scroll),
        .tmds_clk_p(tmds_clk_p),
        .tmds_clk_n(tmds_clk_n),
        .tmds_d_p(tmds_d_p),
        .tmds_d_n(tmds_d_n)
    );

    logic flash_req;
    logic [23:0] flash_addr;
    logic [31:0] flash_rdata;
    logic flash_ready;

    flash flash0 (
        .clk(sys_clk),
        .rst(rst_reg),
        .flash_req(flash_req),
        .flash_addr(flash_addr),
        .flash_rdata(flash_rdata),
        .flash_ready(flash_ready),
        .raw_enable(flash_raw_enable),
        .raw_start(flash_raw_start),
        .raw_tx(flash_raw_tx),
        .raw_rx(flash_raw_rx),
        .raw_busy(flash_raw_busy),
        .flash_cs(spi_cs_pin),
        .flash_sck(spi_clk_pin),
        .flash_mosi(spi_mosi_pin),
        .flash_miso(spi_miso_pin)
    );

    logic sdram_start;
    logic sdram_write;
    logic [20:0] sdram_address;
    logic [31:0] sdram_data;
    logic [3:0] sdram_dqm;
    logic sdram_ready;
    logic sdram_valid;
    logic [31:0] sdram_read_data;
    logic sdram_write_done;
    logic [20:0] sdram_active_address;
    logic [31:0] sdram_active_data;
    logic [3:0] sdram_active_dqm;
    logic store_check;

    logic icache_request;
    logic [10:0] icache_tag;
    logic icache_lookup;
    logic [31:0] icache_read;
    logic icache_fill_request;
    logic icache_clearing;
    logic icache_grant;
    logic icache_start;
    logic [20:0] icache_address;
    logic icache_word;
    logic icache_done;

    logic dcache_request;
    logic [10:0] dcache_tag;
    logic dcache_lookup;
    logic [31:0] dcache_read;
    logic dcache_fill_request;
    logic dcache_clearing;
    logic dcache_grant;
    logic dcache_start;
    logic [20:0] dcache_address;
    logic dcache_word;
    logic dcache_done;

    logic [10:0] mmu_fetch_frame;
    logic mmu_fetch_translated;
    logic mmu_fetch_fault;
    logic mmu_fetch_request;
    logic [10:0] mmu_data_frame;
    logic mmu_data_request;
    logic mmu_data_denied;
    logic mmu_grant_data;
    logic mmu_grant_fetch;
    logic mmu_start;
    logic [20:0] mmu_address;
    logic mmu_walk_done;
    logic mmu_walk_resolved;
    logic mmu_walk_failed;
    logic [10:0] mmu_walk_frame;

    mmu mmu0 (
        .clk(sys_clk),
        .rst(rst_reg),
        .stall(cpu_stall),

        .user_mode(cpu_user_mode),
        .ptbase(cpu_ptbase),
        .asid(cpu_asid),
        .flush(cpu_tlb_flush),

        .fetch_address(cpu_fetch_addr),
        .fetch_next(cpu_fetch_next),
        .fetch_current(cpu_fetch_current),
        .fetch_repeat(cpu_fetch_repeat),
        .fetch_lookup(icache_lookup),
        .fetch_frame(mmu_fetch_frame),
        .fetch_translated(mmu_fetch_translated),
        .fetch_fault(mmu_fetch_fault),
        .fetch_request(mmu_fetch_request),

        .ex_address(cpu_ex_addr),
        .data_address(cpu_mem_addr),
        .data_access(cpu_mem_access),
        .data_write(cpu_mem_we != 4'b0000),
        .data_frame(mmu_data_frame),
        .data_request(mmu_data_request),
        .data_denied(mmu_data_denied),
        .data_fault(cpu_data_fault),

        .grant_data(mmu_grant_data),
        .grant_fetch(mmu_grant_fetch),
        .sdram_ready(sdram_ready),
        .sdram_valid(sdram_valid),
        .sdram_data(sdram_read_data),
        .sdram_start(mmu_start),
        .sdram_address(mmu_address),
        .walk_done(mmu_walk_done),
        .walk_resolved(mmu_walk_resolved),
        .walk_failed(mmu_walk_failed),
        .walk_frame(mmu_walk_frame)
    );

    icache icache0 (
        .clk(sys_clk),
        .rst(rst_reg),

        .capture(!cpu_stall),
        .request(icache_request),
        .address(cpu_fetch_addr),
        .tag(icache_tag),
        .translated(mmu_fetch_translated),
        .lookup(icache_lookup),
        .read_data(icache_read),
        .fill_request(icache_fill_request),
        .clearing(icache_clearing),

        .flush(cpu_tlb_flush && cpu_cache_flush),
        .invalidate(store_check),
        .invalidate_address(sdram_active_address),
        .retag(mmu_walk_resolved),
        .new_tag(mmu_walk_frame),

        .grant(icache_grant),
        .sdram_ready(sdram_ready),
        .sdram_valid(sdram_valid),
        .sdram_data(sdram_read_data),
        .sdram_start(icache_start),
        .sdram_address(icache_address),
        .word_valid(icache_word),
        .fill_done(icache_done)
    );

    dcache dcache0 (
        .clk(sys_clk),
        .rst(rst_reg),

        .capture(!cpu_stall),
        .request(dcache_request),
        .address(cpu_mem_addr),
        .tag(dcache_tag),
        .lookup(dcache_lookup),
        .read_data(dcache_read),
        .fill_request(dcache_fill_request),
        .clearing(dcache_clearing),

        .flush(cpu_tlb_flush && cpu_cache_flush),
        .store(store_check),
        .store_address(sdram_active_address),
        .store_data(sdram_active_data),
        .store_dqm(sdram_active_dqm),

        .grant(dcache_grant),
        .sdram_ready(sdram_ready),
        .sdram_valid(sdram_valid),
        .sdram_data(sdram_read_data),
        .sdram_start(dcache_start),
        .sdram_address(dcache_address),
        .word_valid(dcache_word),
        .fill_done(dcache_done)
    );

    sdram #(
        .CLK_FREQ(CLK_FREQ)
    ) sdram0 (
        .clk(sys_clk),
        .rst(rst_reg),

        .start(sdram_start),
        .write(sdram_write),
        .address(sdram_address),
        .data(sdram_data),
        .dqm(sdram_dqm),
        .ready(sdram_ready),
        .read_valid(sdram_valid),
        .read_data(sdram_read_data),
        .write_done(sdram_write_done),
        .active_address(sdram_active_address),
        .active_data(sdram_active_data),
        .active_dqm(sdram_active_dqm),

        .sdrc_cmd_en(sdrc_cmd_en),
        .sdrc_cmd(sdrc_cmd),
        .sdrc_addr(sdrc_addr),
        .sdrc_data_w(sdrc_data_w),
        .sdrc_dqm(sdrc_dqm),
        .sdrc_data_r(sdrc_data_r),
        .sdrc_init_done(sdrc_init_done),
        .sdrc_cmd_ack(sdrc_cmd_ack)
    );

    bus bus0 (
        .clk(sys_clk),
        .rst(rst_reg),

        .cpu_fetch_addr(cpu_fetch_addr),
        .cpu_fetch_read(cpu_fetch_read),
        .cpu_fetch_fault(cpu_fetch_fault),

        .cpu_mem_access(cpu_mem_access),
        .cpu_mem_we(cpu_mem_we),
        .cpu_mem_addr(cpu_mem_addr),
        .cpu_mem_write(cpu_mem_write),
        .cpu_mem_read(cpu_mem_read),
        .cpu_stall(cpu_stall),

        .cpu_user_mode(cpu_user_mode),

        .bram_we(bram_we),
        .bram_addr(bram_addr),
        .bram_write(bram_write),
        .bram_read(bram_read),
        .bram_fetch_addr(bram_fetch_addr),
        .bram_fetch_read(bram_fetch_read),

        .flash_req(flash_req),
        .flash_addr(flash_addr),
        .flash_rdata(flash_rdata),
        .flash_ready(flash_ready),

        .sdram_start(sdram_start),
        .sdram_write(sdram_write),
        .sdram_address(sdram_address),
        .sdram_data(sdram_data),
        .sdram_dqm(sdram_dqm),
        .sdram_ready(sdram_ready),
        .sdram_write_done(sdram_write_done),
        .sdram_read_data(sdram_read_data),
        .store_check(store_check),

        .icache_request(icache_request),
        .icache_tag(icache_tag),
        .icache_lookup(icache_lookup),
        .icache_read(icache_read),
        .icache_fill_request(icache_fill_request),
        .icache_clearing(icache_clearing),
        .icache_grant(icache_grant),
        .icache_start(icache_start),
        .icache_address(icache_address),
        .icache_word(icache_word),
        .icache_done(icache_done),

        .dcache_request(dcache_request),
        .dcache_tag(dcache_tag),
        .dcache_lookup(dcache_lookup),
        .dcache_read(dcache_read),
        .dcache_fill_request(dcache_fill_request),
        .dcache_clearing(dcache_clearing),
        .dcache_grant(dcache_grant),
        .dcache_start(dcache_start),
        .dcache_address(dcache_address),
        .dcache_word(dcache_word),
        .dcache_done(dcache_done),

        .mmu_fetch_frame(mmu_fetch_frame),
        .mmu_fetch_fault(mmu_fetch_fault),
        .mmu_fetch_request(mmu_fetch_request),
        .mmu_data_frame(mmu_data_frame),
        .mmu_data_request(mmu_data_request),
        .mmu_data_denied(mmu_data_denied),
        .mmu_grant_data(mmu_grant_data),
        .mmu_grant_fetch(mmu_grant_fetch),
        .mmu_start(mmu_start),
        .mmu_address(mmu_address),
        .mmu_walk_done(mmu_walk_done),
        .mmu_walk_failed(mmu_walk_failed)
    );
endmodule
