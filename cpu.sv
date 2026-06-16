module cpu(
    input logic clk,
    input logic reset
);

typedef enum logic [7:0] {
    OP_NOP,
    OP_LD,
    OP_LDI,
    OP_ST,
    OP_CMP,
    OP_CMPI,
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
    OP_ADDI,
    OP_SUBI,
    OP_ANDI,
    OP_ORI,
    OP_XORI,
    OP_NOTI,
    OP_SHLI,
    OP_SHRI,
    OP_HLT = 8'hFF
} opcode_t;

typedef enum logic [1:0] {
    S_FETCH,
    S_DECODE,
    S_EXECUTE,
    S_WRITEBACK
} state_t;

logic halted;
logic [31:0] pc;
state_t state;

logic [31:0] instr;
logic [31:0] regs [0:31];
integer i;

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

always_ff @(posedge clk) begin
    if (reset) begin
        instr <= 0;

        for (i = 0; i < 32; i++)
            regs[i] <= 0;

        halted <= 0;
        state <= S_FETCH;
        pc <= 0;

        ram_addr <= 0;
        ram_write <= 0;
        ram_we <= 0;

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
                    OP_LD: ram_addr <= ram_read[18:0];

                    OP_ST: begin
                        ram_addr <= ram_read[18:0];
                        ram_write <= regs[instr[23:19]];
                        ram_we <= 1;
                    end
                endcase

                state <= S_EXECUTE;
            end

            S_EXECUTE: begin
                if (opcode != OP_HLT) begin
                    state <= S_FETCH;
                    pc <= pc + 1;
                end

                case (opcode)
                    OP_HLT: halted <= 1;
                    OP_LD, OP_LDI: regs[rd] <= (opcode > OP_LD) ? imm19 : ram_read;
                    OP_ST: ram_we <= 0;

                    OP_CMP, OP_CMPI: begin
                        alu_left <= regs[rd];
                        alu_right <= (opcode > OP_CMP) ? imm19 : regs[rs1];
                        alu_op <= ALU_OP_SUB;
                    end

                    OP_J: pc <= imm24;
                    OP_JZ: if (alu_zero) pc <= imm24;
                    OP_JNZ: if (!alu_zero) pc <= imm24;
                    OP_JC: if (alu_carry) pc <= imm24;
                    OP_JNC: if (!alu_carry) pc <= imm24;

                    OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR, OP_SHL, OP_SHR,
                    OP_ADDI, OP_SUBI, OP_ANDI, OP_ORI, OP_XORI, OP_SHLI, OP_SHRI: begin
                        case (opcode)
                            OP_ADD, OP_ADDI: alu_op <= ALU_OP_ADD;
                            OP_SUB, OP_SUBI: alu_op <= ALU_OP_SUB;
                            OP_AND, OP_ANDI: alu_op <= ALU_OP_AND;
                            OP_OR, OP_ORI: alu_op <= ALU_OP_OR;
                            OP_XOR, OP_XORI: alu_op <= ALU_OP_XOR;
                            OP_SHL, OP_SHLI: alu_op <= ALU_OP_SHL;
                            OP_SHR, OP_SHRI: alu_op <= ALU_OP_SHR;
                        endcase

                        alu_left <= regs[rs1];
                        alu_right <= (opcode > OP_SHR) ? imm14 : regs[rs2];
                        state <= S_WRITEBACK;
                    end

                    OP_NOT, OP_NOTI: begin
                        alu_op <= ALU_OP_NOT;
                        alu_left <= (opcode > OP_NOT) ? imm19 : regs[rs1];
                        state <= S_WRITEBACK;
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