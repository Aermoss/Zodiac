module cpu(
    input logic clk,
    input logic reset,
    output logic [31:0] debug
);

typedef enum logic [7:0] {
    OP_NOP,
    OP_LB,
    OP_LBU,
    OP_LH,
    OP_LHU,
    OP_LW,
    OP_LI,
    OP_SB,
    OP_SH,
    OP_SW,
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
    OP_ADDI,
    OP_SUB,
    OP_SUBI,
    OP_MUL,
    OP_MULH,
    OP_MULHSU,
    OP_MULHU,
    OP_DIV,
    OP_DIVU,
    OP_REM,
    OP_REMU,
    OP_AND,
    OP_ANDI,
    OP_OR,
    OP_ORI,
    OP_XOR,
    OP_XORI,
    OP_SLL,
    OP_SLLI,
    OP_SRL,
    OP_SRLI,
    OP_SRA,
    OP_SRAI,
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

assign debug = pc;

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

logic [3:0] ram_we;
logic [3:0] _ram_we;
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
    alu_left = regs[rs1];
    alu_right = (opcode == OP_ADDI) || (opcode == OP_SUBI) || (opcode == OP_ANDI) || (opcode == OP_ORI) || (opcode == OP_XORI)
        || (opcode == OP_SLLI) || (opcode == OP_SRLI) || (opcode == OP_SRAI) ? imm14 : regs[rs2];
    alu_op = ALU_OP_ADD;

    case (opcode)
        OP_SUB, OP_SUBI: alu_op = ALU_OP_SUB;
        OP_MUL: alu_op = ALU_OP_MUL;
        OP_MULH: alu_op = ALU_OP_MULH;
        OP_MULHSU: alu_op = ALU_OP_MULHSU;
        OP_MULHU: alu_op = ALU_OP_MULHU;
        OP_DIV: alu_op = ALU_OP_DIV;
        OP_DIVU: alu_op = ALU_OP_DIVU;
        OP_REM: alu_op = ALU_OP_REM;
        OP_REMU: alu_op = ALU_OP_REMU;
        OP_AND, OP_ANDI: alu_op = ALU_OP_AND;
        OP_OR, OP_ORI: alu_op = ALU_OP_OR;
        OP_XOR, OP_XORI: alu_op = ALU_OP_XOR;
        OP_SLL, OP_SLLI: alu_op = ALU_OP_SLL;
        OP_SRL, OP_SRLI: alu_op = ALU_OP_SRL;
        OP_SRA, OP_SRAI: alu_op = ALU_OP_SRA;
    endcase
end

logic [3:0] uart_we;

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

logic [7:0] ram_read_byte;
logic [15:0] ram_read_half;

assign ram_read_byte = ram_read[8 * ram_addr[1:0]+:8];
assign ram_read_half = ram_read[16 * ram_addr[1]+:16];

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

            case (next_instr[31:24])
                OP_LI: next_state = S_WRITEBACK;
                OP_LB, OP_LBU, OP_LH, OP_LHU, OP_LW, OP_SB, OP_SH, OP_SW: next_state = S_MEMORY;
                default: next_state = S_EXECUTE;
            endcase
        end

        S_EXECUTE: begin
            next_state = S_FETCH;

            case (opcode)
                OP_NOP: next_pc = pc + 4;

                OP_B: next_pc = imm24;
                OP_BR: next_pc = regs[rd];
                OP_BL: begin
                    reg_we = 1;
                    reg_write = pc + 4;
                    next_pc = pc + imm19;
                end

                OP_BEQ: next_pc = pc + (branch_eq ? imm14 : 4);
                OP_BNE: next_pc = pc + (!branch_eq ? imm14 : 4);
                OP_BLT: next_pc = pc + (branch_lt ? imm14 : 4);
                OP_BLTU: next_pc = pc + (branch_ltu ? imm14 : 4);
                OP_BGE: next_pc = pc + (!branch_lt ? imm14 : 4);
                OP_BGEU: next_pc = pc + (!branch_ltu ? imm14 : 4);

                OP_ADD, OP_ADDI, OP_SUB, OP_SUBI,
                OP_MUL, OP_MULH, OP_MULHSU, OP_MULHU, OP_DIV, OP_DIVU, OP_REM, OP_REMU,
                OP_AND, OP_ANDI, OP_OR, OP_ORI, OP_XOR, OP_XORI,
                OP_SLL, OP_SLLI, OP_SRL, OP_SRLI, OP_SRA, OP_SRAI:
                    next_state = S_WRITEBACK;

                OP_HLT: next_halted = 1;
            endcase
        end

        S_MEMORY: begin
            ram_addr = regs[rs1] + imm14;

            case (opcode)
                OP_LB, OP_LBU, OP_LH, OP_LHU, OP_LW: next_state = S_WRITEBACK;

                OP_SB: begin
                    ram_we = 4'b0001 << ram_addr[1:0];
                    ram_write = {24'b0, regs[rd][7:0]} << (8 * ram_addr[1:0]);
                    next_state = S_FETCH;
                    next_pc = pc + 4;
                end

                OP_SH: begin
                    assert(ram_addr[1:0] == 0);
                    ram_we = 4'b0011 << (2 * ram_addr[1]);
                    ram_write = {16'b0, regs[rd][15:0]} << (16 * ram_addr[1]);
                    next_state = S_FETCH;
                    next_pc = pc + 4;
                end

                OP_SW: begin
                    assert(ram_addr[1:0] == 0);
                    ram_we = 4'b1111;
                    ram_write = regs[rd];
                    next_state = S_FETCH;
                    next_pc = pc + 4;
                end
            endcase
        end

        S_WRITEBACK: begin
            reg_we = 1;
            next_state = S_FETCH;
            next_pc = pc + 4;

            case (opcode)
                OP_LI: reg_write = imm19;
                OP_LB: reg_write = {{24{ram_read_byte[7]}}, ram_read_byte};
                OP_LBU: reg_write = ram_read_byte;

                OP_LH: begin
                    assert(!ram_addr[0]);
                    reg_write = {{16{ram_read_half[15]}}, ram_read_half};
                end

                OP_LHU: begin
                    assert(!ram_addr[0]);
                    reg_write = ram_read_half;
                end

                OP_LW: begin
                    assert(ram_addr[1:0] == 0);
                    reg_write = ram_read;
                end

                OP_LW: begin
                    assert(ram_addr[1:0] == 0);
                    reg_write = ram_read;
                end

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