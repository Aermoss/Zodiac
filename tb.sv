`timescale 1ns/1ps

module tb;

logic clk = 0;
logic reset = 1;
integer i;

cpu cpu0(
    .clk(clk),
    .reset(reset)
);

always #3 clk = ~clk;

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);

    for (i = 0; i < 32; i++)
        $dumpvars(0, cpu0.regs[i]);

    @(negedge clk);
    reset = 0;
    #1000;

    $finish;
end

endmodule