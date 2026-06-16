module ram(
    input logic clk,
    input logic we,
    input logic [31:0] addr,
    input logic [31:0] write,
    output logic [31:0] read
);

logic [31:0] mem [0:4095];

assign read = mem[addr];

initial begin
    mem[0] = 32'h13000002;
    mem[1] = 32'h0500000A;
    mem[2] = 32'h07000004;
    mem[3] = 32'h06000000;
    mem[4] = 32'hFF000000;
end

always_ff @(posedge clk) begin
    if (we)
        mem[addr] <= write;
end

endmodule