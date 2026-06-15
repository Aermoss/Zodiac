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
    mem[2] = 8'h02;
    mem[3] = 8'h03;
    mem[4] = 8'h31;
    mem[5] = 8'h05;
    mem[6] = 8'h10;
    mem[7] = 8'h04;
    mem[8] = 8'h10;
    mem[9] = 8'hFF;
end

always @(posedge clk) begin
    if (we)
        mem[addr] <= wdata;
end

endmodule