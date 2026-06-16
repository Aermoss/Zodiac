module cpu(
    input logic clk,
    input logic reset
);

typedef enum logic [7:0] {
    OP_NOP,
    OP_LDI,
    OP_LD,
    OP_ST,
    OP_CMP,
    OP_J,
    OP_JZ,
    OP_JNZ,
    OP_JC,
    OP_JNC,
    OP_ADD,
    OP_SUB,
    OP_AND,
    OP_OR,
    OP_XOR,
    OP_NOT,
    OP_SHL,
    OP_SHR,
    OP_HLT = 8'hFF
} opcode_t;

typedef enum logic [2:0] {
    S_FETCH,
    S_DECODE,
    S_FETCH_OPERAND,
    S_EXECUTE,
    S_WRITEBACK
} state_t;

logic halted;
logic [31:0] pc;
state_t state;

logic [31:0] instr;
logic [31:0] regs [0:31];

opcode_t opcode;
logic [4:0] rd;
logic [4:0] rs1;
logic [4:0] rs2;
logic [8:0] imm9;
logic [13:0] imm14;
logic [18:0] imm19;
logic [23:0] imm24;

assign opcode = opcode_t'(instr[31:24]);
assign rd = instr[23:19];
assign rs1 = instr[18:14];
assign rs2 = instr[13:9];
assign imm9 = instr[8:0];
assign imm14 = instr[13:0];
assign imm19 = instr[18:0];
assign imm24 = instr[23:0];

logic ram_we;
logic [31:0] ram_addr;
logic [31:0] ram_write;
logic [31:0] ram_read;

ram ram0(
    .clk(clk),
    .we(ram_we),
    .addr(ram_addr),
    .write(ram_write),
    .read(ram_read)
);

logic [31:0] alu_left;
logic [31:0] alu_right;
alu_op_t alu_op;
logic [31:0] alu_result;
logic alu_zero;
logic alu_carry;

alu alu0(
    .left(alu_left),
    .right(alu_right),
    .alu_op(alu_op),
    .result(alu_result),
    .zero(alu_zero),
    .carry(alu_carry)
);

always @(posedge clk) begin
    if (reset) begin
        halted <= 0;
        state <= S_FETCH;
        pc <= 0;

        instr <= 0;

        ram_we <= 0;
        ram_addr <= 0;
        ram_write <= 0;

        alu_left <= 0;
        alu_op <= ALU_OP_ADD;
        alu_right <= 0;
    end

    else if (!halted) begin
        case (state)
            S_FETCH: begin
                ram_addr <= pc;
                state <= S_DECODE;
            end

            S_DECODE: begin
                instr <= ram_read;

                case (opcode_t'(ram_read[31:24]))
                    OP_LD: begin
                        ram_addr <= imm19;
                    end

                    OP_ST: begin
                        ram_we <= 1;
                        ram_addr <= imm19;
                        ram_write <= rd;
                    end
                endcase

                state <= S_EXECUTE;
            end

            S_EXECUTE: begin
                case (opcode)
                    OP_LDI: begin
                        regs[rd] = imm19;
                        state <= S_FETCH;
                        pc <= pc + 1;
                    end

                    OP_LD: begin
                        regs[rd] <= ram_read;
                        state <= S_FETCH;
                        pc <= pc + 1;
                    end

                    OP_ST: begin
                        ram_we <= 0;
                        state <= S_FETCH;
                        pc <= pc + 1;
                    end

                    OP_CMP: begin
                        alu_op <= ALU_OP_SUB;
                        alu_left <= regs[rd];
                        alu_right <= regs[rs1];
                        state <= S_FETCH;
                        pc <= pc + 1;
                    end

                    OP_J: begin
                        state <= S_FETCH;
                        pc <= imm24;
                    end

                    OP_JZ, OP_JNZ, OP_JC, OP_JNC: begin
                        state <= S_FETCH;

                        case (opcode)
                            OP_JZ: pc <= alu_zero ? imm24 : pc + 1;
                            OP_JNZ: pc <= !alu_zero ? imm24 : pc + 1;
                            OP_JC: pc <= alu_carry ? imm24 : pc + 1;
                            OP_JNC: pc <= !alu_carry ? imm24 : pc + 1;
                        endcase
                    end

                    OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR, OP_SHL, OP_SHR: begin
                        case (opcode)
                            OP_ADD: alu_op <= ALU_OP_ADD;
                            OP_SUB: alu_op <= ALU_OP_SUB;
                            OP_AND: alu_op <= ALU_OP_AND;
                            OP_OR: alu_op <= ALU_OP_OR;
                            OP_XOR: alu_op <= ALU_OP_XOR;
                            OP_SHL: alu_op <= ALU_OP_SHL;
                            OP_SHR: alu_op <= ALU_OP_SHR;
                        endcase

                        alu_left <= regs[rs1];
                        alu_right <= regs[rs2];
                        state <= S_WRITEBACK;
                        pc <= pc + 1;
                    end

                    OP_NOT: begin
                        alu_op <= ALU_OP_NOT;
                        alu_left <= regs[rs1];
                        state <= S_WRITEBACK;
                        pc <= pc + 1;
                    end

                    OP_HLT: begin
                        halted <= 1;
                    end
                endcase
            end

            S_WRITEBACK: begin
                regs[rd] <= alu_result;
                state <= S_FETCH;
            end
        endcase
    end
end

endmodule