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

module divider (
    input logic clk,
    input logic rst,
    input logic start,
    input logic [31:0] dividend,
    input logic [31:0] divisor,
    output logic [31:0] quotient,
    output logic [31:0] remainder,
    output logic ready
);
    logic [31:0] Q;
    logic [31:0] R;
    logic [31:0] D;
    logic [5:0] count;
    logic busy;

    assign quotient = Q;
    assign remainder = R;
    assign ready = !busy && (count == 0) && !start;

    logic [32:0] sub_res;

    assign sub_res = {1'b0, R[30:0], Q[31]} - {1'b0, D};

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            Q <= 32'b0;
            R <= 32'b0;
            D <= 32'b0;
            count <= 6'b0;
            busy <= 1'b0;
        end else begin
            if (start && !busy) begin
                Q <= dividend;
                R <= 32'b0;
                D <= divisor;
                count <= 6'd32;
                busy <= 1'b1;
            end else if (busy) begin
                if (count > 0) begin
                    count <= count - 6'd1;

                    if (sub_res[32]) begin
                        R <= {R[30:0], Q[31]};
                        Q <= {Q[30:0], 1'b0};
                    end else begin
                        R <= sub_res[31:0];
                        Q <= {Q[30:0], 1'b1};
                    end
                end else begin
                    busy <= 1'b0;
                end
            end
        end
    end
endmodule
