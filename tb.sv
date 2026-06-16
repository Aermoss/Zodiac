`timescale 1ns/1ps

module tb;

logic clk = 0;
logic reset = 1;

cpu dut(
    .clk(clk),
    .reset(reset)
);

always #3 clk = ~clk;

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);

    @(negedge clk);
    reset = 0;
    #1000;

    $finish;
end

endmodule