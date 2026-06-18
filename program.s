ldi x31, 0xFFF

loop:
    subi x31, x31, 1
    st x1, 0(x31)
    addi x1, x1, 2
    ld x1, 0(x31)
    addi x31, x31, 1
    cmpi x1, 10
    jz exit
    j loop

exit:
    hlt