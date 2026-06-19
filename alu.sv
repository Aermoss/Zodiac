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
    output logic [31:0] result
);

always_comb begin
    case (alu_op)
        ALU_OP_ADD: result = left + right;
        ALU_OP_SUB: result = left - right;
        ALU_OP_AND: result = left & right;
        ALU_OP_OR: result = left | right;
        ALU_OP_XOR: result = left ^ right;
        ALU_OP_NOT: result = ~left;
        ALU_OP_SHL: result = left << right;
        ALU_OP_SHR: result = left >> right;
    endcase
end

endmodule