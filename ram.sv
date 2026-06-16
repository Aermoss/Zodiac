module ram(
    input logic clk,
    input logic we,
    input logic [31:0] addr,
    input logic [31:0] write,
    output logic [31:0] read
);

logic [31:0] mem [0:255];

assign read = mem[addr];

initial begin
    mem[0] = 32'h0000000A;
    mem[1] = 32'h00000002;
    mem[2] = 32'h00000004;
    mem[3] = 32'h0000000A;
    mem[4] = 32'h00000006;
    mem[5] = 32'h00000008;
    mem[6] = 32'h00000005;
    mem[7] = 32'h00000000;
    mem[8] = 32'h000000FF;
end

always @(posedge clk) begin
    if (we)
        mem[addr] <= write;
end

endmodule