module ram #(
    parameter BYTE_DEPTH = 16384
)(
    input logic clk,
    input logic [3:0] we,
    input logic [31:0] addr,
    input logic [31:0] write,
    output logic [31:0] read
);

localparam WORD_DEPTH = BYTE_DEPTH / 4;

logic [31:0] mem [0:WORD_DEPTH - 1];

wire [$clog2(WORD_DEPTH) - 1:0] word_addr;

assign word_addr = addr[31:2];

initial begin
    $readmemh("program.hex", mem);
end

always_ff @(posedge clk) begin
    if (word_addr < WORD_DEPTH) begin
        read <= mem[word_addr];

        if (we[0]) mem[word_addr][7:0] <= write[7:0];
        if (we[1]) mem[word_addr][15:8] <= write[15:8];
        if (we[2]) mem[word_addr][23:16] <= write[23:16];
        if (we[3]) mem[word_addr][31:24] <= write[31:24];
    end
end

endmodule