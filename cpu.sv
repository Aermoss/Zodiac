module cpu(
    input logic clk,
    input logic reset
);

typedef enum logic [7:0] {
    OP_NOP,
    OP_INC,
    OP_DEC,
    OP_LDI,
    OP_LD,
    OP_ST,
    OP_J,
    OP_ADD,
    OP_SUB,
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
logic [7:0] pc;
state_t state;

opcode_t instr;
logic [7:0] operand;
logic [7:0] acc;

logic ram_we;
logic [7:0] ram_addr;
logic [7:0] ram_write;
logic [7:0] ram_read;

ram ram0(
    .clk(clk),
    .we(ram_we),
    .addr(ram_addr),
    .write(ram_write),
    .read(ram_read)
);

logic [7:0] alu_left;
logic [7:0] alu_right;
alu_op_t alu_op;
logic [7:0] alu_result;
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

        operand <= 0;
        instr <= OP_NOP;
        acc <= 0;

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
                instr <= opcode_t'(ram_read);

                case (ram_read)
                    OP_LDI, OP_LD, OP_ST, OP_J, OP_ADD, OP_SUB: begin
                        ram_addr <= pc + 1;
                        state <= S_FETCH_OPERAND;
                    end

                    default: begin 
                        state <= S_EXECUTE;
                    end
                endcase
            end

            S_FETCH_OPERAND: begin
                operand <= ram_read;

                case (instr)
                    OP_LD: begin
                        ram_addr <= ram_read;
                    end

                    OP_ST: begin
                        ram_we <= 1;
                        ram_addr <= ram_read;
                        ram_write <= acc;
                    end
                endcase

                state <= S_EXECUTE;
            end

            S_EXECUTE: begin
                case (instr)
                    OP_INC: begin
                        alu_op <= ALU_OP_INC;
                        alu_left <= acc;
                        state <= S_WRITEBACK;
                        pc <= pc + 1;
                    end

                    OP_DEC: begin
                        alu_op <= ALU_OP_DEC;
                        alu_left <= acc;
                        state <= S_WRITEBACK;
                        pc <= pc + 1;
                    end

                    OP_LDI: begin
                        acc <= operand;
                        state <= S_FETCH;
                        pc <= pc + 2;
                    end

                    OP_LD: begin
                        acc <= ram_read;
                        state <= S_FETCH;
                        pc <= pc + 2;
                    end

                    OP_ST: begin
                        ram_we <= 0;
                        state <= S_FETCH;
                        pc <= pc + 2;
                    end

                    OP_J: begin
                        state <= S_FETCH;
                        pc <= operand;
                    end

                    OP_ADD: begin
                        alu_op <= ALU_OP_ADD;
                        alu_left <= acc;
                        alu_right <= operand;
                        state <= S_WRITEBACK;
                        pc <= pc + 2;
                    end

                    OP_SUB: begin
                        alu_op <= ALU_OP_SUB;
                        alu_left <= acc;
                        alu_right <= operand;
                        state <= S_WRITEBACK;
                        pc <= pc + 2;
                    end

                    OP_HLT: begin
                        halted <= 1;
                    end
                endcase
            end

            S_WRITEBACK: begin
                acc <= alu_result;
                state <= S_FETCH;
            end
        endcase
    end
end

endmodule