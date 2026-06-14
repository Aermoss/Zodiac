module cpu(
    input logic clk,
    input logic reset
);

logic halted;
logic [7:0] next;
logic [7:0] pc;
logic [7:0] instruction;
logic [7:0] acc;

pc pc0(
    .clk(clk),
    .reset(reset),
    .next(next),
    .pc(pc)
);

ram ram0(
    .clk(clk),
    .we(1'b0),
    .addr(pc),
    .wdata(8'h00),
    .rdata(instruction)
);

always @(*) begin
    if (halted)
        next = pc;
    else begin
        case (instruction)
            8'hFF: next = pc;
            default: next = pc + 1;
        endcase
    end
end

always @(posedge clk) begin
    if (reset) begin
        halted <= 0;
        acc <= 0;
    end

    else if (!halted) begin
        case (instruction)
            8'h01: acc <= acc + 1;
            8'h02: acc <= acc - 1;
            8'hFF: halted <= 1;
        endcase
    end
end

endmodule