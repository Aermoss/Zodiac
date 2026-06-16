loop:
    addi x0, x0, 2
    cmpi x0, 10
    jz exit
    j loop

exit:
    hlt