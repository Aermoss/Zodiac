typedef enum logic [2:0] {
    ALU_OP_ADD,
    ALU_OP_SUB,
    ALU_OP_AND,
    ALU_OP_OR,
    ALU_OP_XOR,
    ALU_OP_NOT,
    ALU_OP_SHL,
    ALU_OP_SHR
} alu_op_t;

module alu(
    input logic [31:0] left,
    input logic [31:0] right,
    input alu_op_t alu_op,
    output logic [31:0] result,
    output logic zero,
    output logic carry
);

logic [32:0] temp;

always_comb begin
    case (alu_op)
        ALU_OP_ADD: temp = left + right;
        ALU_OP_SUB: temp = left - right;
        ALU_OP_AND: temp = left & right;
        ALU_OP_OR: temp = left | right;
        ALU_OP_XOR: temp = left ^ right;
        ALU_OP_NOT: temp = ~left;
        ALU_OP_SHL: temp = left << right;
        ALU_OP_SHR: temp = left >> right;
        default: temp = 0;
    endcase
end

assign result = temp[31:0];
assign zero = (temp[31:0] == 0);
assign carry = temp[32];

endmodule