ldi x0, 10
ldi x1, 0
ldi x2, 2

loop:
    add x1, x1, x2
    cmp x0, x1
    jz exit
    j loop

exit:
    hlt