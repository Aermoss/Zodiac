module cpu(
    input logic clk,
    input logic reset
);

typedef enum logic [1:0] {
    FETCH,
    DECODE,
    MEMORY,
    EXECUTE
} state_t;

logic halted;
logic [7:0] next;
logic [7:0] pc;
state_t state;

logic [7:0] instruction;
logic [7:0] acc;

logic ram_we = 0;
logic [7:0] ram_addr;
logic [7:0] ram_write;
logic [7:0] ram_read;

pc pc0(
    .clk(clk),
    .reset(reset),
    .next(next),
    .pc(pc)
);

ram ram0(
    .clk(clk),
    .we(ram_we),
    .addr(ram_addr),
    .wdata(ram_write),
    .rdata(ram_read)
);

always @(*) begin
    next = pc;

    if (state == EXECUTE) begin
        case (instruction)
            8'hFF: next = pc;
            8'h03, 8'h04, 8'h05: next = pc + 2;
            default: next = pc + 1;
        endcase
    end
end

always @(posedge clk) begin
    if (reset) begin
        halted <= 0;
        state <= FETCH;
        acc <= 0;
    end

    else if (!halted) begin
        case (state)
            FETCH: begin
                ram_addr <= pc;
                state <= DECODE;
            end

            DECODE: begin
                instruction <= ram_read;

                case (ram_read)
                    8'h03, 8'h04, 8'h05:
                        ram_addr <= pc + 1;
                endcase

                case (ram_read)
                    8'h04, 8'h05: state <= MEMORY;
                    default: state <= EXECUTE;
                endcase
            end

            MEMORY: begin
                case (instruction)
                    8'h04: begin
                        ram_addr <= ram_read;
                        state <= EXECUTE;
                    end

                    8'h05: begin
                        ram_we <= 1;
                        ram_addr <= ram_read;
                        ram_write <= acc;
                        state <= EXECUTE;
                    end
                endcase
            end

            EXECUTE: begin
                case (instruction)
                    8'h01: acc <= acc + 1;
                    8'h02: acc <= acc - 1;
                    8'h03, 8'h04: acc <= ram_read;
                    8'h05: ram_we <= 0;
                    8'hFF: halted <= 1;
                endcase

                state <= FETCH;
            end
        endcase
    end
end

endmodule