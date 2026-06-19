li x31, 0x4000
bl x30, print
li x1, 0
li x2, 10

loop:
    addi x1, x1, 2
    beq x1, x2, exit
    b loop

print:
    subi x31, x31, 4
    sw x30, 0(x31)

    li x2, 0xFFFF
    li x1, 90
    sb x1, 0(x2)
    li x1, 79
    sb x1, 0(x2)
    li x1, 68
    sb x1, 0(x2)
    li x1, 73
    sb x1, 0(x2)
    li x1, 65
    sb x1, 0(x2)
    li x1, 67
    sb x1, 0(x2)
    li x1, 32
    sb x1, 0(x2)

    bl x30, other

    li x1, 10
    sb x1, 0(x2)

    lw x30, 0(x31)
    addi x31, x31, 4
    br x30

other:
    subi x31, x31, 4
    sw x30, 0(x31)

    li x2, 0xFFFF
    li x1, 84
    sb x1, 0(x2)
    li x1, 69
    sb x1, 0(x2)
    li x1, 83
    sb x1, 0(x2)
    li x1, 84
    sb x1, 0(x2)

    lw x30, 0(x31)
    addi x31, x31, 4
    br x30

exit:
    hlt