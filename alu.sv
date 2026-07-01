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
    ALU_OP_AND,
    ALU_OP_OR,
    ALU_OP_XOR,
    ALU_OP_SLL,
    ALU_OP_SRL,
    ALU_OP_SRA
} alu_op_t;

module alu(
    input logic [31:0] left,
    input logic [31:0] right,
    input alu_op_t alu_op,
    output logic [31:0] result
);
    logic signed [63:0] ss_prod;
    logic signed [63:0] su_prod;
    logic [63:0] uu_prod;

    assign ss_prod = $signed(left) * $signed(right);
    assign su_prod = $signed({left[31], left}) * $signed({1'b0, right});
    assign uu_prod = left * right;

    always_comb begin
        result = 0;

        case (alu_op)
            ALU_OP_ADD: result = left + right;
            ALU_OP_SUB: result = left - right;
            ALU_OP_MUL: result = ss_prod[31:0];
            ALU_OP_MULH: result = ss_prod[63:32];
            ALU_OP_MULHSU: result = su_prod[63:32];
            ALU_OP_MULHU: result = uu_prod[63:32];
            ALU_OP_AND: result = left & right;
            ALU_OP_OR: result = left | right;
            ALU_OP_XOR: result = left ^ right;
            ALU_OP_SLL: result = left << right[4:0];
            ALU_OP_SRL: result = left >> right[4:0];
            ALU_OP_SRA: result = $signed(left) >>> right[4:0]; 
        endcase
    end
endmodule
