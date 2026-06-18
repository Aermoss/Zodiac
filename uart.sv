module uart(
    input logic clk,
    input logic we,
    input logic [31:0] write
);

always_ff @(posedge clk) begin
    if (we)
        $write("%c", write[7:0]);
end

endmodule