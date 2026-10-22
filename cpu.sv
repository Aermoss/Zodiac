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
    parameter int CLK_FREQ = 54000000
) (
    input logic clk,
    input logic rst,

    input logic uart_rx,
    output logic uart_tx,

    input logic button,
    output logic [5:0] leds,
    output logic ws2812,

    output logic [31:0] fetch_addr,
    input logic [31:0] fetch_read,

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
        OP_CSRR,
        OP_CSRW,
        OP_ERET,
        OP_HLT = 6'h3F
    } opcode_t;

    localparam logic [15:0] CSR_STATUS = 0;
    localparam logic [15:0] CSR_IENABLE = 1;
    localparam logic [15:0] CSR_IPENDING = 2;
    localparam logic [15:0] CSR_EPC = 3;
    localparam logic [15:0] CSR_CAUSE = 4;
    localparam logic [15:0] CSR_VECTOR = 5;
    localparam logic [15:0] CSR_SCRATCH = 6;

    logic reg_we;
    logic [4:0] reg_addr;
    logic [31:0] reg_write;
    logic [31:0] regs [0:31];

    logic [31:0] if_pc;
    logic [31:0] if_pc_current;
    wire [31:0] if_instr;

    assign if_instr = fetch_read;

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

    logic id_branch_always;
    logic id_branch_if_eq;
    logic id_branch_if_ne;
    logic id_branch_if_lt;
    logic id_branch_if_ge;
    logic id_signed_compare;
    logic signed [31:0] id_branch_offset;
    logic [31:0] id_branch_target;

    always_comb begin
        id_branch_always = 0;
        id_branch_if_eq = 0;
        id_branch_if_ne = 0;
        id_branch_if_lt = 0;
        id_branch_if_ge = 0;
        id_signed_compare = (id_opcode == OP_BLT) || (id_opcode == OP_BGE);

        case (id_opcode)
            OP_B, OP_BR, OP_BL, OP_BLR, OP_ERET: id_branch_always = 1;
            OP_BEQ: id_branch_if_eq = 1;
            OP_BNE: id_branch_if_ne = 1;
            OP_BLT, OP_BLTU: id_branch_if_lt = 1;
            OP_BGE, OP_BGEU: id_branch_if_ge = 1;
        endcase

        case (id_opcode)
            OP_B: id_branch_offset = id_simm26;
            OP_BL: id_branch_offset = id_simm21;
            default: id_branch_offset = id_simm16;
        endcase
    end

    assign id_branch_target = id_pc + (id_branch_offset << 2);

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
    logic signed [31:0] ex_simm16;
    logic ex_branch_always;
    logic ex_branch_if_eq;
    logic ex_branch_if_ne;
    logic ex_branch_if_lt;
    logic ex_branch_if_ge;
    logic ex_signed_compare;
    logic [31:0] ex_branch_target;

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

    logic [31:0] wb_pc;
    logic [31:0] wb_instr;
    logic [31:0] wb_result;
    logic [31:0] wb_addr;
    opcode_t wb_opcode;
    logic [4:0] wb_reg_addr;

    logic [31:0] alu_left;
    logic [31:0] alu_right;
    alu_op_t alu_op;
    logic alu_start;
    logic [31:0] alu_result;
    logic alu_ready;

    alu alu0(
        .clk(clk),
        .rst(rst),
        .left(alu_left),
        .right(alu_right),
        .alu_op(alu_op),
        .start(alu_start),
        .result(alu_result),
        .ready(alu_ready)
    );

    logic is_multicycle_op, alu_active, alu_stall;
    assign is_multicycle_op = (ex_opcode == OP_MUL) || (ex_opcode == OP_MULH) || (ex_opcode == OP_MULHSU) || (ex_opcode == OP_MULHU) ||
        (ex_opcode == OP_DIV) || (ex_opcode == OP_DIVU) || (ex_opcode == OP_REM) || (ex_opcode == OP_REMU);
    assign alu_start = is_multicycle_op && !alu_active;
    assign alu_stall = is_multicycle_op && !alu_ready;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_active <= 1'b0;
        end else begin
            if (alu_start) begin
                alu_active <= 1'b1;
            end else if (alu_ready && !bus_stall) begin
                alu_active <= 1'b0;
            end
        end
    end

    function automatic logic is_load_op(opcode_t opcode);
        case (opcode)
            OP_LB, OP_LBU, OP_LH, OP_LHU, OP_LW: return 1;
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
            OP_CSRR, OP_ERET,
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

    function automatic logic writes_result(opcode_t opcode);
        case (opcode)
            OP_LUI, OP_AUIPC,
            OP_SLT, OP_SLTU, OP_SLTI, OP_SLTIU,
            OP_ADD, OP_ADDI, OP_SUB, OP_SUBI,
            OP_MUL, OP_MULH, OP_MULHSU, OP_MULHU, OP_DIV, OP_DIVU, OP_REM, OP_REMU,
            OP_AND, OP_ANDI, OP_OR, OP_ORI, OP_XOR, OP_XORI,
            OP_SLL, OP_SLLI, OP_SRL, OP_SRLI, OP_SRA, OP_SRAI,
            OP_BL, OP_BLR,
            OP_CSRR: return 1;
            default: return 0;
        endcase
    endfunction

    function automatic logic reads_register(opcode_t opcode, logic [31:0] instr, logic [4:0] register);
        return (reads_reg0(opcode) && instr[25:21] == register) || (reads_reg1(opcode) && instr[20:16] == register) || (reads_reg2(opcode) && instr[15:11] == register);
    endfunction

    function automatic logic [2:0] source_matches(logic [31:0] instr, logic [4:0] register);
        return (register == 0) ? 3'b000 : {instr[15:11] == register, instr[20:16] == register, instr[25:21] == register};
    endfunction

    logic mem_writes_reg;

    assign mem_writes_reg = writes_result(mem_opcode);

    logic [2:0] id_fwd_mem;
    logic [2:0] id_fwd_wb;
    logic [2:0] ex_fwd_mem;
    logic [2:0] ex_fwd_wb;

    assign id_fwd_mem = writes_result(ex_opcode) ? source_matches(id_instr, ex_reg_addr) : 3'b000;
    assign id_fwd_wb = mem_writes_reg ? source_matches(id_instr, mem_reg_addr) : 3'b000;

    logic [31:0] ex_reg0_fwd;
    logic [31:0] ex_reg1_fwd;
    logic [31:0] ex_reg2_fwd;

    assign ex_reg0_fwd = ex_fwd_mem[0] ? mem_result : (ex_fwd_wb[0] ? wb_result : ex_reg0);
    assign ex_reg1_fwd = ex_fwd_mem[1] ? mem_result : (ex_fwd_wb[1] ? wb_result : ex_reg1);
    assign ex_reg2_fwd = ex_fwd_mem[2] ? mem_result : (ex_fwd_wb[2] ? wb_result : ex_reg2);

    logic hazard_stall;

    assign hazard_stall = (is_load_op(ex_opcode) && (ex_reg_addr != 0) && reads_register(id_opcode, id_instr, ex_reg_addr)) ||
        (is_load_op(mem_opcode) && (mem_reg_addr != 0) && reads_register(id_opcode, id_instr, mem_reg_addr));

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

    logic [3:0] io_we;
    logic io_read;

    assign io_we = bus_stall ? 4'b0000 : mem_we;
    assign io_read = mem_access && mem_we == 0 && !bus_stall;

    logic [3:0] uart_we;
    logic [15:0] uart_clks_per_bit;

    logic uart_tx_busy;
    logic uart_tx_started;
    logic uart_tx_write;

    assign uart_tx_write = (mem_addr == 32'hFFFF) && (io_we != 0) && !uart_tx_busy && !uart_tx_started;

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
        .read_ack(mem_addr == 32'hFFFF && io_read),
        .rx_byte(uart_rx_byte),
        .rx_ready(uart_rx_ready)
    );

    localparam int UART_DEFAULT_BAUD_RATE = 115200;
    localparam int UART_DEFAULT_CLKS_PER_BIT = CLK_FREQ / UART_DEFAULT_BAUD_RATE;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            uart_clks_per_bit <= UART_DEFAULT_CLKS_PER_BIT;
        else if (mem_addr == 32'hFFF8 && io_we != 0)
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

    logic [31:0] cycle_counter;
    logic [31:0] instret_counter;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle_counter <= 0;
            instret_counter <= 0;
        end else begin
            cycle_counter <= cycle_counter + 32'd1;

            if (!bus_stall && wb_instr != 0)
                instret_counter <= instret_counter + 32'd1;
        end
    end

    logic [31:0] timer_compare;
    logic timer_pending;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            timer_compare <= 0;
            timer_pending <= 0;
        end else begin
            if (mem_addr == 32'hFFDC && io_we != 0)
                timer_compare <= mem_write;

            timer_pending <= $signed(cycle_counter - timer_compare) >= 0;
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
        else if (mem_addr == 32'hFFF0 && io_we != 0)
            leds <= mem_write[5:0];
    end

    ws2812_tx #(
        .CLK_FREQ(CLK_FREQ)
    ) ws2812_tx0 (
        .clk(clk),
        .rst(rst),
        .strobe(mem_addr == 32'hFFE0 && io_we != 0),
        .write(mem_write[23:0]),
        .busy(),
        .out(ws2812)
    );

    always_comb begin
        uart_we = 0;
        actual_mem_we = 0;

        if (mem_addr == 32'hFFFF)
            uart_we = io_we;
        else if (mem_addr != 32'hFFF0 && mem_addr != 32'hFFE0 && mem_addr != 32'hFFEC && mem_addr != 32'hFFF4 && mem_addr != 32'hFFF8 && mem_addr != 32'hFFE8 && mem_addr != 32'hFFE4 && mem_addr != 32'hFFDC)
            actual_mem_we = mem_we;
    end

    logic csr_ie;
    logic csr_pie;
    logic [31:0] csr_ienable;
    logic [31:0] csr_ipending;
    logic [31:0] csr_epc;
    logic [31:0] csr_cause;
    logic [31:0] csr_vector;
    logic [31:0] csr_scratch;
    logic [31:0] csr_read;
    logic take_interrupt;

    assign csr_ipending = {31'b0, timer_pending};
    assign take_interrupt = csr_ie && (csr_ipending & csr_ienable) != 0 && ex_instr != 0 && !is_multicycle_op && !halted;

    always_comb begin
        case (ex_imm16)
            CSR_STATUS: csr_read = {30'b0, csr_pie, csr_ie};
            CSR_IENABLE: csr_read = csr_ienable;
            CSR_IPENDING: csr_read = csr_ipending;
            CSR_EPC: csr_read = csr_epc;
            CSR_CAUSE: csr_read = csr_cause;
            CSR_VECTOR: csr_read = csr_vector;
            CSR_SCRATCH: csr_read = csr_scratch;
            default: csr_read = 0;
        endcase
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            csr_ie <= 0;
            csr_pie <= 0;
            csr_ienable <= 0;
            csr_epc <= 0;
            csr_cause <= 0;
            csr_vector <= 0;
            csr_scratch <= 0;
        end else if (!bus_stall) begin
            if (take_interrupt) begin
                csr_epc <= ex_pc;
                csr_cause <= 32'h80000000;
                csr_pie <= csr_ie;
                csr_ie <= 0;
            end else if (ex_opcode == OP_ERET) begin
                csr_ie <= csr_pie;
                csr_pie <= 1;
            end else if (ex_opcode == OP_CSRW) begin
                case (ex_imm16)
                    CSR_STATUS: {csr_pie, csr_ie} <= ex_reg1_fwd[1:0];
                    CSR_IENABLE: csr_ienable <= ex_reg1_fwd;
                    CSR_EPC: csr_epc <= ex_reg1_fwd;
                    CSR_CAUSE: csr_cause <= ex_reg1_fwd;
                    CSR_VECTOR: csr_vector <= ex_reg1_fwd;
                    CSR_SCRATCH: csr_scratch <= ex_reg1_fwd;
                    default: ;
                endcase
            end
        end
    end

    logic branch_eq;
    logic branch_lt;

    assign branch_eq = (ex_reg0_fwd == ex_reg1_fwd);
    assign branch_lt = $signed({ex_signed_compare & ex_reg0_fwd[31], ex_reg0_fwd}) < $signed({ex_signed_compare & ex_reg1_fwd[31], ex_reg1_fwd});
    assign should_take_branch = take_interrupt || ex_branch_always || (branch_eq ? ex_branch_if_eq : ex_branch_if_ne) ||
        (branch_lt ? ex_branch_if_lt : ex_branch_if_ge);

    always_comb begin
        branch_target = ex_branch_target;
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

            OP_BR: branch_target = ex_reg0_fwd;
            OP_BL: ex_result = ex_pc + 4;

            OP_BLR: begin
                ex_result = ex_pc + 4;
                branch_target = ex_reg1_fwd;
            end

            OP_CSRR: ex_result = csr_read;
            OP_ERET: branch_target = csr_epc;
            OP_HLT: should_halt = 1;
        endcase

        if (take_interrupt) begin
            branch_target = csr_vector;
            should_halt = 0;
        end
    end

    assign mem_addr = stage_mem_addr;
    assign fetch_addr = (hazard_stall || alu_stall) ? if_pc_current : if_pc;

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

    logic [31:0] io_read_word;
    logic io_read_hit;

    always_comb begin
        io_read_hit = 1;

        case (stage_mem_addr)
            32'hFFFF: io_read_word = {4{uart_rx_byte}};
            32'hFFFC: io_read_word = {30'b0, uart_tx_busy, uart_rx_ready};
            32'hFFF8: io_read_word = {16'b0, uart_clks_per_bit};
            32'hFFEC: io_read_word = ms_counter;
            32'hFFF4: io_read_word = {31'b0, button_sync1};
            32'hFFE8: io_read_word = cycle_counter;
            32'hFFE4: io_read_word = instret_counter;
            32'hFFDC: io_read_word = timer_compare;
            default: begin
                io_read_word = 0;
                io_read_hit = 0;
            end
        endcase
    end

    logic wb_writes;
    logic wb_load;
    logic wb_load_byte;
    logic wb_load_half;
    logic wb_load_signed;
    logic wb_io;
    logic [31:0] wb_io_word;

    logic [31:0] wb_read_word;
    logic [15:0] wb_read_half;
    logic [7:0] wb_read_byte;

    assign wb_read_word = wb_io ? wb_io_word : mem_read;
    assign wb_read_half = wb_read_word[16 * wb_addr[1]+:16];
    assign wb_read_byte = wb_read_word[8 * wb_addr[1:0]+:8];

    always_comb begin
        reg_addr = wb_reg_addr;
        reg_we = wb_writes;

        if (!wb_load)
            reg_write = wb_result;
        else if (wb_load_byte)
            reg_write = {{24{wb_load_signed & wb_read_byte[7]}}, wb_read_byte};
        else if (wb_load_half)
            reg_write = {{16{wb_load_signed & wb_read_half[15]}}, wb_read_half};
        else
            reg_write = wb_read_word;
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
            ex_simm16 <= 0;
            ex_branch_always <= 0;
            ex_branch_if_eq <= 0;
            ex_branch_if_ne <= 0;
            ex_branch_if_lt <= 0;
            ex_branch_if_ge <= 0;
            ex_signed_compare <= 0;
            ex_branch_target <= 0;
            ex_fwd_mem <= 0;
            ex_fwd_wb <= 0;

            halted <= 0;
            branch_taken <= 1;

            mem_pc <= 0;
            mem_instr <= 0;
            mem_result <= 0;
            stage_mem_addr <= 0;
            mem_opcode <= OP_NOP;
            mem_reg_addr <= 0;
            mem_reg0 <= 0;

            wb_pc <= 0;
            wb_instr <= 0;
            wb_result <= 0;
            wb_addr <= 0;
            wb_opcode <= OP_NOP;
            wb_reg_addr <= 0;
            wb_writes <= 0;
            wb_load <= 0;
            wb_load_byte <= 0;
            wb_load_half <= 0;
            wb_load_signed <= 0;
            wb_io <= 0;
            wb_io_word <= 0;
        end else if (!bus_stall) begin
            if (reg_we && reg_addr != 0)
                regs[reg_addr] <= reg_write;

            if (should_take_branch) begin
                if_pc <= branch_target;
                if_pc_current <= branch_target;
            end else if (halted) begin
                if_pc <= 0;
                if_pc_current <= 0;
            end else if (hazard_stall || alu_stall) begin
                if_pc <= if_pc;
                if_pc_current <= if_pc_current;
            end else begin
                if_pc <= if_pc + 4;
                if_pc_current <= if_pc;
            end

            if (!hazard_stall && !alu_stall)
                id_pc <= if_pc_current;

            if (should_take_branch || branch_taken || halted)
                id_instr <= 0;
            else if (!hazard_stall && !alu_stall)
                id_instr <= if_instr;

            if (!alu_stall) begin
                ex_pc <= id_pc;
                ex_reg0 <= id_reg0;
                ex_reg1 <= id_reg1;
                ex_reg2 <= id_reg2;
                ex_imm16 <= id_imm16;
                ex_imm21 <= id_imm21;
                ex_simm16 <= id_simm16;
                ex_signed_compare <= id_signed_compare;
                ex_branch_target <= id_branch_target;
                ex_fwd_mem <= id_fwd_mem;
                ex_fwd_wb <= id_fwd_wb;

                if (should_take_branch || hazard_stall || halted) begin
                    ex_instr <= 0;
                    ex_opcode <= OP_NOP;
                    ex_reg_addr <= 0;
                    ex_branch_always <= 0;
                    ex_branch_if_eq <= 0;
                    ex_branch_if_ne <= 0;
                    ex_branch_if_lt <= 0;
                    ex_branch_if_ge <= 0;
                end else begin
                    ex_instr <= id_instr;
                    ex_opcode <= id_opcode;
                    ex_reg_addr <= id_reg_addr;
                    ex_branch_always <= id_branch_always;
                    ex_branch_if_eq <= id_branch_if_eq;
                    ex_branch_if_ne <= id_branch_if_ne;
                    ex_branch_if_lt <= id_branch_if_lt;
                    ex_branch_if_ge <= id_branch_if_ge;
                end
            end

            if (should_halt)
                halted <= 1;

            branch_taken <= should_take_branch;

            if (alu_stall || take_interrupt) begin
                mem_pc <= 0;
                mem_instr <= 0;
                mem_result <= 0;
                stage_mem_addr <= 0;
                mem_opcode <= OP_NOP;
                mem_reg_addr <= 0;
                mem_reg0 <= 0;
            end else begin
                mem_pc <= ex_pc;
                mem_instr <= ex_instr;
                mem_result <= ex_result;
                stage_mem_addr <= ex_addr;
                mem_opcode <= ex_opcode;
                mem_reg_addr <= ex_reg_addr;
                mem_reg0 <= ex_reg0_fwd;
            end

            wb_pc <= mem_pc;
            wb_instr <= mem_instr;
            wb_result <= mem_result;
            wb_addr <= stage_mem_addr;
            wb_opcode <= mem_opcode;
            wb_reg_addr <= mem_reg_addr;
            wb_writes <= writes_result(mem_opcode) || is_load_op(mem_opcode);
            wb_load <= is_load_op(mem_opcode);
            wb_load_byte <= (mem_opcode == OP_LB) || (mem_opcode == OP_LBU);
            wb_load_half <= (mem_opcode == OP_LH) || (mem_opcode == OP_LHU);
            wb_load_signed <= (mem_opcode == OP_LB) || (mem_opcode == OP_LH);
            wb_io <= io_read_hit;
            wb_io_word <= io_read_word;

            if (halted && id_instr == 0 && ex_instr == 0 && mem_instr == 0 && wb_instr == 0)
                $finish;
        end
    end
endmodule
