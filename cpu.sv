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

module cpu #(
    parameter bit SIMULATION = 1'b1,
    parameter int CLK_FREQ = 33000000
) (
    input logic clk,
    input logic rst,

    input logic uart_rx,
    output logic uart_tx,

    input logic button,
    output logic [5:0] leds,
    output logic ws2812,

    output logic mem_access,
    output logic [3:0] actual_mem_we,
    output logic [31:0] mem_addr,
    output logic [31:0] mem_write,
    input logic [31:0] mem_read,
    input logic bus_stall
);
    logic [3:0] mem_we;

    typedef enum logic [5:0] {
        OP_NOP,
        OP_LB,
        OP_LBU,
        OP_LH,
        OP_LHU,
        OP_LW,
        OP_LUI,
        OP_AUIPC,
        OP_SB,
        OP_SH,
        OP_SW,
        OP_B,
        OP_BR,
        OP_BL,
        OP_BLR,
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

    assign if_instr = mem_read;

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
    logic signed [31:0] id_simm26;

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
    assign id_simm26 = {{6{id_imm26[25]}}, id_imm26};

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
    logic signed [31:0] ex_simm26;

    logic should_take_branch;
    logic [31:0] branch_target;
    logic branch_taken;

    logic should_halt;
    logic halted;

    logic [31:0] mem_pc;
    logic [31:0] mem_instr;
    logic [31:0] mem_result;
    logic [31:0] stage_mem_addr;
    opcode_t mem_opcode;
    logic [4:0] mem_reg_addr;
    logic [31:0] mem_reg0;

    logic mem_op_in_mem;
    logic mem_op_in_wb;

    logic [31:0] wb_pc;
    logic [31:0] wb_instr;
    logic [31:0] wb_result;
    logic [31:0] wb_addr;
    opcode_t wb_opcode;
    logic [4:0] wb_reg_addr;

    logic [31:0] alu_left;
    logic [31:0] alu_right;
    alu_op_t alu_op;
    logic div_start;
    logic [31:0] alu_result;
    logic alu_ready;

    alu alu0(
        .clk(clk),
        .rst(rst),
        .left(alu_left),
        .right(alu_right),
        .alu_op(alu_op),
        .start(div_start),
        .result(alu_result),
        .ready(alu_ready)
    );

    logic is_div_op, div_active, div_stall;
    assign is_div_op = (ex_opcode == OP_DIV) || (ex_opcode == OP_DIVU) || (ex_opcode == OP_REM) || (ex_opcode == OP_REMU);
    assign div_start = is_div_op && !div_active;
    assign div_stall = is_div_op && !alu_ready;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            div_active <= 1'b0;
        end else begin
            if (div_start) begin
                div_active <= 1'b1;
            end else if (alu_ready) begin
                div_active <= 1'b0;
            end
        end
    end

    function automatic logic is_load_op(opcode_t opcode);
        case (opcode)
            OP_LB, OP_LBU, OP_LH, OP_LHU, OP_LW: return 1;
            default: return 0;
        endcase
    endfunction

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
            OP_LUI, OP_AUIPC,
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
            OP_LUI, OP_AUIPC,
            OP_SLT, OP_SLTU, OP_SLTI, OP_SLTIU,
            OP_ADD, OP_ADDI, OP_SUB, OP_SUBI,
            OP_MUL, OP_MULH, OP_MULHSU, OP_MULHU, OP_DIV, OP_DIVU, OP_REM, OP_REMU,
            OP_AND, OP_ANDI, OP_OR, OP_ORI, OP_XOR, OP_XORI,
            OP_SLL, OP_SLLI, OP_SRL, OP_SRLI, OP_SRA, OP_SRAI,
            OP_BL, OP_BLR: mem_writes_reg = 1;
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

    assign hazard_stall = is_load_op(ex_opcode) && (ex_reg_addr != 0) && (
        (reads_reg0(id_opcode) && id_instr[25:21] == ex_reg_addr) ||
        (reads_reg1(id_opcode) && id_instr[20:16] == ex_reg_addr) ||
        (reads_reg2(id_opcode) && id_instr[15:11] == ex_reg_addr)
    );

    always_comb begin
        alu_left = ex_reg1_fwd;
        alu_right = (ex_opcode == OP_ANDI) || (ex_opcode == OP_ORI) || (ex_opcode == OP_XORI) || (ex_opcode == OP_SLLI) || (ex_opcode == OP_SRLI) || (ex_opcode == OP_SRAI)
            ? ex_imm16 : ((ex_opcode == OP_ADDI) || (ex_opcode == OP_SUBI) ? ex_simm16 : ex_reg2_fwd);
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
    logic [15:0] uart_clks_per_bit;

    logic uart_tx_busy;
    logic uart_tx_started;
    logic uart_tx_write;

    assign uart_tx_write = (mem_addr == 32'hFFFF) && (mem_we != 0) && !uart_tx_busy && !uart_tx_started;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            uart_tx_started <= 0;
        else if (uart_tx_write)
            uart_tx_started <= 1;
        else
            uart_tx_started <= 0;
    end

    generate
        if (SIMULATION) begin : sim_uart
            always_ff @(posedge clk) begin
                if (uart_we[0]) $write("%c", mem_write[7:0]);
                if (uart_we[1]) $write("%c", mem_write[15:8]);
                if (uart_we[2]) $write("%c", mem_write[23:16]);
                if (uart_we[3]) $write("%c", mem_write[31:24]);
            end

            assign uart_tx_busy = 1'b0;
            assign uart_tx = 1'b1;
        end else begin : hw_uart
            logic [7:0] uart_tx_data;

            always_comb begin
                if (uart_we[3]) uart_tx_data = mem_write[31:24];
                else if (uart_we[2]) uart_tx_data = mem_write[23:16];
                else if (uart_we[1]) uart_tx_data = mem_write[15:8];
                else uart_tx_data = mem_write[7:0];
            end

            uart_tx uart_tx0 (
                .clk(clk),
                .rst(rst),
                .clks_per_bit(uart_clks_per_bit),
                .tx_data(uart_tx_data),
                .tx_write(uart_tx_write),
                .tx_busy(uart_tx_busy),
                .tx_pin(uart_tx)
            );
        end
    endgenerate

    logic [7:0] uart_rx_byte;
    logic uart_rx_ready;

    uart_rx uart_rx0 (
        .clk(clk),
        .rst(rst),
        .clks_per_bit(uart_clks_per_bit),
        .rx_pin(uart_rx),
        .read_ack(mem_addr == 32'hFFFF && mem_we == 0 && mem_access),
        .rx_byte(uart_rx_byte),
        .rx_ready(uart_rx_ready)
    );

    localparam int UART_DEFAULT_BAUD_RATE = 115200;
    localparam int UART_DEFAULT_CLKS_PER_BIT = CLK_FREQ / UART_DEFAULT_BAUD_RATE;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            uart_clks_per_bit <= UART_DEFAULT_CLKS_PER_BIT;
        else if (mem_addr == 32'hFFF8 && mem_we != 0)
            uart_clks_per_bit <= mem_write[15:0];
    end

    logic [31:0] ms_counter;
    logic [21:0] tick_divider;

    localparam int TICK_MAX = (CLK_FREQ / 1000) - 1;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            ms_counter <= 0;
            tick_divider <= 0;
        end else if (tick_divider >= TICK_MAX) begin
            tick_divider <= 0;
            ms_counter <= ms_counter + 32'd1;
        end else begin
            tick_divider <= tick_divider + 31'd1;
        end
    end

    logic button_sync0, button_sync1;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            button_sync0 <= 1'b1;
            button_sync1 <= 1'b1;
        end else begin
            button_sync0 <= button;
            button_sync1 <= button_sync0;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            leds <= 6'h3F;
        else if (mem_addr == 32'hFFF0 && mem_we != 0)
            leds <= mem_write[5:0];
    end

    ws2812_tx #(
        .CLK_FREQ(CLK_FREQ)
    ) ws2812_tx0 (
        .clk(clk),
        .rst(rst),
        .strobe(mem_addr == 32'hFFE0 && mem_we != 0),
        .write(mem_write[23:0]),
        .busy(),
        .out(ws2812)
    );

    always_comb begin
        uart_we = 0;
        actual_mem_we = 0;

        if (mem_addr == 32'hFFFF)
            uart_we = mem_we;
        else if (mem_addr != 32'hFFF0 && mem_addr != 32'hFFE0 && mem_addr != 32'hFFEC && mem_addr != 32'hFFF4 && mem_addr != 32'hFFF8)
            actual_mem_we = mem_we;
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

            OP_LUI: ex_result = (ex_imm21 << 11);
            OP_AUIPC: ex_result = ex_pc + (ex_imm21 << 11);
            OP_SLT: ex_result = ($signed(ex_reg1_fwd) < $signed(ex_reg2_fwd));
            OP_SLTU: ex_result = (ex_reg1_fwd < ex_reg2_fwd);
            OP_SLTI: ex_result = ($signed(ex_reg1_fwd) < ex_simm16);
            OP_SLTIU: ex_result = (ex_reg1_fwd < {{16{1'b0}}, ex_imm16});

            OP_B: begin
                branch_target = ex_pc + (ex_simm26 << 2);
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

            OP_BLR: begin
                ex_result = ex_pc + 4;
                branch_target = ex_reg1_fwd;
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
            mem_addr = stage_mem_addr;
        else
            mem_addr = if_pc;
    end

    always_comb begin
        mem_write = 0;
        mem_access = 0;
        mem_we = 0;

        case (mem_opcode)
            OP_LB, OP_LBU, OP_LH, OP_LHU, OP_LW:
                mem_access = 1;

            OP_SB: begin
                mem_we = 4'b0001 << mem_addr[1:0];
                mem_write = {24'b0, mem_reg0[7:0]} << (8 * mem_addr[1:0]);
                mem_access = 1;
            end

            OP_SH: begin
                mem_we = 4'b0011 << (2 * mem_addr[1]);
                mem_write = {16'b0, mem_reg0[15:0]} << (16 * mem_addr[1]);
                mem_access = 1;
            end

            OP_SW: begin
                mem_we = 4'b1111;
                mem_write = mem_reg0;
                mem_access = 1;
            end
        endcase
    end

    logic [31:0] wb_read_word;

    always_comb begin
        if (wb_addr == 32'hFFFF)
            wb_read_word = {4{uart_rx_byte}};
        else if (wb_addr == 32'hFFFC)
            wb_read_word = {30'b0, uart_tx_busy, uart_rx_ready};
        else if (wb_addr == 32'hFFF8)
            wb_read_word = {16'b0, uart_clks_per_bit};
        else if (wb_addr == 32'hFFEC)
            wb_read_word = ms_counter;
        else if (wb_addr == 32'hFFF4)
            wb_read_word = {31'b0, button_sync1};
        else
            wb_read_word = mem_read;
    end

    logic [15:0] wb_read_half;
    logic [7:0] wb_read_byte;

    assign wb_read_half = wb_read_word[16 * wb_addr[1]+:16];
    assign wb_read_byte = wb_read_word[8 * wb_addr[1:0]+:8];

    always_comb begin
        reg_addr = wb_reg_addr;
        reg_write = 0;
        reg_we = 1;

        case (wb_opcode)
            OP_LUI, OP_AUIPC,
            OP_SLT, OP_SLTU, OP_SLTI, OP_SLTIU,
            OP_ADD, OP_ADDI, OP_SUB, OP_SUBI,
            OP_MUL, OP_MULH, OP_MULHSU, OP_MULHU,
            OP_DIV, OP_DIVU, OP_REM, OP_REMU,
            OP_AND, OP_ANDI, OP_OR, OP_ORI, OP_XOR, OP_XORI,
            OP_SLL, OP_SLLI, OP_SRL, OP_SRLI, OP_SRA, OP_SRAI,
            OP_BL, OP_BLR: reg_write = wb_result;
            OP_LB: reg_write = {{24{wb_read_byte[7]}}, wb_read_byte};
            OP_LBU: reg_write = wb_read_byte;
            OP_LH: reg_write = {{16{wb_read_half[15]}}, wb_read_half};
            OP_LHU: reg_write = wb_read_half;
            OP_LW: reg_write = wb_read_word;
            default: reg_we = 0;
        endcase
    end

    integer i;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
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
            ex_simm26 <= 0;

            halted <= 0;
            branch_taken <= 0;

            mem_pc <= 0;
            mem_instr <= 0;
            mem_result <= 0;
            stage_mem_addr <= 0;
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
            end else if (hazard_stall || mem_op_in_mem || div_stall || bus_stall) begin
                if_pc <= if_pc_current;
                if_pc_current <= if_pc_current;
            end else begin
                if_pc <= if_pc + 4;
                if_pc_current <= if_pc;
            end

            if (should_take_branch || branch_taken || halted) begin
                id_pc <= 0;
                id_instr <= 0;
            end else if (hazard_stall || div_stall || bus_stall) begin
                id_pc <= id_pc;
                id_instr <= id_instr;
            end else if (mem_op_in_mem || mem_op_in_wb) begin
                id_pc <= if_pc_current;
                id_instr <= 0;
            end else begin
                id_pc <= if_pc_current;
                id_instr <= if_instr;
            end

            if (!div_stall && !bus_stall) begin
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
                    ex_simm26 <= 0;
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
                    ex_simm26 <= id_simm26;
                end
            end

            if (should_halt)
                halted <= 1;

            branch_taken <= should_take_branch;

            if (!bus_stall) begin
                if (div_stall) begin
                    mem_pc <= 0;
                    mem_instr <= 0;
                    mem_result <= 0;
                    stage_mem_addr <= 0;
                    mem_opcode <= OP_NOP;
                    mem_reg_addr <= 0;
                    mem_reg0 <= 0;
                    mem_op_in_mem <= 0;
                end else begin
                    mem_pc <= ex_pc;
                    mem_instr <= ex_instr;
                    mem_result <= ex_result;
                    stage_mem_addr <= ex_addr;
                    mem_opcode <= ex_opcode;
                    mem_reg_addr <= ex_reg_addr;
                    mem_reg0 <= ex_reg0_fwd;
                    mem_op_in_mem <= is_mem_op(ex_opcode);
                end
            end

            if (!bus_stall) begin
                mem_op_in_wb <= mem_op_in_mem;
                wb_pc <= mem_pc;
                wb_instr <= mem_instr;
                wb_result <= mem_result;
                wb_addr <= stage_mem_addr;
                wb_opcode <= mem_opcode;
                wb_reg_addr <= mem_reg_addr;
            end

            if (halted && id_instr == 0 && ex_instr == 0 && mem_instr == 0 && wb_instr == 0)
                $finish;
        end
    end
endmodule
