module cpu(
    input logic clk,
    input logic reset
);

logic [7:0] pc;
logic [7:0] instruction;
logic [7:0] acc;

pc pc0(
    .clk(clk),
    .reset(reset),
    .pc(pc)
);

ram ram0(
    .clk(clk),
    .we(1'b0),
    .addr(pc),
    .wdata(8'h00),
    .rdata(instruction)
);

endmodule