module cpu(
    input logic clk,
    input logic reset
);

typedef enum logic [7:0] {
    OP_NOP,
    OP_LD,
    OP_LDI,
    OP_ST,
    OP_B,
    OP_BR,
    OP_BL,
    OP_BEQ,
    OP_BNE,
    OP_BLT,
    OP_BLTU,
    OP_BGE,
    OP_BGEU,
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

typedef enum logic [2:0] {
    S_FETCH,
    S_DECODE,
    S_EXECUTE,
    S_MEMORY,
    S_WRITEBACK
} state_t;

state_t state;
logic [31:0] pc;
logic [31:0] instr;
logic halted;

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

logic reg_we;
logic [4:0] reg_addr;
logic [31:0] reg_write;
logic [31:0] regs [0:31];

logic ram_we;
logic _ram_we;
logic [31:0] ram_addr;
logic [31:0] ram_write;
logic [31:0] ram_read;

ram ram0(
    .clk(clk),
    .we(_ram_we),
    .addr(ram_addr),
    .write(ram_write),
    .read(ram_read)
);

logic [31:0] alu_left;
logic [31:0] alu_right;
alu_op_t alu_op;
logic [31:0] alu_result;

alu alu0(
    .left(alu_left),
    .right(alu_right),
    .alu_op(alu_op),
    .result(alu_result)
);

always_comb begin
    alu_left = 0;
    alu_right = 0;
    alu_op = ALU_OP_ADD;

    case (opcode)
        OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR, OP_NOT, OP_SHL, OP_SHR,
        OP_ADDI, OP_SUBI, OP_ANDI, OP_ORI, OP_XORI, OP_SHLI, OP_SHRI:
            alu_left = regs[rs1];

        OP_NOTI: alu_left = imm19;
    endcase

    case (opcode)
        OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR, OP_SHL, OP_SHR:
            alu_right = regs[rs2];

        OP_ADDI, OP_SUBI, OP_ANDI, OP_ORI, OP_XORI, OP_SHLI, OP_SHRI:
            alu_right = imm14;
    endcase

    case (opcode)
        OP_ADD, OP_ADDI: alu_op = ALU_OP_ADD;
        OP_SUB, OP_SUBI: alu_op = ALU_OP_SUB;
        OP_AND, OP_ANDI: alu_op = ALU_OP_AND;
        OP_OR, OP_ORI: alu_op = ALU_OP_OR;
        OP_XOR, OP_XORI: alu_op = ALU_OP_XOR;
        OP_NOT, OP_NOTI: alu_op = ALU_OP_NOT;
        OP_SHL, OP_SHLI: alu_op = ALU_OP_SHL;
        OP_SHR, OP_SHRI: alu_op = ALU_OP_SHR;
    endcase
end

logic uart_we;

uart uart0(
    .clk(clk),
    .we(uart_we),
    .write(ram_write)
);

always_comb begin
    uart_we = 0;
    _ram_we = 0;

    if (ram_addr == 32'hFFFF) begin
        uart_we = ram_we;
    end else begin
        _ram_we = ram_we;
    end
end

logic branch_eq;
logic branch_lt;
logic branch_ltu;

assign branch_eq = (regs[rd] == regs[rs1]);
assign branch_lt = ($signed(regs[rd]) < $signed(regs[rs1]));
assign branch_ltu = (regs[rd] < regs[rs1]);

state_t next_state;
logic [31:0] next_pc;
logic [31:0] next_instr;
logic next_halted;

always_comb begin
    next_state = state;
    next_pc = pc;
    next_instr = instr;
    next_halted = halted;

    reg_we = 0;
    reg_addr = rd;
    reg_write = 0;

    ram_we = 0;
    ram_addr = pc;
    ram_write = 0;

    case (state)
        S_FETCH: begin
            next_state = S_DECODE;
        end

        S_DECODE: begin
            next_instr = ram_read;

            case (opcode_t'(ram_read[31:24]))
                OP_LD, OP_ST: next_state = S_MEMORY;
                OP_LDI: next_state = S_WRITEBACK;
                default: next_state = S_EXECUTE;
            endcase
        end

        S_EXECUTE: begin
            next_state = S_FETCH;

            case (opcode)
                OP_NOP: next_pc = pc + 1;

                OP_B: next_pc = imm24;
                OP_BR: next_pc = regs[rd];
                OP_BL: begin
                    reg_we = (rd != 0);
                    reg_write = pc + 1;
                    next_pc = imm19;
                end

                OP_BEQ: next_pc = branch_eq ? imm14 : pc + 1;
                OP_BNE: next_pc = !branch_eq ? imm14 : pc + 1;
                OP_BLT: next_pc = branch_lt ? imm14 : pc + 1;
                OP_BLTU: next_pc = branch_ltu ? imm14 : pc + 1;
                OP_BGE: next_pc = !branch_lt ? imm14 : pc + 1;
                OP_BGEU: next_pc = !branch_ltu ? imm14 : pc + 1;

                OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR, OP_NOT, OP_SHL, OP_SHR,
                OP_ADDI, OP_SUBI, OP_ANDI, OP_ORI, OP_XORI, OP_NOTI, OP_SHLI, OP_SHRI:
                    next_state = S_WRITEBACK;

                OP_HLT: next_halted = 1;
            endcase
        end

        S_MEMORY: begin
            ram_addr = regs[rs1] + imm14;

            case (opcode)
                OP_LD: next_state = S_WRITEBACK;

                OP_ST: begin
                    ram_we = 1;
                    ram_write = regs[rd];
                    next_state = S_FETCH;
                    next_pc = pc + 1;
                end
            endcase
        end

        S_WRITEBACK: begin
            reg_we = (rd != 0);
            next_state = S_FETCH;
            next_pc = pc + 1;

            case (opcode)
                OP_LD: reg_write = ram_read;
                OP_LDI: reg_write = imm19;
                default: reg_write = alu_result;
            endcase
        end
    endcase
end

integer i;

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        for (i = 0; i < 32; i++)
            regs[i] <= 0;

        state <= S_FETCH;
        pc <= 0;
        instr <= 0;
        halted <= 0;
    end else if (!halted) begin
        if (reg_we && reg_addr != 0)
            regs[reg_addr] <= reg_write;

        state <= next_state;
        pc <= next_pc;
        instr <= next_instr;
        halted <= next_halted;
    end else begin
        $finish;
    end
end

endmodule