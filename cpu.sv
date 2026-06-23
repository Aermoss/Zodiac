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

logic reg_we;
logic [4:0] reg_addr;
logic [31:0] reg_write;
logic [31:0] regs [0:31];

logic [31:0] if_pc;
logic [31:0] if_pc_current;
wire [31:0] if_instr;

logic [31:0] id_pc;
logic [31:0] id_instr;
opcode_t id_opcode;
logic [4:0] id_reg_addr;
logic [31:0] id_reg0;
logic [31:0] id_reg1;
logic [31:0] id_reg2;
logic [15:0] id_imm16;
logic [20:0] id_imm21;
logic [25:0] id_imm26;
logic signed [31:0] id_simm16;
logic signed [31:0] id_simm21;

assign id_opcode = opcode_t'(id_instr[31:26]);
assign id_reg_addr = id_instr[25:21];
assign id_reg0 = (reg_we && reg_addr != 0 && reg_addr == id_instr[25:21]) ? reg_write : regs[id_instr[25:21]];
assign id_reg1 = (reg_we && reg_addr != 0 && reg_addr == id_instr[20:16]) ? reg_write : regs[id_instr[20:16]];
assign id_reg2 = (reg_we && reg_addr != 0 && reg_addr == id_instr[15:11]) ? reg_write : regs[id_instr[15:11]];
assign id_imm16 = id_instr[15:0];
assign id_imm21 = id_instr[20:0];
assign id_imm26 = id_instr[25:0];
assign id_simm16 = {{16{id_imm16[15]}}, id_imm16};
assign id_simm21 = {{11{id_imm21[20]}}, id_imm21};

logic [31:0] ex_pc;
logic [31:0] ex_instr;
logic [31:0] ex_result;
logic [31:0] ex_addr;
opcode_t ex_opcode;
logic [4:0] ex_reg_addr;
logic [31:0] ex_reg0;
logic [31:0] ex_reg1;
logic [31:0] ex_reg2;
logic [15:0] ex_imm16;
logic [20:0] ex_imm21;
logic [25:0] ex_imm26;
logic signed [31:0] ex_simm16;
logic signed [31:0] ex_simm21;

logic should_take_branch;
logic [31:0] branch_target;
logic branch_taken;

logic should_halt;
logic halted;

logic [31:0] mem_pc;
logic [31:0] mem_instr;
logic [31:0] mem_result;
logic [31:0] mem_addr;
opcode_t mem_opcode;
logic [4:0] mem_reg_addr;
logic [31:0] mem_reg0;

logic mem_access;
logic mem_op_in_mem;
logic mem_op_in_wb;

logic [31:0] wb_pc;
logic [31:0] wb_instr;
logic [31:0] wb_result;
logic [31:0] wb_addr;
opcode_t wb_opcode;
logic [4:0] wb_reg_addr;

logic [3:0] ram_we;
logic [3:0] _ram_we;
logic [31:0] ram_addr;
logic [31:0] ram_write;
logic [31:0] ram_read;

assign if_instr = ram_read;

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

function automatic logic is_mem_op(opcode_t opcode);
    case (opcode)
        OP_LB, OP_LBU, OP_LH, OP_LHU, OP_LW,
        OP_SB, OP_SH, OP_SW: return 1;
        default: return 0;
    endcase
endfunction

function automatic logic reads_reg0(opcode_t opcode);
    case (opcode)
        OP_BR,
        OP_BEQ, OP_BNE, OP_BLT, OP_BLTU, OP_BGE, OP_BGEU,
        OP_SB, OP_SH, OP_SW: return 1;
        default: return 0;
    endcase
endfunction

function automatic logic reads_reg1(opcode_t opcode);
    case (opcode)
        OP_NOP,
        OP_LI, OP_LUI, OP_AUIPC,
        OP_B,
        OP_HLT: return 0;
        default: return 1;
    endcase
endfunction

function automatic logic reads_reg2(opcode_t opcode);
    case (opcode)
        OP_ADD, OP_SUB,
        OP_MUL, OP_MULH, OP_MULHSU, OP_MULHU,
        OP_DIV, OP_DIVU, OP_REM, OP_REMU,
        OP_AND, OP_OR, OP_XOR,
        OP_SLL, OP_SRL, OP_SRA,
        OP_SLT, OP_SLTU: return 1;
        default: return 0;
    endcase
endfunction

logic mem_writes_reg;

always_comb begin
    case (mem_opcode)
        OP_LI, OP_LUI, OP_AUIPC,
        OP_SLT, OP_SLTU, OP_SLTI, OP_SLTIU,
        OP_ADD, OP_ADDI, OP_SUB, OP_SUBI,
        OP_MUL, OP_MULH, OP_MULHSU, OP_MULHU, OP_DIV, OP_DIVU, OP_REM, OP_REMU,
        OP_AND, OP_ANDI, OP_OR, OP_ORI, OP_XOR, OP_XORI,
        OP_SLL, OP_SLLI, OP_SRL, OP_SRLI, OP_SRA, OP_SRAI,
        OP_BL: mem_writes_reg = 1;
        default: mem_writes_reg = 0;
    endcase
end

logic [31:0] ex_reg0_fwd;
logic [31:0] ex_reg1_fwd;
logic [31:0] ex_reg2_fwd;

always_comb begin
    if (ex_instr[25:21] == 0)
        ex_reg0_fwd = 0;
    else if (mem_writes_reg && mem_reg_addr == ex_instr[25:21])
        ex_reg0_fwd = mem_result;
    else if (reg_we && reg_addr == ex_instr[25:21])
        ex_reg0_fwd = reg_write;
    else
        ex_reg0_fwd = ex_reg0;

    if (ex_instr[20:16] == 0)
        ex_reg1_fwd = 0;
    else if (mem_writes_reg && mem_reg_addr == ex_instr[20:16])
        ex_reg1_fwd = mem_result;
    else if (reg_we && reg_addr == ex_instr[20:16])
        ex_reg1_fwd = reg_write;
    else
        ex_reg1_fwd = ex_reg1;

    if (ex_instr[15:11] == 0)
        ex_reg2_fwd = 0;
    else if (mem_writes_reg && mem_reg_addr == ex_instr[15:11])
        ex_reg2_fwd = mem_result;
    else if (reg_we && reg_addr == ex_instr[15:11])
        ex_reg2_fwd = reg_write;
    else
        ex_reg2_fwd = ex_reg2;
end

logic hazard_stall;

assign hazard_stall = (ex_opcode == OP_LB || ex_opcode == OP_LBU || ex_opcode == OP_LH || ex_opcode == OP_LHU || ex_opcode == OP_LW) && (ex_reg_addr != 0) && (
    (reads_reg0(id_opcode) && id_instr[25:21] == ex_reg_addr) ||
    (reads_reg1(id_opcode) && id_instr[20:16] == ex_reg_addr) ||
    (reads_reg2(id_opcode) && id_instr[15:11] == ex_reg_addr)
);

always_comb begin
    alu_left = ex_reg1_fwd;
    alu_right = (ex_opcode == OP_ADDI) || (ex_opcode == OP_SUBI) || (ex_opcode == OP_ANDI) || (ex_opcode == OP_ORI) || (ex_opcode == OP_XORI)
        ? ex_simm16 : ((ex_opcode == OP_SLLI) || (ex_opcode == OP_SRLI) || (ex_opcode == OP_SRAI) ? ex_imm16 : ex_reg2_fwd);
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

    if (ram_addr == 32'hFFFF)
        uart_we = ram_we;
    else
        _ram_we = ram_we;
end

logic branch_eq;
logic branch_lt;
logic branch_ltu;

assign branch_eq = (ex_reg0_fwd == ex_reg1_fwd);
assign branch_lt = ($signed(ex_reg0_fwd) < $signed(ex_reg1_fwd));
assign branch_ltu = (ex_reg0_fwd < ex_reg1_fwd);

always_comb begin
    should_take_branch = 0;
    branch_target = ex_pc + (ex_simm16 << 2);
    should_halt = 0;
    ex_result = alu_result;
    ex_addr = 0;

    case (ex_opcode)
        OP_LB, OP_LBU, OP_LH, OP_LHU, OP_LW, OP_SB, OP_SH, OP_SW:
            ex_addr = ex_reg1_fwd + ex_simm16;

        OP_LI: ex_result = ex_imm21;
        OP_LUI: ex_result = ex_imm21 << 11;
        OP_AUIPC: ex_result = ex_pc + (ex_imm21 << 11);
        OP_SLT: ex_result = ($signed(ex_reg1_fwd) < $signed(ex_reg2_fwd));
        OP_SLTU: ex_result = (ex_reg1_fwd < ex_reg2_fwd);
        OP_SLTI: ex_result = ($signed(ex_reg1_fwd) < ex_simm16);
        OP_SLTIU: ex_result = (ex_reg1_fwd < {{16{1'b0}}, ex_imm16});

        OP_B: begin
            branch_target = ex_imm26 << 2;
            should_take_branch = 1;
        end

        OP_BR: begin
            branch_target = ex_reg0_fwd;
            should_take_branch = 1;
        end

        OP_BL: begin
            ex_result = ex_pc + 4;
            branch_target = ex_pc + (ex_simm21 << 2);
            should_take_branch = 1;
        end

        OP_BEQ: should_take_branch = branch_eq;
        OP_BNE: should_take_branch = !branch_eq;
        OP_BLT: should_take_branch = branch_lt;
        OP_BLTU: should_take_branch = branch_ltu;
        OP_BGE: should_take_branch = !branch_lt;
        OP_BGEU: should_take_branch = !branch_ltu;
        OP_HLT: should_halt = 1;
    endcase
end

always_comb begin
    if (mem_access)
        ram_addr = mem_addr;
    else
        ram_addr = if_pc;
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

logic [7:0] ram_read_byte;
logic [15:0] ram_read_half;

assign ram_read_byte = ram_read[8 * wb_addr[1:0]+:8];
assign ram_read_half = ram_read[16 * wb_addr[1]+:16];

always_comb begin
    reg_addr = wb_reg_addr;
    reg_write = 0;
    reg_we = 1;

    case (wb_opcode)
        OP_LI, OP_LUI, OP_AUIPC,
        OP_SLT, OP_SLTU, OP_SLTI, OP_SLTIU,
        OP_ADD, OP_ADDI, OP_SUB, OP_SUBI,
        OP_MUL, OP_MULH, OP_MULHSU, OP_MULHU,
        OP_DIV, OP_DIVU, OP_REM, OP_REMU,
        OP_AND, OP_ANDI, OP_OR, OP_ORI, OP_XOR, OP_XORI,
        OP_SLL, OP_SLLI, OP_SRL, OP_SRLI, OP_SRA, OP_SRAI,
        OP_BL: reg_write = wb_result;
        OP_LB: reg_write = {{24{ram_read_byte[7]}}, ram_read_byte};
        OP_LBU: reg_write = ram_read_byte;
        OP_LH: reg_write = {{16{ram_read_half[15]}}, ram_read_half};
        OP_LHU: reg_write = ram_read_half;
        OP_LW: reg_write = ram_read;
        default: reg_we = 0;
    endcase
end

integer i;

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        for (i = 0; i < 32; i++)
            regs[i] <= 0;

        if_pc <= 0;
        if_pc_current <= 0;

        id_pc <= 0;
        id_instr <= 0;

        ex_pc <= 0;
        ex_instr <= 0;
        ex_opcode <= OP_NOP;
        ex_reg_addr <= 0;
        ex_reg0 <= 0;
        ex_reg1 <= 0;
        ex_reg2 <= 0;
        ex_imm16 <= 0;
        ex_imm21 <= 0;
        ex_imm26 <= 0;
        ex_simm16 <= 0;
        ex_simm21 <= 0;

        halted <= 0;
        branch_taken <= 0;

        mem_pc <= 0;
        mem_instr <= 0;
        mem_result <= 0;
        mem_addr <= 0;
        mem_opcode <= OP_NOP;
        mem_reg_addr <= 0;
        mem_reg0 <= 0;

        mem_op_in_mem <= 0;
        mem_op_in_wb <= 0;

        wb_pc <= 0;
        wb_instr <= 0;
        wb_result <= 0;
        wb_addr <= 0;
        wb_opcode <= OP_NOP;
        wb_reg_addr <= 0;
    end else begin
        if (reg_we && reg_addr != 0)
            regs[reg_addr] <= reg_write;

        if (halted) begin
            if_pc <= 0;
            if_pc_current <= 0;
        end else if (should_take_branch) begin
            if_pc <= branch_target;
            if_pc_current <= branch_target;
        end else if (hazard_stall || mem_op_in_mem) begin
            if_pc <= if_pc_current;
            if_pc_current <= if_pc_current;
        end else begin
            if_pc <= if_pc + 4;
            if_pc_current <= if_pc;
        end

        if (should_take_branch || branch_taken || halted) begin
            id_pc <= 0;
            id_instr <= 0;
        end else if (hazard_stall) begin
            id_pc <= id_pc;
            id_instr <= id_instr;
        end else if (mem_op_in_mem || mem_op_in_wb) begin
            id_pc <= if_pc_current;
            id_instr <= 0;
        end else begin
            id_pc <= if_pc_current;
            id_instr <= if_instr;
        end

        if (should_take_branch || hazard_stall || halted) begin
            ex_pc <= 0;
            ex_instr <= 0;
            ex_opcode <= OP_NOP;
            ex_reg_addr <= 0;
            ex_reg0 <= 0;
            ex_reg1 <= 0;
            ex_reg2 <= 0;
            ex_imm16 <= 0;
            ex_imm21 <= 0;
            ex_imm26 <= 0;
            ex_simm16 <= 0;
            ex_simm21 <= 0;
        end else begin
            ex_pc <= id_pc;
            ex_instr <= id_instr;
            ex_opcode <= id_opcode;
            ex_reg_addr <= id_reg_addr;
            ex_reg0 <= id_reg0;
            ex_reg1 <= id_reg1;
            ex_reg2 <= id_reg2;
            ex_imm16 <= id_imm16;
            ex_imm21 <= id_imm21;
            ex_imm26 <= id_imm26;
            ex_simm16 <= id_simm16;
            ex_simm21 <= id_simm21;
        end

        if (should_halt)
            halted <= 1;

        branch_taken <= should_take_branch;

        mem_pc <= ex_pc;
        mem_instr <= ex_instr;
        mem_result <= ex_result;
        mem_addr <= ex_addr;
        mem_opcode <= ex_opcode;
        mem_reg_addr <= ex_reg_addr;
        mem_reg0 <= ex_reg0_fwd;

        mem_op_in_mem <= is_mem_op(ex_opcode);
        mem_op_in_wb <= mem_op_in_mem;

        wb_pc <= mem_pc;
        wb_instr <= mem_instr;
        wb_result <= mem_result;
        wb_addr <= mem_addr;
        wb_opcode <= mem_opcode;
        wb_reg_addr <= mem_reg_addr;

        if (halted && id_instr == 0 && ex_instr == 0 && mem_instr == 0 && wb_instr == 0)
            $finish;
    end
end

endmodule