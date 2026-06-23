module cpu(
    input logic clk,
    input logic reset
);

typedef enum logic [5:0] {
    OP_NOP,
    OP_LB,
    OP_LBU,
    OP_LH,
    OP_LHU,
    OP_LW,
    OP_LI,
    OP_LUI,
    OP_AUIPC,
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
    OP_SLT,
    OP_SLTU,
    OP_SLTI,
    OP_SLTIU,
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
    OP_HLT = 6'h3F
} opcode_t;

logic halted;

logic reg_we;
logic [4:0] reg_addr;
logic [31:0] reg_write;
logic [31:0] regs [0:31];

logic [31:0] if_pc;
logic [31:0] if_instr;

logic [31:0] id_pc;
logic [31:0] id_instr;

opcode_t id_opcode;
logic [4:0] id_reg_addr;
logic [31:0] id_reg0;
logic [31:0] id_reg1;
logic [31:0] id_reg2;
logic [10:0] id_imm11;
logic [15:0] id_imm16;
logic [20:0] id_imm21;
logic [25:0] id_imm26;

assign id_opcode = opcode_t'(id_instr[31:26]);
assign id_reg_addr = id_instr[25:21];
assign id_reg0 = regs[id_instr[25:21]];
assign id_reg1 = regs[id_instr[20:16]];
assign id_reg2 = regs[id_instr[15:11]];
assign id_imm11 = id_instr[10:0];
assign id_imm16 = id_instr[15:0];
assign id_imm21 = id_instr[20:0];
assign id_imm26 = id_instr[25:0];

logic signed [31:0] id_simm11;
logic signed [31:0] id_simm16;
logic signed [31:0] id_simm21;
logic signed [31:0] id_simm26;

assign id_simm11 = {{21{id_imm11[10]}}, id_imm11};
assign id_simm16 = {{16{id_imm16[15]}}, id_imm16};
assign id_simm21 = {{11{id_imm21[20]}}, id_imm21};
assign id_simm26 = {{6{id_imm26[25]}}, id_imm26};

logic [31:0] ex_pc;
logic [31:0] ex_instr;

opcode_t ex_opcode;
logic [4:0] ex_reg_addr;
logic [31:0] ex_reg0;
logic [31:0] ex_reg1;
logic [31:0] ex_reg2;
logic [10:0] ex_imm11;
logic [15:0] ex_imm16;
logic [20:0] ex_imm21;
logic [25:0] ex_imm26;

logic signed [31:0] ex_simm11;
logic signed [31:0] ex_simm16;
logic signed [31:0] ex_simm21;
logic signed [31:0] ex_simm26;

logic [31:0] mem_pc;
logic [31:0] mem_instr;

opcode_t mem_opcode;
logic [4:0] mem_reg_addr;
logic [31:0] mem_reg0;
logic [31:0] mem_reg1;
logic [31:0] mem_reg2;
logic [10:0] mem_imm11;
logic [15:0] mem_imm16;
logic [20:0] mem_imm21;
logic [25:0] mem_imm26;

logic signed [31:0] mem_simm11;
logic signed [31:0] mem_simm16;
logic signed [31:0] mem_simm21;
logic signed [31:0] mem_simm26;

logic [31:0] wb_pc;
logic [31:0] wb_instr;

opcode_t wb_opcode;
logic [4:0] wb_reg_addr;
logic [31:0] wb_reg0;
logic [31:0] wb_reg1;
logic [31:0] wb_reg2;
logic [10:0] wb_imm11;
logic [15:0] wb_imm16;
logic [20:0] wb_imm21;
logic [25:0] wb_imm26;

logic signed [31:0] wb_simm11;
logic signed [31:0] wb_simm16;
logic signed [31:0] wb_simm21;
logic signed [31:0] wb_simm26;

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
    alu_left = ex_reg1;
    alu_right = (ex_opcode == OP_ADDI) || (ex_opcode == OP_SUBI) || (ex_opcode == OP_ANDI) || (ex_opcode == OP_ORI) || (ex_opcode == OP_XORI)
        ? ex_simm16 : ((ex_opcode == OP_SLLI) || (ex_opcode == OP_SRLI) || (ex_opcode == OP_SRAI) ? ex_imm16 : ex_reg2);
    alu_op = ALU_OP_ADD;

    case (ex_opcode)
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

assign branch_eq = (ex_reg0 == ex_reg1);
assign branch_lt = ($signed(ex_reg0) < $signed(ex_reg1));
assign branch_ltu = (ex_reg0 < ex_reg1);

logic [31:0] ex_result;
logic [31:0] mem_result;
logic [31:0] wb_result;

logic [31:0] ex_addr;
logic [31:0] mem_addr;
logic [31:0] wb_addr;

logic [7:0] wb_result_byte;
logic [15:0] wb_result_half;

assign wb_result_byte = wb_result[8 * wb_addr[1:0]+:8];
assign wb_result_half = wb_result[16 * wb_addr[1]+:16];

logic mem_access;

logic branch_taken;
logic [31:0] branch_target;

logic should_halt;

always_comb begin
    if (mem_access)
        ram_addr = mem_addr;
    else
        ram_addr = if_pc;
end

always_comb begin
    branch_taken = 0;
    branch_target = ex_pc + (ex_simm16 << 2);
    should_halt = 0;
    ex_result = alu_result;
    ex_addr = 0;

    case (ex_opcode)
        OP_LB, OP_LBU, OP_LH, OP_LHU, OP_LW, OP_SB, OP_SH, OP_SW:
            ex_addr = ex_reg1 + ex_simm16;

        OP_B: begin
            branch_target = (ex_imm26 << 2);
            branch_taken = 1;
        end

        OP_BR: begin
            branch_target = ex_reg0;
            branch_taken = 1;
        end

        OP_BL: begin
            ex_result = ex_pc + 4;
            branch_taken = 1;
        end

        OP_BEQ: branch_taken = branch_eq;
        OP_BNE: branch_taken = !branch_eq;
        OP_BLT: branch_taken = branch_lt;
        OP_BLTU: branch_taken = branch_ltu;
        OP_BGE: branch_taken = !branch_lt;
        OP_BGEU: branch_taken = !branch_ltu;

        OP_HLT: should_halt = 1;
    endcase
end

always_comb begin
    ram_write = 0;
    mem_access = 0;
    ram_we = 0;

    case (mem_opcode)
        OP_LB, OP_LBU, OP_LH, OP_LHU, OP_LW:
            mem_access = 1;

        OP_SB: begin
            ram_we = 4'b0001 << ram_addr[1:0];
            ram_write = {24'b0, mem_reg0[7:0]} << (8 * ram_addr[1:0]);
            mem_access = 1;
        end

        OP_SH: begin
            ram_we = 4'b0011 << (2 * ram_addr[1]);
            ram_write = {16'b0, mem_reg0[15:0]} << (16 * ram_addr[1]);
            mem_access = 1;
        end

        OP_SW: begin
            ram_we = 4'b1111;
            ram_write = mem_reg0;
            mem_access = 1;
        end
    endcase
end

always_comb begin
    reg_addr = wb_reg_addr;
    reg_write = 0;
    reg_we = 1;

    case (wb_opcode)
        OP_LI: reg_write = wb_imm21;
        OP_LUI: reg_write = wb_imm21 << 11;
        OP_AUIPC: reg_write = wb_pc + (wb_imm21 << 11);
        OP_LB: reg_write = {{24{wb_result_byte[7]}}, wb_result_byte};
        OP_LBU: reg_write = wb_result_byte;
        OP_LH: reg_write = {{16{wb_result_half[15]}}, wb_result_half};
        OP_LHU: reg_write = wb_result_half;
        OP_LW: reg_write = wb_result;
        OP_SLT: reg_write = ($signed(wb_reg1) < $signed(wb_reg2));
        OP_SLTU: reg_write = (wb_reg1 < wb_reg2);
        OP_SLTI: reg_write = ($signed(wb_reg1) < wb_simm16);
        OP_SLTIU: reg_write = (wb_reg1 < {{16{1'b0}}, wb_imm16});
        OP_ADD, OP_ADDI, OP_SUB, OP_SUBI,
        OP_MUL, OP_MULH, OP_MULHSU, OP_MULHU, OP_DIV, OP_DIVU, OP_REM, OP_REMU,
        OP_AND, OP_ANDI, OP_OR, OP_ORI, OP_XOR, OP_XORI,
        OP_SLL, OP_SLLI, OP_SRL, OP_SRLI, OP_SRA, OP_SRAI,
        OP_BL: reg_write = wb_result;
        default: reg_we = 0;
    endcase
end

integer i;

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        for (i = 0; i < 32; i++)
            regs[i] <= 0;

        if_pc <= 0;
        if_instr <= 0;

        id_pc <= 0;
        id_instr <= 0;

        ex_pc <= 0;
        ex_instr <= 0;
        ex_opcode <= OP_NOP;
        ex_reg_addr <= 0;
        ex_reg0 <= 0;
        ex_reg1 <= 0;
        ex_reg2 <= 0;
        ex_imm11 <= 0;
        ex_imm16 <= 0;
        ex_imm21 <= 0;
        ex_imm26 <= 0;
        ex_simm11 <= 0;
        ex_simm16 <= 0;
        ex_simm21 <= 0;
        ex_simm26 <= 0;

        mem_pc <= 0;
        mem_instr <= 0;
        mem_result <= 0;
        mem_opcode <= OP_NOP;
        mem_reg_addr <= 0;
        mem_reg0 <= 0;
        mem_reg1 <= 0;
        mem_reg2 <= 0;
        mem_imm11 <= 0;
        mem_imm16 <= 0;
        mem_imm21 <= 0;
        mem_imm26 <= 0;
        mem_simm11 <= 0;
        mem_simm16 <= 0;
        mem_simm21 <= 0;
        mem_simm26 <= 0;

        wb_pc <= 0;
        wb_instr <= 0;
        wb_result <= 0;
        wb_opcode <= OP_NOP;
        wb_reg_addr <= 0;
        wb_reg0 <= 0;
        wb_reg1 <= 0;
        wb_reg2 <= 0;
        wb_imm11 <= 0;
        wb_imm16 <= 0;
        wb_imm21 <= 0;
        wb_imm26 <= 0;
        wb_simm11 <= 0;
        wb_simm16 <= 0;
        wb_simm21 <= 0;
        wb_simm26 <= 0;

        halted <= 0;
    end else begin
        if (reg_we && reg_addr != 0)
            regs[reg_addr] <= reg_write;

        if_pc <= !halted ? (branch_taken ? branch_target : (!mem_access ? if_pc + 4 : 0)) : 0;
        if_instr <= !halted ? (branch_taken ? 0 : (!mem_access ? ram_read : 0)) : 0;

        id_pc <= branch_taken ? 0 : if_pc;
        id_instr <= branch_taken ? 0 : if_instr;

        ex_pc <= id_pc;
        ex_instr <= id_instr;
        ex_opcode <= id_opcode;
        ex_reg_addr <= id_reg_addr;
        ex_reg0 <= id_reg0;
        ex_reg1 <= id_reg1;
        ex_reg2 <= id_reg2;
        ex_imm11 <= id_imm11;
        ex_imm16 <= id_imm16;
        ex_imm21 <= id_imm21;
        ex_imm26 <= id_imm26;
        ex_simm11 <= id_simm11;
        ex_simm16 <= id_simm16;
        ex_simm21 <= id_simm21;
        ex_simm26 <= id_simm26;

        mem_pc <= ex_pc;
        mem_instr <= ex_instr;
        mem_result <= ex_result;
        mem_addr <= ex_addr;
        mem_opcode <= ex_opcode;
        mem_reg_addr <= ex_reg_addr;
        mem_reg0 <= ex_reg0;
        mem_reg1 <= ex_reg1;
        mem_reg2 <= ex_reg2;
        mem_imm11 <= ex_imm11;
        mem_imm16 <= ex_imm16;
        mem_imm21 <= ex_imm21;
        mem_imm26 <= ex_imm26;
        mem_simm11 <= ex_simm11;
        mem_simm16 <= ex_simm16;
        mem_simm21 <= ex_simm21;
        mem_simm26 <= ex_simm26;

        wb_pc <= mem_pc;
        wb_instr <= mem_instr;
        wb_result <= mem_result;
        wb_opcode <= mem_opcode;
        wb_reg_addr <= mem_reg_addr;
        wb_reg0 <= mem_reg0;
        wb_reg1 <= mem_reg1;
        wb_reg2 <= mem_reg2;
        wb_imm11 <= mem_imm11;
        wb_imm16 <= mem_imm16;
        wb_imm21 <= mem_imm21;
        wb_imm26 <= mem_imm26;
        wb_simm11 <= mem_simm11;
        wb_simm16 <= mem_simm16;
        wb_simm21 <= mem_simm21;
        wb_simm26 <= mem_simm26;

        if (should_halt)
            halted <= 1;

        if (halted && if_instr == 0 && id_instr == 0 && ex_instr == 0 && mem_instr == 0 && wb_instr == 0)
            $finish;
    end
end

endmodule