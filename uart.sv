module uart(
    input logic clk,
    input logic [3:0] we,
    input logic [31:0] write
);

always_ff @(posedge clk) begin
    if (we[0]) $write("%c", write[7:0]);
    if (we[1]) $write("%c", write[15:8]);
    if (we[2]) $write("%c", write[23:16]);
    if (we[3]) $write("%c", write[31:24]);
end

endmodule