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
    mem[0] = 32'h0100000A;
    mem[1] = 32'h01080000;
    mem[2] = 32'h01100002;
    mem[3] = 32'h0A084400;
    mem[4] = 32'h04004000;
    mem[5] = 32'h06000007;
    mem[6] = 32'h05000003;
    mem[7] = 32'hFF000000;
end

always @(posedge clk) begin
    if (we)
        mem[addr] <= write;
end

endmodule