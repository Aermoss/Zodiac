.text
.global main

fibonacci:
    addi x31, x31, -16
    sw x30, 12(x31)
    sw x1, 4(x31)
    lw x2, 4(x31)
    add x1, x0, x0
    blt x1, x2, __LBB0_2
    b __LBB0_1
__LBB0_1:
    add x1, x0, x0
    sw x1, 8(x31)
    b __LBB0_5
__LBB0_2:
    lw x1, 4(x31)
    addi x2, x0, 1
    bne x1, x2, __LBB0_4
    b __LBB0_3
__LBB0_3:
    addi x1, x0, 1
    sw x1, 8(x31)
    b __LBB0_5
__LBB0_4:
    lw x1, 4(x31)
    addi x1, x1, -1
    bl x30, fibonacci
    sw x1, 0(x31)
    lw x1, 4(x31)
    addi x1, x1, -2
    bl x30, fibonacci
    add x2, x1, x0
    lw x1, 0(x31)
    add x1, x1, x2
    sw x1, 8(x31)
    b __LBB0_5
__LBB0_5:
    lw x1, 8(x31)
    lw x30, 12(x31)
    addi x31, x31, 16
    br x30

factorial:
    addi x31, x31, -16
    sw x30, 12(x31)
    sw x1, 4(x31)
    lw x2, 4(x31)
    addi x1, x0, 1
    blt x1, x2, __LBB1_2
    b __LBB1_1
__LBB1_1:
    addi x1, x0, 1
    sw x1, 8(x31)
    b __LBB1_3
__LBB1_2:
    lw x1, 4(x31)
    sw x1, 0(x31)
    addi x1, x1, -1
    bl x30, factorial
    add x2, x1, x0
    lw x1, 0(x31)
    mul x1, x1, x2
    sw x1, 8(x31)
    b __LBB1_3
__LBB1_3:
    lw x1, 8(x31)
    lw x30, 12(x31)
    addi x31, x31, 16
    br x30

putchar:
    addi x31, x31, -8
    sb x1, 7(x31)
    lbu x1, 7(x31)
	;APP
    li x21, 65535

    sb x1, 0(x21)

	;NO_APP
    addi x31, x31, 8
    br x30

print:
    addi x31, x31, -8
    sw x30, 4(x31)
    sw x1, 0(x31)
    b __LBB3_1
__LBB3_1:
    lw x1, 0(x31)
    lb x1, 0(x1)
    add x2, x0, x0
    beq x1, x2, __LBB3_3
    b __LBB3_2
__LBB3_2:
    lw x1, 0(x31)
    lbu x1, 0(x1)
    bl x30, putchar
    lw x1, 0(x31)
    addi x1, x1, 1
    sw x1, 0(x31)
    b __LBB3_1
__LBB3_3:
    lw x30, 4(x31)
    addi x31, x31, 8
    br x30

print_int:
    addi x31, x31, -8
    sw x30, 4(x31)
    sw x1, 0(x31)
    lw x1, 0(x31)
    addi x2, x0, 10
    blt x1, x2, __LBB4_2
    b __LBB4_1
__LBB4_1:
    lw x1, 0(x31)
    lui x2, 838860
    ori x2, x2, 1639
    mulh x1, x1, x2
    srli x2, x1, 31
    srai x1, x1, 2
    add x1, x1, x2
    bl x30, print_int
    b __LBB4_2
__LBB4_2:
    lw x1, 0(x31)
    lui x2, 838860
    ori x2, x2, 1639
    mulh x2, x1, x2
    srli x3, x2, 31
    srli x2, x2, 2
    add x2, x2, x3
    addi x3, x0, 10
    mul x2, x2, x3
    sub x1, x1, x2
    addi x1, x1, 48
    andi x1, x1, 255
    bl x30, putchar
    lw x30, 4(x31)
    addi x31, x31, 8
    br x30

main:
    addi x31, x31, -16
    sw x30, 12(x31)
    add x1, x0, x0
    sw x1, 4(x31)
    sw x1, 8(x31)
    la x1, .L.str
    bl x30, print
    addi x1, x0, 5
    bl x30, factorial
    bl x30, print_int
    addi x1, x0, 10
    sw x1, 0(x31)
    bl x30, putchar
    addi x1, x0, 8
    bl x30, fibonacci
    bl x30, print_int
    lw x1, 0(x31)
    bl x30, putchar
    lw x1, 4(x31)
    lw x30, 12(x31)
    addi x31, x31, 16
    br x30

.L.str:
	.string	"ZODIAC TEST\n"