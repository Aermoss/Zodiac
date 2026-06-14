`timescale 1ns/1ps

module tb;

logic clk = 0;
logic d;
logic q;

dff dut(
    .clk(clk),
    .d(d),
    .q(q)
);

always #3 clk = ~clk;

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);

    $monitor("t=%0t d=%0d q=%0d clk=%0d", $time, d, q, clk);

    d = 0;
    #10;

    d = 1;
    #10;

    d = 0;
    #10;

    $finish;
end

endmodule