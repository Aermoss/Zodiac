st x1, 0x31

loop:
    ldi x1, 0
    ld x1, 0x31
    addi x1, x1, 2
    st x1, 0x31
    cmpi x1, 10
    jz exit
    j loop

exit:
    hlt