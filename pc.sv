module pc(
    input logic clk,
    input logic reset,
    input logic [7:0] next,
    output logic [7:0] pc
);

always @(posedge clk) begin
    if (reset)
        pc <= 0;
    else
        pc <= next;
end

endmodule