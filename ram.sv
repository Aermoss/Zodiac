module ram(
    input logic clk,
    input logic we,
    input logic [7:0] addr,
    input logic [7:0] wdata,
    output logic [7:0] rdata
);

logic [7:0] mem [0:255];

assign rdata = mem[addr];

initial begin
    mem[0] = 8'h01;
    mem[1] = 8'h01;
    mem[2] = 8'h01;
    mem[3] = 8'hFF;
end

always @(posedge clk) begin
    if (we)
        mem[addr] <= wdata;
end

endmodule