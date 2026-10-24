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

module video (
    input logic clk,
    input logic cpu_clk,
    input logic rst,

    input logic text_write,
    input logic [11:0] text_address,
    input logic [15:0] text_data,
    input logic [15:0] cursor,
    input logic [4:0] scroll,

    output logic tmds_clk_p,
    output logic tmds_clk_n,
    output logic [2:0] tmds_d_p,
    output logic [2:0] tmds_d_n
);
    localparam int COLUMNS = 80;
    localparam int ROWS = 30;

    localparam int H_VISIBLE = 640;
    localparam int H_SYNC_START = 656;
    localparam int H_SYNC_END = 752;
    localparam int H_TOTAL = 800;
    localparam int V_VISIBLE = 480;
    localparam int V_SYNC_START = 490;
    localparam int V_SYNC_END = 492;
    localparam int V_TOTAL = 525;

    logic serial_clk;
    logic pixel_clk;
    logic pll_lock;
    logic video_rst;

    Gowin_rPLL_video pll (
        .clkout(serial_clk),
        .lock(pll_lock),
        .clkin(clk)
    );

    CLKDIV #(
        .DIV_MODE("5"),
        .GSREN("false")
    ) divider (
        .RESETN(pll_lock),
        .HCLKIN(serial_clk),
        .CLKOUT(pixel_clk),
        .CALIB(1'b1)
    );

    logic [1:0] reset_sync;

    always_ff @(posedge pixel_clk or negedge pll_lock) begin
        if (!pll_lock)
            reset_sync <= 2'b11;
        else
            reset_sync <= {reset_sync[0], rst};
    end

    assign video_rst = reset_sync[1];

    logic [15:0] text [0:COLUMNS * ROWS - 1];
    logic [7:0] font [0:4095];

    initial begin
        $readmemh("C:\\Users\\rencb\\Documents\\GitHub\\Zodiac\\font.hex", font);
    end

    always_ff @(posedge cpu_clk) begin
        if (text_write && text_address < 12'(COLUMNS * ROWS))
            text[text_address] <= text_data;
    end

    logic [15:0] cursor_sync0, cursor_sync1;
    logic [4:0] scroll_sync0, scroll_sync1;

    always_ff @(posedge pixel_clk) begin
        cursor_sync0 <= cursor;
        cursor_sync1 <= cursor_sync0;
        scroll_sync0 <= scroll;
        scroll_sync1 <= scroll_sync0;
    end

    logic [9:0] h;
    logic [9:0] v;
    logic [5:0] frame;

    always_ff @(posedge pixel_clk or posedge video_rst) begin
        if (video_rst) begin
            h <= 0;
            v <= 0;
            frame <= 0;
        end else if (h == 10'(H_TOTAL - 1)) begin
            h <= 0;

            if (v == 10'(V_TOTAL - 1)) begin
                v <= 0;
                frame <= frame + 6'd1;
            end else begin
                v <= v + 10'd1;
            end
        end else begin
            h <= h + 10'd1;
        end
    end

    logic [4:0] row;
    logic [5:0] row_sum;
    logic [4:0] shown_row;
    logic [6:0] column;

    assign row = v[8:4];
    assign column = h[9:3];
    assign row_sum = {1'b0, row} + {1'b0, scroll_sync1};
    assign shown_row = 5'(row_sum >= 6'(ROWS) ? row_sum - 6'(ROWS) : row_sum);

    logic [15:0] cell_word;
    logic [7:0] glyph_row;
    logic [2:0] pixel1, pixel2;
    logic [3:0] line1;
    logic active1, active2, active3;
    logic hsync1, hsync2, hsync3;
    logic vsync1, vsync2, vsync3;
    logic cursor1, cursor2;
    logic [7:0] colors2;

    always_ff @(posedge pixel_clk) begin
        cell_word <= text[{7'b0, shown_row} * 12'(COLUMNS) + {5'b0, column}];
        pixel1 <= h[2:0];
        line1 <= v[3:0];
        active1 <= h < 10'(H_VISIBLE) && v < 10'(V_VISIBLE);
        hsync1 <= !(h >= 10'(H_SYNC_START) && h < 10'(H_SYNC_END));
        vsync1 <= !(v >= 10'(V_SYNC_START) && v < 10'(V_SYNC_END));
        cursor1 <= cursor_sync1[15] && column == cursor_sync1[6:0] && row == cursor_sync1[12:8] && frame[5];

        glyph_row <= font[{cell_word[7:0], line1}];
        colors2 <= cell_word[15:8];
        pixel2 <= pixel1;
        active2 <= active1;
        hsync2 <= hsync1;
        vsync2 <= vsync1;
        cursor2 <= cursor1 && line1 >= 4'd14;

        active3 <= active2;
        hsync3 <= hsync2;
        vsync3 <= vsync2;
    end

    function automatic logic [23:0] palette(input logic [3:0] color);
        case (color)
            4'h0: palette = 24'h000000;
            4'h1: palette = 24'h0000AA;
            4'h2: palette = 24'h00AA00;
            4'h3: palette = 24'h00AAAA;
            4'h4: palette = 24'hAA0000;
            4'h5: palette = 24'hAA00AA;
            4'h6: palette = 24'hAA5500;
            4'h7: palette = 24'hAAAAAA;
            4'h8: palette = 24'h555555;
            4'h9: palette = 24'h5555FF;
            4'hA: palette = 24'h55FF55;
            4'hB: palette = 24'h55FFFF;
            4'hC: palette = 24'hFF5555;
            4'hD: palette = 24'hFF55FF;
            4'hE: palette = 24'hFFFF55;
            default: palette = 24'hFFFFFF;
        endcase
    endfunction

    logic [23:0] rgb;

    always_ff @(posedge pixel_clk) begin
        rgb <= palette((glyph_row[3'd7 - pixel2] || cursor2) ? colors2[3:0] : colors2[7:4]);
    end

    logic [9:0] symbol_red, symbol_green, symbol_blue;

    tmds_encoder encoder_blue (.clk(pixel_clk), .rst(video_rst), .data(rgb[7:0]), .control({vsync3, hsync3}), .active(active3), .symbol(symbol_blue));
    tmds_encoder encoder_green (.clk(pixel_clk), .rst(video_rst), .data(rgb[15:8]), .control(2'b00), .active(active3), .symbol(symbol_green));
    tmds_encoder encoder_red (.clk(pixel_clk), .rst(video_rst), .data(rgb[23:16]), .control(2'b00), .active(active3), .symbol(symbol_red));

    logic [9:0] symbols [0:3];
    logic [3:0] serial;

    assign symbols[0] = symbol_blue;
    assign symbols[1] = symbol_green;
    assign symbols[2] = symbol_red;
    assign symbols[3] = 10'b1111100000;

    generate
        for (genvar i = 0; i < 4; i++) begin : channels
            OSER10 #(
                .GSREN("false"),
                .LSREN("true")
            ) serializer (
                .Q(serial[i]),
                .D0(symbols[i][0]),
                .D1(symbols[i][1]),
                .D2(symbols[i][2]),
                .D3(symbols[i][3]),
                .D4(symbols[i][4]),
                .D5(symbols[i][5]),
                .D6(symbols[i][6]),
                .D7(symbols[i][7]),
                .D8(symbols[i][8]),
                .D9(symbols[i][9]),
                .PCLK(pixel_clk),
                .FCLK(serial_clk),
                .RESET(!pll_lock)
            );
        end
    endgenerate

    ELVDS_OBUF buffer_blue (.I(serial[0]), .O(tmds_d_p[0]), .OB(tmds_d_n[0]));
    ELVDS_OBUF buffer_green (.I(serial[1]), .O(tmds_d_p[1]), .OB(tmds_d_n[1]));
    ELVDS_OBUF buffer_red (.I(serial[2]), .O(tmds_d_p[2]), .OB(tmds_d_n[2]));
    ELVDS_OBUF buffer_clock (.I(serial[3]), .O(tmds_clk_p), .OB(tmds_clk_n));
endmodule
