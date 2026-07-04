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

typedef enum logic [3:0] {
    ALU_OP_ADD,
    ALU_OP_SUB,
    ALU_OP_MUL,
    ALU_OP_MULH,
    ALU_OP_MULHSU,
    ALU_OP_MULHU,
    ALU_OP_DIV,
    ALU_OP_DIVU,
    ALU_OP_REM,
    ALU_OP_REMU,
    ALU_OP_AND,
    ALU_OP_OR,
    ALU_OP_XOR,
    ALU_OP_SLL,
    ALU_OP_SRL,
    ALU_OP_SRA
} alu_op_t;

module alu(
    input logic clk,
    input logic rst,
    input logic [31:0] left,
    input logic [31:0] right,
    input alu_op_t alu_op,
    input logic start,
    output logic [31:0] result,
    output logic ready
);
    logic signed [63:0] ss_prod;
    logic signed [63:0] su_prod;
    logic [63:0] uu_prod;

    assign ss_prod = $signed(left) * $signed(right);
    assign su_prod = $signed({left[31], left}) * $signed({1'b0, right});
    assign uu_prod = left * right;

    logic is_div_op;
    assign is_div_op = (alu_op == ALU_OP_DIV) || (alu_op == ALU_OP_DIVU) || (alu_op == ALU_OP_REM) || (alu_op == ALU_OP_REMU);

    logic [31:0] div_dividend, div_divisor;
    assign div_dividend = (alu_op == ALU_OP_DIV || alu_op == ALU_OP_REM) && left[31] ? -left : left;
    assign div_divisor = (alu_op == ALU_OP_DIV || alu_op == ALU_OP_REM) && right[31] ? -right : right;

    logic [5:0] count;
    logic [31:0] Q, R, D;
    logic busy;

    logic [32:0] sub_res;
    assign sub_res = {1'b0, R[30:0], Q[31]} - {1'b0, D};

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
            Q <= 0;
            R <= 0;
            D <= 0;
            busy <= 0;
        end else begin
            if (start && is_div_op && !busy) begin
                count <= 32;
                Q <= div_dividend;
                R <= 0;
                D <= div_divisor;
                busy <= 1;
            end else if (busy) begin
                if (count > 0) begin
                    count <= count - 1;

                    if (sub_res[32]) begin
                        R <= {R[30:0], Q[31]};
                        Q <= {Q[30:0], 1'b0};
                    end else begin
                        R <= sub_res[31:0];
                        Q <= {Q[30:0], 1'b1};
                    end
                end else begin
                    busy <= 0;
                end
            end
        end
    end

    logic div_sign_q, div_sign_r;
    logic [31:0] div_orig_dividend, div_orig_divisor;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            div_sign_q <= 0;
            div_sign_r <= 0;
            div_orig_dividend <= 0;
            div_orig_divisor <= 0;
        end else if (start && is_div_op) begin
            div_sign_q <= (alu_op == ALU_OP_DIV) && (left[31] ^ right[31]) && (right != 0);
            div_sign_r <= (alu_op == ALU_OP_REM) && left[31] && (right != 0);
            div_orig_dividend <= left;
            div_orig_divisor <= right;
        end
    end

    logic [31:0] final_quotient, final_remainder;
    assign final_quotient = (div_orig_divisor == 0) ? 32'hFFFFFFFF : (div_sign_q ? -Q : Q);
    assign final_remainder = (div_orig_divisor == 0) ? div_orig_dividend : (div_sign_r ? -R : R);
    assign ready = is_div_op ? (!busy && (count == 0) && !start) : 1'b1;

    always_comb begin
        result = 0;

        case (alu_op)
            ALU_OP_ADD: result = left + right;
            ALU_OP_SUB: result = left - right;
            ALU_OP_MUL: result = ss_prod[31:0];
            ALU_OP_MULH: result = ss_prod[63:32];
            ALU_OP_MULHSU: result = su_prod[63:32];
            ALU_OP_MULHU: result = uu_prod[63:32];
            ALU_OP_DIV, ALU_OP_DIVU: result = final_quotient;
            ALU_OP_REM, ALU_OP_REMU: result = final_remainder;
            ALU_OP_AND: result = left & right;
            ALU_OP_OR: result = left | right;
            ALU_OP_XOR: result = left ^ right;
            ALU_OP_SLL: result = left << right[4:0];
            ALU_OP_SRL: result = left >> right[4:0];
            ALU_OP_SRA: result = $signed(left) >>> right[4:0];
        endcase
    end
endmodule
