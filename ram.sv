module ram(
    input logic clk,
    input logic we,
    input logic [7:0] addr,
    input logic [7:0] write,
    output logic [7:0] read
);

logic [7:0] mem [0:255];

assign read = mem[addr];

initial begin
    mem[0] = 8'h0A;
    mem[1] = 8'h02;
    mem[2] = 8'h04;
    mem[3] = 8'h0A;
    mem[4] = 8'h06;
    mem[5] = 8'h08;
    mem[6] = 8'h05;
    mem[7] = 8'h00;
    mem[8] = 8'hFF;
end

always @(posedge clk) begin
    if (we)
        mem[addr] <= write;
end

endmodule