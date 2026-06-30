	.global	putchar
putchar:
    addi x31, x31, -8
    sb x1, 7(x31)
	;APP
    lui x21, 31
    ori x21, x21, 2047

    sb x1, 0(x21)

	;NO_APP
    addi x31, x31, 8
    br x30

	.global	print
print:
    addi x31, x31, -8
    sw x30, 4(x31)
    sw x1, 0(x31)
    b __LBB1_1
__LBB1_1:
    lw x1, 0(x31)
    lbu x1, 0(x1)
    add x2, x0, x0
    beq x1, x2, __LBB1_3
    b __LBB1_2
__LBB1_2:
    lw x1, 0(x31)
    lbu x1, 0(x1)
    bl x30, putchar
    lw x1, 0(x31)
    addi x1, x1, 1
    sw x1, 0(x31)
    b __LBB1_1
__LBB1_3:
    lw x30, 4(x31)
    addi x31, x31, 8
    br x30

	.global	print_int
print_int:
    addi x31, x31, -16
    sw x30, 12(x31)
    add x2, x1, x0
    sw x2, 8(x31)
    addi x1, x0, -1
    blt x1, x2, __LBB2_2
    b __LBB2_1
__LBB2_1:
    addi x1, x0, 45
    bl x30, putchar
    lw x2, 8(x31)
    add x1, x0, x0
    sub x1, x1, x2
    bl x30, print_int
    b __LBB2_3
__LBB2_2:
    lw x2, 8(x31)
    addi x1, x0, 9
    blt x1, x2, __LBB2_4
    b __LBB2_5
__LBB2_3:
    lw x30, 12(x31)
    addi x31, x31, 16
    br x30
__LBB2_4:
    lw x1, 8(x31)
    lui x2, 838860
    ori x2, x2, 1639
    sw x2, 4(x31)
    mulh x1, x1, x2
    srli x2, x1, 31
    srai x1, x1, 2
    add x1, x1, x2
    bl x30, print_int
    lw x2, 4(x31)
    lw x1, 8(x31)
    mulh x2, x1, x2
    srli x3, x2, 31
    srai x2, x2, 2
    add x2, x2, x3
    addi x3, x0, 10
    mul x2, x2, x3
    sub x1, x1, x2
    addi x1, x1, 48
    bl x30, putchar
    b __LBB2_6
__LBB2_5:
    lbu x1, 8(x31)
    addi x1, x1, 48
    bl x30, putchar
    b __LBB2_6
__LBB2_6:
    b __LBB2_3

	.global	factorial
factorial:
    addi x31, x31, -8
    sw x30, 4(x31)
    add x2, x1, x0
    sw x2, 0(x31)
    addi x1, x0, 1
    blt x1, x2, __LBB3_2
    b __LBB3_1
__LBB3_1:
    addi x1, x0, 1
    lw x30, 4(x31)
    addi x31, x31, 8
    br x30
__LBB3_2:
    lw x1, 0(x31)
    addi x1, x1, -1
    bl x30, factorial
    add x2, x1, x0
    lw x1, 0(x31)
    mul x1, x1, x2
    lw x30, 4(x31)
    addi x31, x31, 8
    br x30

	.global	fibonacci
fibonacci:
    addi x31, x31, -16
    sw x30, 12(x31)
    add x2, x1, x0
    sw x2, 8(x31)
    addi x1, x0, 1
    blt x1, x2, __LBB4_2
    b __LBB4_1
__LBB4_1:
    lw x1, 8(x31)
    lw x30, 12(x31)
    addi x31, x31, 16
    br x30
__LBB4_2:
    lw x1, 8(x31)
    addi x1, x1, -1
    bl x30, fibonacci
    sw x1, 4(x31)
    lw x1, 8(x31)
    addi x1, x1, -2
    bl x30, fibonacci
    add x2, x1, x0
    lw x1, 4(x31)
    add x1, x1, x2
    lw x30, 12(x31)
    addi x31, x31, 16
    br x30

	.global	main
main:
    addi x31, x31, -8
    sw x30, 4(x31)
    la x1, .L__unnamed_1
    bl x30, print
    la x1, .L__unnamed_2
    bl x30, print
    addi x1, x0, 5
    bl x30, factorial
    bl x30, print_int
    la x1, .L__unnamed_3
    bl x30, print
    la x1, .L__unnamed_4
    bl x30, print
    addi x1, x0, 8
    bl x30, fibonacci
    bl x30, print_int
    la x1, .L__unnamed_5
    bl x30, print
    add x1, x0, x0
    lw x30, 4(x31)
    addi x31, x31, 8
    br x30

.L__unnamed_1:
	.string	"Hello, World!\n"

.L__unnamed_2:
	.string	"factorial(5) = "

.L__unnamed_3:
	.string	"\n"

.L__unnamed_4:
	.string	"fibonacci(8) = "

.L__unnamed_5:
	.string	"\n"
