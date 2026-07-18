.text
.global boot

boot:
    li x1, 0x80100000
    li x2, 0x40000000
    li x3, 0x00001000

copy:
    lw x4, 0(x1)
    sw x4, 0(x2)
    addi x1, x1, 4
    addi x2, x2, 4
    subi x3, x3, 4
    bnez x3, copy
    li x5, 0x40000000
    br x5
