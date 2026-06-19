bl x30, print
ldi x31, 0xFFF
ldi x1, 0
ldi x2, 10

loop:
    addi x1, x1, 2
    beq x1, x2, exit
    b loop

print:
    ldi x3, 0xFFFF
    ldi x1, 90
    st x1, 0(x3)
    ldi x1, 79
    st x1, 0(x3)
    ldi x1, 68
    st x1, 0(x3)
    ldi x1, 73
    st x1, 0(x3)
    ldi x1, 65
    st x1, 0(x3)
    ldi x1, 67
    st x1, 0(x3)
    ldi x1, 10
    st x1, 0(x3)
    br x30

exit:
    hlt