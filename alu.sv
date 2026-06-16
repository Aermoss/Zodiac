typedef enum logic [1:0] {
    ALU_OP_INC,
    ALU_OP_DEC,
    ALU_OP_ADD,
    ALU_OP_SUB
} alu_op_t;

module alu(
    input logic [7:0] left,
    input logic [7:0] right,
    input alu_op_t alu_op,
    output logic [7:0] result,
    output logic zero,
    output logic carry
);

logic [8:0] temp;

always_comb begin
    temp = 9'b0;

    case (alu_op)
        ALU_OP_INC: temp = left + 1;
        ALU_OP_DEC: temp = left - 1;
        ALU_OP_ADD: temp = left + right;
        ALU_OP_SUB: temp = left - right;
    endcase
end

assign result = temp[7:0];
assign zero = (temp[7:0] == 8'b0);
assign carry = temp[8];

endmodule