module cpu(
    input logic clk,
    input logic reset
);

typedef enum logic [1:0] {
    FETCH,
    DECODE,
    FETCH_OPERAND,
    EXECUTE
} state_t;

logic halted;
logic [7:0] pc;
state_t state;

logic [7:0] instr;
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

always @(posedge clk) begin
    if (reset) begin
        halted <= 0;
        state <= FETCH;
        pc <= 0;

        instr <= 0;
        operand <= 0;
        acc <= 0;

        ram_we <= 0;
        ram_addr <= 0;
        ram_write <= 0;
    end

    else if (!halted) begin
        case (state)
            FETCH: begin
                ram_addr <= pc;
                state <= DECODE;
            end

            DECODE: begin
                instr <= ram_read;

                case (ram_read)
                    8'h03, 8'h04, 8'h05, 8'h06: begin
                        ram_addr <= pc + 1;
                        state <= FETCH_OPERAND;
                    end

                    default: begin 
                        state <= EXECUTE;
                    end
                endcase
            end

            FETCH_OPERAND: begin
                operand <= ram_read;

                case (instr)
                    8'h04: begin
                        ram_addr <= ram_read;
                    end

                    8'h05: begin
                        ram_we <= 1;
                        ram_addr <= ram_read;
                        ram_write <= acc;
                    end
                endcase

                state <= EXECUTE;
            end

            EXECUTE: begin
                case (instr)
                    8'h01: acc <= acc + 1;
                    8'h02: acc <= acc - 1;
                    8'h03: acc <= operand;
                    8'h04: acc <= ram_read;
                    8'h05: ram_we <= 0;
                    8'hFF: halted <= 1;
                endcase

                case (instr)
                    8'hFF: pc <= pc;
                    8'h03, 8'h04, 8'h05: pc <= pc + 2;
                    8'h06: pc <= operand;
                    default: pc <= pc + 1;
                endcase

                state <= FETCH;
            end
        endcase
    end
end

endmodule