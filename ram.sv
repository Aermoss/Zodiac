module ram(
    input logic clk,
    input logic we,
    input logic [31:0] addr,
    input logic [31:0] write,
    output logic [31:0] read = 0
);

logic [31:0] mem [0:4095];

initial begin
    $readmemh("program.hex", mem);
end

always_ff @(posedge clk) begin
    if (we)
        mem[addr] <= write;
    else
        read <= mem[addr];
end

endmodule