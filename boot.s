.text
.global boot

boot:
    li t0, 0x80100000
    li t1, 0x40000000
    lw t2, 4(t0)
    sub t2, t2, t1
    blez t2, fail
    li t3, 0x700000
    bgtu t2, t3, fail

copy:
    lw t3, 0(t0)
    sw t3, 0(t1)
    addi t0, t0, 4
    addi t1, t1, 4
    subi t2, t2, 4
    bgtz t2, copy
    li t4, 0x40000000
    br t4

fail:
    li t4, 0x2A
    li t5, 0xFFF0
    sw t4, 0(t5)
    hlt
