module ram #(
    parameter BYTE_DEPTH = 16384
)(
    input logic clk,
    input logic [3:0] we,
    input logic [31:0] addr,
    input logic [31:0] write,
    output logic [31:0] read = 0
);

logic [7:0] mem [0:BYTE_DEPTH - 1];

initial begin
    $readmemh("program.hex", mem);
end

always_ff @(posedge clk) begin
    if (addr + 3 < BYTE_DEPTH) begin
        read[7:0] <= mem[addr];
        read[15:8] <= mem[addr + 1];
        read[23:16] <= mem[addr + 2];
        read[31:24] <= mem[addr + 3];
    end
end

always_ff @(posedge clk) begin
    if (addr + 3 < BYTE_DEPTH) begin
        if (we[0]) mem[addr] <= write[7:0];
        if (we[1]) mem[addr + 1] <= write[15:8];
        if (we[2]) mem[addr + 2] <= write[23:16];
        if (we[3]) mem[addr + 3] <= write[31:24];
    end
end

endmodule