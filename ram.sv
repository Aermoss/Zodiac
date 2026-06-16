module ram(
    input logic clk,
    input logic we,
    input logic [31:0] addr,
    input logic [31:0] write,
    output logic [31:0] read = 0
);

logic [31:0] mem [0:4095];

initial begin
    mem[0] = 32'h03080031;
    mem[1] = 32'h02080000;
    mem[2] = 32'h01080031;
    mem[3] = 32'h13084002;
    mem[4] = 32'h03080031;
    mem[5] = 32'h0508000A;
    mem[6] = 32'h07000008;
    mem[7] = 32'h06000001;
    mem[8] = 32'hFF000000;
end

always_ff @(posedge clk) begin
    if (we)
        mem[addr] <= write;
    else
        read <= mem[addr];
end

endmodule