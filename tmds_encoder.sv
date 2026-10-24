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

module tmds_encoder (
    input logic clk,
    input logic rst,
    input logic [7:0] data,
    input logic [1:0] control,
    input logic active,
    output logic [9:0] symbol
);
    logic [3:0] data_ones;
    logic use_xnor;
    logic [8:0] q_m;
    logic [3:0] q_m_ones;
    logic signed [4:0] q_m_balance;
    logic signed [5:0] disparity;

    always_comb begin
        data_ones = 0;

        for (int i = 0; i < 8; i++)
            data_ones = data_ones + {3'b0, data[i]};

        use_xnor = data_ones > 4 || (data_ones == 4 && !data[0]);
        q_m[0] = data[0];

        for (int i = 1; i < 8; i++)
            q_m[i] = use_xnor ? ~(q_m[i - 1] ^ data[i]) : q_m[i - 1] ^ data[i];

        q_m[8] = !use_xnor;
        q_m_ones = 0;

        for (int i = 0; i < 8; i++)
            q_m_ones = q_m_ones + {3'b0, q_m[i]};

        q_m_balance = $signed({1'b0, q_m_ones, 1'b0}) - 5'sd8;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            symbol <= 10'b1101010100;
            disparity <= 0;
        end else if (!active) begin
            disparity <= 0;

            case (control)
                2'b00: symbol <= 10'b1101010100;
                2'b01: symbol <= 10'b0010101011;
                2'b10: symbol <= 10'b0101010100;
                default: symbol <= 10'b1010101011;
            endcase
        end else if (disparity == 0 || q_m_balance == 0) begin
            symbol <= {~q_m[8], q_m[8], q_m[8] ? q_m[7:0] : ~q_m[7:0]};
            disparity <= q_m[8] ? disparity + 6'(q_m_balance) : disparity - 6'(q_m_balance);
        end else if ((disparity > 0 && q_m_balance > 0) || (disparity < 0 && q_m_balance < 0)) begin
            symbol <= {1'b1, q_m[8], ~q_m[7:0]};
            disparity <= disparity + (q_m[8] ? 6'sd2 : 6'sd0) - 6'(q_m_balance);
        end else begin
            symbol <= {1'b0, q_m[8], q_m[7:0]};
            disparity <= disparity - (q_m[8] ? 6'sd0 : 6'sd2) + 6'(q_m_balance);
        end
    end
endmodule
