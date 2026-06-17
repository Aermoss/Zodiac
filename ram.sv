module ram(
    input logic clk,
    input logic we,
    input logic [31:0] addr,
    input logic [31:0] write,
    output logic [31:0] read = 0
);

logic [31:0] mem [0:4095];

initial begin
    mem[0] = 32'h02F80FFF;
    mem[1] = 32'h15FFC001;
    mem[2] = 32'h030FC000;
    mem[3] = 32'h14084002;
    mem[4] = 32'h010FC000;
    mem[5] = 32'h14FFC001;
    mem[6] = 32'h0508000A;
    mem[7] = 32'h07000009;
    mem[8] = 32'h06000001;
    mem[9] = 32'hFF000000;
end

always_ff @(posedge clk) begin
    if (we)
        mem[addr] <= write;
    else
        read <= mem[addr];
end

endmodule