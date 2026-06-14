module pc(
    input logic clk,
    input logic reset,
    output logic [7:0] pc
);

always @(posedge clk) begin
    if (reset)
        pc <= 0;
    else
        pc <= pc + 1;
end

endmodule