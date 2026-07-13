	.text
	.global	__z14WriteCharacterc
__z14WriteCharacterc:
    addi x31, x31, -8
    sb x1, 7(x31)
    b __LBB0_1
__LBB0_1:
    lui x1, 31
    ori x1, x1, 2044
    lbu x1, 0(x1)
    andi x1, x1, 2
    add x2, x0, x0
    beq x1, x2, __LBB0_3
    b __LBB0_2
__LBB0_2:
    b __LBB0_1
__LBB0_3:
    lbu x1, 7(x31)
    lui x2, 31
    ori x2, x2, 2047
    sb x1, 0(x2)
    addi x31, x31, 8
    br x30

	.global	__z5WritePc
__z5WritePc:
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
    bl x30, __z14WriteCharacterc
    lw x1, 0(x31)
    addi x1, x1, 1
    sw x1, 0(x31)
    b __LBB1_1
__LBB1_3:
    lw x30, 4(x31)
    addi x31, x31, 8
    br x30

	.global	__z9WriteLinePc
__z9WriteLinePc:
    addi x31, x31, -8
    sw x30, 4(x31)
    sw x1, 0(x31)
    bl x30, __z5WritePc
    addi x1, x0, 10
    bl x30, __z14WriteCharacterc
    lw x30, 4(x31)
    addi x31, x31, 8
    br x30

	.global	__z12WriteIntegeri
__z12WriteIntegeri:
    addi x31, x31, -8
    sw x30, 4(x31)
    add x2, x1, x0
    sw x2, 0(x31)
    addi x1, x0, -1
    blt x1, x2, __LBB3_2
    b __LBB3_1
__LBB3_1:
    addi x1, x0, 45
    bl x30, __z14WriteCharacterc
    lw x2, 0(x31)
    add x1, x0, x0
    sub x1, x1, x2
    sw x1, 0(x31)
    b __LBB3_2
__LBB3_2:
    lw x1, 0(x31)
    addi x2, x0, 10
    blt x1, x2, __LBB3_4
    b __LBB3_3
__LBB3_3:
    lw x1, 0(x31)
    lui x2, 838860
    ori x2, x2, 1639
    mulh x1, x1, x2
    srli x2, x1, 31
    srai x1, x1, 2
    add x1, x1, x2
    bl x30, __z12WriteIntegeri
    b __LBB3_4
__LBB3_4:
    lw x1, 0(x31)
    lui x2, 838860
    ori x2, x2, 1639
    mulh x2, x1, x2
    srli x3, x2, 31
    srai x2, x2, 2
    add x2, x2, x3
    addi x3, x0, 10
    mul x2, x2, x3
    sub x1, x1, x2
    addi x1, x1, 48
    bl x30, __z14WriteCharacterc
    lw x30, 4(x31)
    addi x31, x31, 8
    br x30

	.global	__z12WriteIntegeri.1
__z12WriteIntegeri.1:
    addi x31, x31, -8
    sw x30, 4(x31)
    sw x1, 0(x31)
    addi x2, x0, 10
    bltu x1, x2, __LBB4_2
    b __LBB4_1
__LBB4_1:
    lw x1, 0(x31)
    lui x2, 1677721
    ori x2, x2, 1229
    mulhu x1, x1, x2
    srli x1, x1, 3
    bl x30, __z12WriteIntegeri.1
    b __LBB4_2
__LBB4_2:
    lw x1, 0(x31)
    lui x2, 1677721
    ori x2, x2, 1229
    mulhu x2, x1, x2
    srli x2, x2, 3
    addi x3, x0, 10
    mul x2, x2, x3
    sub x1, x1, x2
    ori x1, x1, 48
    bl x30, __z14WriteCharacterc
    lw x30, 4(x31)
    addi x31, x31, 8
    br x30

	.global	__z16WriteHexadecimali
__z16WriteHexadecimali:
    addi x31, x31, -16
    sw x30, 12(x31)
    sw x1, 0(x31)
    la x1, .L__unnamed_1
    bl x30, __z5WritePc
    addi x1, x0, 7
    sw x1, 4(x31)
    b __LBB5_1
__LBB5_1:
    lw x1, 4(x31)
    slli x2, x1, 2
    lw x1, 0(x31)
    srl x1, x1, x2
    andi x1, x1, 15
    sb x1, 11(x31)
    addi x2, x0, 10
    bltu x1, x2, __LBB5_3
    b __LBB5_4
__LBB5_2:
    lw x30, 12(x31)
    addi x31, x31, 16
    br x30
__LBB5_3:
    lbu x1, 11(x31)
    addi x1, x1, 48
    bl x30, __z14WriteCharacterc
    b __LBB5_5
__LBB5_4:
    lbu x1, 11(x31)
    addi x1, x1, 55
    bl x30, __z14WriteCharacterc
    b __LBB5_5
__LBB5_5:
    lw x1, 4(x31)
    add x2, x0, x0
    bne x1, x2, __LBB5_7
    b __LBB5_6
__LBB5_6:
    b __LBB5_2
__LBB5_7:
    lw x1, 4(x31)
    addi x1, x1, -1
    sw x1, 4(x31)
    b __LBB5_1

	.global	__z7SetLEDsc
__z7SetLEDsc:
    addi x31, x31, -8
    sb x1, 7(x31)
    lui x2, 31
    ori x2, x2, 2032
    sb x1, 0(x2)
    addi x31, x31, 8
    br x30

	.global	__z9SetWS2812cccc
__z9SetWS2812cccc:
    addi x31, x31, -16
    add x5, x4, x0
    add x4, x1, x0
    andi x1, x5, 255
    sb x4, 0(x31)
    sb x2, 1(x31)
    sb x3, 2(x31)
    sb x5, 3(x31)
    andi x4, x4, 255
    sw x4, 4(x31)
    andi x2, x2, 255
    sw x2, 8(x31)
    andi x2, x3, 255
    sw x2, 12(x31)
    addi x2, x0, 255
    beq x1, x2, __LBB7_2
    b __LBB7_1
__LBB7_1:
    lw x1, 4(x31)
    lbu x3, 3(x31)
    mul x1, x1, x3
    lui x2, 1052688
    ori x2, x2, 129
    mulhu x1, x1, x2
    srli x1, x1, 7
    sw x1, 4(x31)
    lw x1, 8(x31)
    mul x1, x1, x3
    mulhu x1, x1, x2
    srli x1, x1, 7
    sw x1, 8(x31)
    lw x1, 12(x31)
    mul x1, x1, x3
    mulhu x1, x1, x2
    srli x1, x1, 7
    sw x1, 12(x31)
    b __LBB7_2
__LBB7_2:
    lw x1, 8(x31)
    slli x1, x1, 16
    lw x2, 4(x31)
    slli x2, x2, 8
    or x1, x1, x2
    lw x2, 12(x31)
    or x1, x1, x2
    lui x2, 31
    ori x2, x2, 2016
    sw x1, 0(x2)
    addi x31, x31, 16
    br x30

	.global	__z12HasCharacter
__z12HasCharacter:
    lui x1, 31
    ori x1, x1, 2044
    lbu x1, 0(x1)
    andi x1, x1, 1
    br x30

	.global	__z13ReadCharacter
__z13ReadCharacter:
    lui x1, 31
    ori x1, x1, 2047
    lw x1, 0(x1)
    br x30

	.global	__z13ButtonPressed
__z13ButtonPressed:
    addi x31, x31, -16
    lui x1, 31
    ori x1, x1, 2036
    lbu x1, 0(x1)
    andi x1, x1, 1
    add x2, x0, x0
    sw x2, 8(x31)
    addi x2, x0, 1
    sw x2, 12(x31)
    bltu x1, x2, __LBB10_1
    b __LBB10_2
__LBB10_1:
    lw x1, 12(x31)
    sw x1, 4(x31)
    b __LBB10_3
__LBB10_2:
    lw x1, 8(x31)
    sw x1, 4(x31)
__LBB10_3:
    lw x1, 4(x31)
    addi x31, x31, 16
    br x30

	.global	__z7GetTime
__z7GetTime:
    lui x1, 31
    ori x1, x1, 2028
    lw x1, 0(x1)
    br x30

	.global	__z5Sleepi
__z5Sleepi:
    addi x31, x31, -16
    sw x30, 12(x31)
    sw x1, 4(x31)
    bl x30, __z7GetTime
    sw x1, 8(x31)
    b __LBB12_1
__LBB12_1:
    bl x30, __z7GetTime
    lw x2, 8(x31)
    sub x1, x1, x2
    lw x2, 4(x31)
    bgeu x1, x2, __LBB12_3
    b __LBB12_2
__LBB12_2:
    b __LBB12_1
__LBB12_3:
    lw x30, 12(x31)
    addi x31, x31, 16
    br x30

	.global	__z11SetBaudRatei
__z11SetBaudRatei:
    addi x31, x31, -8
    add x2, x1, x0
    sw x2, 4(x31)
    lui x1, 16113
    ori x1, x1, 576
    divu x1, x1, x2
    lui x2, 31
    ori x2, x2, 2040
    sw x1, 0(x2)
    addi x31, x31, 8
    br x30

	.global	Main
Main:
    addi x31, x31, -56
    sw x30, 52(x31)
    lui x1, 56
    ori x1, x1, 512
    bl x30, __z11SetBaudRatei
    addi x1, x0, 1
    bl x30, __z5Sleepi
    la x1, .L__unnamed_2
    bl x30, __z9WriteLinePc
    la x1, .L__unnamed_3
    bl x30, __z9WriteLinePc
    la x1, .L__unnamed_4
    bl x30, __z9WriteLinePc
    lui x1, 524288
    ori x1, x1, 0
    sw x1, 8(x31)
    lui x1, 1824183
    ori x1, x1, 1775
    sw x1, 12(x31)
    la x1, .L__unnamed_5
    bl x30, __z9WriteLinePc
    lw x2, 8(x31)
    lw x1, 12(x31)
    sw x1, 0(x2)
    la x1, .L__unnamed_6
    bl x30, __z5WritePc
    lw x1, 12(x31)
    bl x30, __z16WriteHexadecimali
    la x1, .L__unnamed_7
    bl x30, __z5WritePc
    lw x1, 8(x31)
    bl x30, __z16WriteHexadecimali
    la x1, .L__unnamed_8
    bl x30, __z9WriteLinePc
    lw x1, 8(x31)
    lw x1, 0(x1)
    sw x1, 16(x31)
    la x1, .L__unnamed_9
    bl x30, __z5WritePc
    lw x1, 16(x31)
    bl x30, __z16WriteHexadecimali
    la x1, .L__unnamed_10
    bl x30, __z5WritePc
    lw x1, 8(x31)
    bl x30, __z16WriteHexadecimali
    la x1, .L__unnamed_11
    bl x30, __z9WriteLinePc
    lw x1, 16(x31)
    lw x2, 12(x31)
    bne x1, x2, __LBB14_2
    b __LBB14_1
__LBB14_1:
    la x1, .L__unnamed_12
    bl x30, __z9WriteLinePc
    b __LBB14_3
__LBB14_2:
    la x1, .L__unnamed_13
    bl x30, __z9WriteLinePc
    b __LBB14_3
__LBB14_3:
    add x1, x0, x0
    sw x1, 4(x31)
    sw x1, 20(x31)
    addi x2, x0, 255
    sb x2, 24(x31)
    sb x1, 25(x31)
    sb x1, 26(x31)
    addi x1, x0, 63
    sb x1, 27(x31)
    bl x30, __z7SetLEDsc
    lw x1, 4(x31)
    sw x1, 28(x31)
    bl x30, __z13ButtonPressed
    xori x1, x1, -1
    andi x1, x1, 1
    sb x1, 35(x31)
    bl x30, __z7GetTime
    addi x1, x1, 10
    sw x1, 36(x31)
    addi x1, x0, 64
    sb x1, 43(x31)
    b __LBB14_4
__LBB14_4:
    bl x30, __z7GetTime
    sw x1, 44(x31)
    bl x30, __z13ButtonPressed
    andi x1, x1, 1
    add x2, x0, x0
    beq x1, x2, __LBB14_6
    b __LBB14_5
__LBB14_5:
    lbu x1, 35(x31)
    add x2, x0, x0
    bne x1, x2, __LBB14_7
    b __LBB14_8
__LBB14_6:
    addi x1, x0, 1
    sb x1, 35(x31)
    b __LBB14_11
__LBB14_7:
    lw x1, 28(x31)
    addi x2, x1, 1
    sw x2, 28(x31)
    addi x1, x0, 4
    blt x1, x2, __LBB14_9
    b __LBB14_10
__LBB14_8:
    b __LBB14_11
__LBB14_9:
    add x1, x0, x0
    sw x1, 28(x31)
    b __LBB14_10
__LBB14_10:
    add x1, x0, x0
    sb x1, 35(x31)
    la x1, .L__unnamed_14
    bl x30, __z5WritePc
    lw x1, 28(x31)
    bl x30, __z12WriteIntegeri
    la x1, .L__unnamed_15
    bl x30, __z5WritePc
    b __LBB14_8
__LBB14_11:
    lw x1, 44(x31)
    lw x2, 36(x31)
    bltu x1, x2, __LBB14_13
    b __LBB14_12
__LBB14_12:
    lw x1, 44(x31)
    addi x1, x1, 10
    sw x1, 36(x31)
    lw x1, 28(x31)
    add x2, x0, x0
    beq x1, x2, __LBB14_14
    b __LBB14_15
__LBB14_13:
    bl x30, __z12HasCharacter
    andi x1, x1, 1
    add x2, x0, x0
    bne x1, x2, __LBB14_56
    b __LBB14_57
__LBB14_14:
    lw x1, 20(x31)
    add x2, x0, x0
    beq x1, x2, __LBB14_16
    b __LBB14_17
__LBB14_15:
    lw x1, 28(x31)
    addi x2, x0, 1
    beq x1, x2, __LBB14_47
    b __LBB14_48
__LBB14_16:
    lbu x1, 25(x31)
    addi x2, x1, 5
    andi x1, x2, 255
    sb x2, 25(x31)
    addi x2, x0, 255
    beq x1, x2, __LBB14_18
    b __LBB14_19
__LBB14_17:
    lw x1, 20(x31)
    addi x2, x0, 1
    beq x1, x2, __LBB14_21
    b __LBB14_22
__LBB14_18:
    addi x1, x0, 255
    sb x1, 25(x31)
    addi x1, x0, 1
    sw x1, 20(x31)
    b __LBB14_19
__LBB14_19:
    b __LBB14_20
__LBB14_20:
    lbu x4, 43(x31)
    lbu x3, 26(x31)
    lbu x2, 25(x31)
    lbu x1, 24(x31)
    bl x30, __z9SetWS2812cccc
    b __LBB14_46
__LBB14_21:
    lbu x1, 24(x31)
    addi x2, x0, 6
    bltu x1, x2, __LBB14_23
    b __LBB14_24
__LBB14_22:
    lw x1, 20(x31)
    addi x2, x0, 2
    beq x1, x2, __LBB14_27
    b __LBB14_28
__LBB14_23:
    add x1, x0, x0
    sb x1, 24(x31)
    addi x1, x0, 2
    sw x1, 20(x31)
    b __LBB14_25
__LBB14_24:
    lbu x1, 24(x31)
    addi x1, x1, -5
    sb x1, 24(x31)
    b __LBB14_25
__LBB14_25:
    b __LBB14_26
__LBB14_26:
    b __LBB14_20
__LBB14_27:
    lbu x1, 26(x31)
    addi x2, x1, 5
    andi x1, x2, 255
    sb x2, 26(x31)
    addi x2, x0, 255
    beq x1, x2, __LBB14_29
    b __LBB14_30
__LBB14_28:
    lw x1, 20(x31)
    addi x2, x0, 3
    beq x1, x2, __LBB14_32
    b __LBB14_33
__LBB14_29:
    addi x1, x0, 255
    sb x1, 26(x31)
    addi x1, x0, 3
    sw x1, 20(x31)
    b __LBB14_30
__LBB14_30:
    b __LBB14_31
__LBB14_31:
    b __LBB14_26
__LBB14_32:
    lbu x1, 25(x31)
    addi x2, x0, 6
    bltu x1, x2, __LBB14_34
    b __LBB14_35
__LBB14_33:
    lw x1, 20(x31)
    addi x2, x0, 4
    beq x1, x2, __LBB14_38
    b __LBB14_39
__LBB14_34:
    add x1, x0, x0
    sb x1, 25(x31)
    addi x1, x0, 4
    sw x1, 20(x31)
    b __LBB14_36
__LBB14_35:
    lbu x1, 25(x31)
    addi x1, x1, -5
    sb x1, 25(x31)
    b __LBB14_36
__LBB14_36:
    b __LBB14_37
__LBB14_37:
    b __LBB14_31
__LBB14_38:
    lbu x1, 24(x31)
    addi x2, x1, 5
    andi x1, x2, 255
    sb x2, 24(x31)
    addi x2, x0, 255
    beq x1, x2, __LBB14_40
    b __LBB14_41
__LBB14_39:
    lbu x1, 26(x31)
    addi x2, x0, 6
    bltu x1, x2, __LBB14_43
    b __LBB14_44
__LBB14_40:
    addi x1, x0, 255
    sb x1, 24(x31)
    addi x1, x0, 5
    sw x1, 20(x31)
    b __LBB14_41
__LBB14_41:
    b __LBB14_42
__LBB14_42:
    b __LBB14_37
__LBB14_43:
    add x1, x0, x0
    sb x1, 26(x31)
    sw x1, 20(x31)
    b __LBB14_45
__LBB14_44:
    lbu x1, 26(x31)
    addi x1, x1, -5
    sb x1, 26(x31)
    b __LBB14_45
__LBB14_45:
    b __LBB14_42
__LBB14_46:
    b __LBB14_13
__LBB14_47:
    lbu x4, 43(x31)
    addi x1, x0, 255
    add x3, x0, x0
    add x2, x3, x0
    bl x30, __z9SetWS2812cccc
    b __LBB14_49
__LBB14_48:
    lw x1, 28(x31)
    addi x2, x0, 2
    beq x1, x2, __LBB14_50
    b __LBB14_51
__LBB14_49:
    b __LBB14_46
__LBB14_50:
    lbu x4, 43(x31)
    addi x2, x0, 255
    add x3, x0, x0
    add x1, x3, x0
    bl x30, __z9SetWS2812cccc
    b __LBB14_52
__LBB14_51:
    lw x1, 28(x31)
    addi x2, x0, 3
    beq x1, x2, __LBB14_53
    b __LBB14_54
__LBB14_52:
    b __LBB14_49
__LBB14_53:
    lbu x4, 43(x31)
    add x2, x0, x0
    addi x3, x0, 255
    add x1, x2, x0
    bl x30, __z9SetWS2812cccc
    b __LBB14_55
__LBB14_54:
    lbu x4, 43(x31)
    add x3, x0, x0
    add x1, x3, x0
    add x2, x3, x0
    bl x30, __z9SetWS2812cccc
    b __LBB14_55
__LBB14_55:
    b __LBB14_52
__LBB14_56:
    bl x30, __z13ReadCharacter
    sb x1, 51(x31)
    slli x1, x1, 24
    srai x1, x1, 24
    sw x1, 0(x31)
    addi x2, x0, 49
    blt x1, x2, __LBB14_59
    b __LBB14_73
__LBB14_73:
    lw x1, 0(x31)
    addi x2, x0, 55
    blt x1, x2, __LBB14_58
    b __LBB14_59
__LBB14_57:
    b __LBB14_4
__LBB14_58:
    lbu x1, 51(x31)
    addi x1, x1, -49
    andi x2, x1, 255
    addi x1, x0, 1
    sll x2, x1, x2
    lbu x1, 27(x31)
    xor x1, x1, x2
    sb x1, 27(x31)
    bl x30, __z7SetLEDsc
    b __LBB14_60
__LBB14_59:
    lbu x1, 51(x31)
    addi x2, x0, 43
    beq x1, x2, __LBB14_61
    b __LBB14_62
__LBB14_60:
    b __LBB14_57
__LBB14_61:
    lbu x2, 43(x31)
    addi x1, x0, 246
    bltu x1, x2, __LBB14_63
    b __LBB14_64
__LBB14_62:
    lbu x1, 51(x31)
    addi x2, x0, 45
    beq x1, x2, __LBB14_67
    b __LBB14_68
__LBB14_63:
    addi x1, x0, 255
    sb x1, 43(x31)
    b __LBB14_65
__LBB14_64:
    lbu x1, 43(x31)
    addi x1, x1, 8
    sb x1, 43(x31)
    b __LBB14_65
__LBB14_65:
    la x1, .L__unnamed_16
    bl x30, __z5WritePc
    lbu x1, 43(x31)
    bl x30, __z12WriteIntegeri.1
    la x1, .L__unnamed_17
    bl x30, __z5WritePc
    b __LBB14_66
__LBB14_66:
    b __LBB14_60
__LBB14_67:
    lbu x1, 43(x31)
    addi x2, x0, 9
    bltu x1, x2, __LBB14_69
    b __LBB14_70
__LBB14_68:
    lbu x1, 51(x31)
    bl x30, __z14WriteCharacterc
    b __LBB14_72
__LBB14_69:
    add x1, x0, x0
    sb x1, 43(x31)
    b __LBB14_71
__LBB14_70:
    lbu x1, 43(x31)
    addi x1, x1, -8
    sb x1, 43(x31)
    b __LBB14_71
__LBB14_71:
    la x1, .L__unnamed_18
    bl x30, __z5WritePc
    lbu x1, 43(x31)
    bl x30, __z12WriteIntegeri.1
    la x1, .L__unnamed_19
    bl x30, __z5WritePc
    b __LBB14_72
__LBB14_72:
    b __LBB14_66

	.data
.LCLK_FREQ:
	.word	33000000

.L__unnamed_1:
	.string	"0x"

.L__unnamed_2:
	.string	"Zodiac interactive terminal initialized!"

.L__unnamed_3:
	.string	"Type anything to echo, press 1-6 to toggle LEDs, or +/- to change RGB brightness."

.L__unnamed_4:
	.string	"Press the button on the board to cycle WS2812 animation modes."

.L__unnamed_5:
	.string	"Running SDRAM test..."

.L__unnamed_6:
	.string	"Written "

.L__unnamed_7:
	.string	" to "

.L__unnamed_8:
	.string	"."

.L__unnamed_9:
	.string	"Read "

.L__unnamed_10:
	.string	" from "

.L__unnamed_11:
	.string	"."

.L__unnamed_12:
	.string	"SDRAM test successful!"

.L__unnamed_13:
	.string	"SDRAM test failed!"

.L__unnamed_14:
	.string	"WS2812 Mode: "

.L__unnamed_15:
	.string	"\n"

.L__unnamed_16:
	.string	"Brightness: "

.L__unnamed_17:
	.string	"/255\n"

.L__unnamed_18:
	.string	"Brightness: "

.L__unnamed_19:
	.string	"/255\n"

