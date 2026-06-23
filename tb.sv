`timescale 1ns/1ps

module tb;

logic reset;
logic clk = 0;
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

    reset = 1;
    @(negedge clk);
    reset = 0;
end

endmodule