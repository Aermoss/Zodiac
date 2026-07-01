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
    beq x1, x2, __LBB5_2
    b __LBB5_1
__LBB5_1:
    lw x1, 4(x31)
    lbu x3, 3(x31)
    mul x4, x1, x3
    lui x1, 1052688
    ori x1, x1, 129
    mulh x2, x4, x1
    add x2, x2, x4
    srli x4, x2, 31
    srai x2, x2, 7
    add x2, x2, x4
    sw x2, 4(x31)
    lw x2, 8(x31)
    mul x4, x2, x3
    mulh x2, x4, x1
    add x2, x2, x4
    srli x4, x2, 31
    srai x2, x2, 7
    add x2, x2, x4
    sw x2, 8(x31)
    lw x2, 12(x31)
    mul x2, x2, x3
    mulh x1, x2, x1
    add x1, x1, x2
    srli x2, x1, 31
    srai x1, x1, 7
    add x1, x1, x2
    sw x1, 12(x31)
    b __LBB5_2
__LBB5_2:
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
    bltu x1, x2, __LBB8_1
    b __LBB8_2
__LBB8_1:
    lw x1, 12(x31)
    sw x1, 4(x31)
    b __LBB8_3
__LBB8_2:
    lw x1, 8(x31)
    sw x1, 4(x31)
__LBB8_3:
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
    b __LBB10_1
__LBB10_1:
    bl x30, __z7GetTime
    lw x2, 8(x31)
    sub x1, x1, x2
    lw x2, 4(x31)
    bge x1, x2, __LBB10_3
    b __LBB10_2
__LBB10_2:
    b __LBB10_1
__LBB10_3:
    lw x30, 12(x31)
    addi x31, x31, 16
    br x30

	.global	__z11SetBaudRatei
__z11SetBaudRatei:
    addi x31, x31, -8
    add x2, x1, x0
    sw x2, 4(x31)
    lui x1, 13183
    ori x1, x1, 1216
    div x1, x1, x2
    lui x2, 31
    ori x2, x2, 2040
    sw x1, 0(x2)
    addi x31, x31, 8
    br x30

	.global	Main
Main:
    addi x31, x31, -48
    sw x30, 44(x31)
    lui x1, 56
    ori x1, x1, 512
    bl x30, __z11SetBaudRatei
    la x1, .L__unnamed_1
    bl x30, __z9WriteLinePc
    la x1, .L__unnamed_2
    bl x30, __z9WriteLinePc
    la x1, .L__unnamed_3
    bl x30, __z9WriteLinePc
    add x1, x0, x0
    sw x1, 8(x31)
    sw x1, 12(x31)
    addi x2, x0, 255
    sb x2, 16(x31)
    sb x1, 17(x31)
    sb x1, 18(x31)
    addi x1, x0, 63
    sb x1, 19(x31)
    bl x30, __z7SetLEDsc
    lw x1, 8(x31)
    sw x1, 20(x31)
    bl x30, __z13ButtonPressed
    xori x1, x1, -1
    andi x1, x1, 1
    sb x1, 27(x31)
    bl x30, __z7GetTime
    addi x1, x1, 10
    sw x1, 28(x31)
    addi x1, x0, 64
    sb x1, 35(x31)
    b __LBB12_1
__LBB12_1:
    bl x30, __z7GetTime
    sw x1, 36(x31)
    bl x30, __z13ButtonPressed
    andi x1, x1, 1
    add x2, x0, x0
    beq x1, x2, __LBB12_3
    b __LBB12_2
__LBB12_2:
    lbu x1, 27(x31)
    add x2, x0, x0
    bne x1, x2, __LBB12_4
    b __LBB12_5
__LBB12_3:
    addi x1, x0, 1
    sb x1, 27(x31)
    b __LBB12_8
__LBB12_4:
    add x1, x0, x0
    sb x1, 27(x31)
    lw x1, 20(x31)
    addi x2, x1, 1
    sw x2, 20(x31)
    addi x1, x0, 4
    blt x1, x2, __LBB12_6
    b __LBB12_7
__LBB12_5:
    b __LBB12_8
__LBB12_6:
    add x1, x0, x0
    sw x1, 20(x31)
    b __LBB12_7
__LBB12_7:
    la x1, .L__unnamed_4
    bl x30, __z5WritePc
    lw x1, 20(x31)
    bl x30, __z12WriteIntegeri
    la x1, .L__unnamed_5
    bl x30, __z5WritePc
    b __LBB12_5
__LBB12_8:
    lw x1, 36(x31)
    lw x2, 28(x31)
    blt x1, x2, __LBB12_10
    b __LBB12_9
__LBB12_9:
    lw x1, 36(x31)
    addi x1, x1, 10
    sw x1, 28(x31)
    lw x1, 20(x31)
    add x2, x0, x0
    beq x1, x2, __LBB12_11
    b __LBB12_12
__LBB12_10:
    bl x30, __z12HasCharacter
    andi x1, x1, 1
    add x2, x0, x0
    bne x1, x2, __LBB12_53
    b __LBB12_54
__LBB12_11:
    lw x1, 12(x31)
    add x2, x0, x0
    beq x1, x2, __LBB12_13
    b __LBB12_14
__LBB12_12:
    lw x1, 20(x31)
    addi x2, x0, 1
    beq x1, x2, __LBB12_44
    b __LBB12_45
__LBB12_13:
    lbu x1, 17(x31)
    addi x2, x1, 5
    andi x1, x2, 255
    sb x2, 17(x31)
    addi x2, x0, 255
    beq x1, x2, __LBB12_15
    b __LBB12_16
__LBB12_14:
    lw x1, 12(x31)
    addi x2, x0, 1
    beq x1, x2, __LBB12_18
    b __LBB12_19
__LBB12_15:
    addi x1, x0, 255
    sb x1, 17(x31)
    addi x1, x0, 1
    sw x1, 12(x31)
    b __LBB12_16
__LBB12_16:
    b __LBB12_17
__LBB12_17:
    lbu x4, 35(x31)
    lbu x3, 18(x31)
    lbu x2, 17(x31)
    lbu x1, 16(x31)
    bl x30, __z9SetWS2812cccc
    b __LBB12_43
__LBB12_18:
    lbu x1, 16(x31)
    addi x2, x0, 6
    bltu x1, x2, __LBB12_20
    b __LBB12_21
__LBB12_19:
    lw x1, 12(x31)
    addi x2, x0, 2
    beq x1, x2, __LBB12_24
    b __LBB12_25
__LBB12_20:
    add x1, x0, x0
    sb x1, 16(x31)
    addi x1, x0, 2
    sw x1, 12(x31)
    b __LBB12_22
__LBB12_21:
    lbu x1, 16(x31)
    addi x1, x1, -5
    sb x1, 16(x31)
    b __LBB12_22
__LBB12_22:
    b __LBB12_23
__LBB12_23:
    b __LBB12_17
__LBB12_24:
    lbu x1, 18(x31)
    addi x2, x1, 5
    andi x1, x2, 255
    sb x2, 18(x31)
    addi x2, x0, 255
    beq x1, x2, __LBB12_26
    b __LBB12_27
__LBB12_25:
    lw x1, 12(x31)
    addi x2, x0, 3
    beq x1, x2, __LBB12_29
    b __LBB12_30
__LBB12_26:
    addi x1, x0, 255
    sb x1, 18(x31)
    addi x1, x0, 3
    sw x1, 12(x31)
    b __LBB12_27
__LBB12_27:
    b __LBB12_28
__LBB12_28:
    b __LBB12_23
__LBB12_29:
    lbu x1, 17(x31)
    addi x2, x0, 6
    bltu x1, x2, __LBB12_31
    b __LBB12_32
__LBB12_30:
    lw x1, 12(x31)
    addi x2, x0, 4
    beq x1, x2, __LBB12_35
    b __LBB12_36
__LBB12_31:
    add x1, x0, x0
    sb x1, 17(x31)
    addi x1, x0, 4
    sw x1, 12(x31)
    b __LBB12_33
__LBB12_32:
    lbu x1, 17(x31)
    addi x1, x1, -5
    sb x1, 17(x31)
    b __LBB12_33
__LBB12_33:
    b __LBB12_34
__LBB12_34:
    b __LBB12_28
__LBB12_35:
    lbu x1, 16(x31)
    addi x2, x1, 5
    andi x1, x2, 255
    sb x2, 16(x31)
    addi x2, x0, 255
    beq x1, x2, __LBB12_37
    b __LBB12_38
__LBB12_36:
    lbu x1, 18(x31)
    addi x2, x0, 6
    bltu x1, x2, __LBB12_40
    b __LBB12_41
__LBB12_37:
    addi x1, x0, 255
    sb x1, 16(x31)
    addi x1, x0, 5
    sw x1, 12(x31)
    b __LBB12_38
__LBB12_38:
    b __LBB12_39
__LBB12_39:
    b __LBB12_34
__LBB12_40:
    add x1, x0, x0
    sb x1, 18(x31)
    sw x1, 12(x31)
    b __LBB12_42
__LBB12_41:
    lbu x1, 18(x31)
    addi x1, x1, -5
    sb x1, 18(x31)
    b __LBB12_42
__LBB12_42:
    b __LBB12_39
__LBB12_43:
    b __LBB12_10
__LBB12_44:
    lbu x4, 35(x31)
    addi x1, x0, 255
    add x3, x0, x0
    add x2, x3, x0
    bl x30, __z9SetWS2812cccc
    b __LBB12_46
__LBB12_45:
    lw x1, 20(x31)
    addi x2, x0, 2
    beq x1, x2, __LBB12_47
    b __LBB12_48
__LBB12_46:
    b __LBB12_43
__LBB12_47:
    lbu x4, 35(x31)
    addi x2, x0, 255
    add x3, x0, x0
    add x1, x3, x0
    bl x30, __z9SetWS2812cccc
    b __LBB12_49
__LBB12_48:
    lw x1, 20(x31)
    addi x2, x0, 3
    beq x1, x2, __LBB12_50
    b __LBB12_51
__LBB12_49:
    b __LBB12_46
__LBB12_50:
    lbu x4, 35(x31)
    add x2, x0, x0
    addi x3, x0, 255
    add x1, x2, x0
    bl x30, __z9SetWS2812cccc
    b __LBB12_52
__LBB12_51:
    lbu x4, 35(x31)
    add x3, x0, x0
    add x1, x3, x0
    add x2, x3, x0
    bl x30, __z9SetWS2812cccc
    b __LBB12_52
__LBB12_52:
    b __LBB12_49
__LBB12_53:
    bl x30, __z13ReadCharacter
    sb x1, 43(x31)
    slli x1, x1, 24
    srai x1, x1, 24
    sw x1, 4(x31)
    addi x2, x0, 49
    blt x1, x2, __LBB12_56
    b __LBB12_70
__LBB12_70:
    lw x1, 4(x31)
    addi x2, x0, 55
    blt x1, x2, __LBB12_55
    b __LBB12_56
__LBB12_54:
    b __LBB12_1
__LBB12_55:
    lbu x1, 43(x31)
    addi x1, x1, -49
    andi x2, x1, 255
    addi x1, x0, 1
    sll x2, x1, x2
    lbu x1, 19(x31)
    xor x1, x1, x2
    sb x1, 19(x31)
    bl x30, __z7SetLEDsc
    b __LBB12_57
__LBB12_56:
    lbu x1, 43(x31)
    addi x2, x0, 43
    beq x1, x2, __LBB12_58
    b __LBB12_59
__LBB12_57:
    b __LBB12_54
__LBB12_58:
    lbu x2, 35(x31)
    addi x1, x0, 246
    bltu x1, x2, __LBB12_60
    b __LBB12_61
__LBB12_59:
    lbu x1, 43(x31)
    addi x2, x0, 45
    beq x1, x2, __LBB12_64
    b __LBB12_65
__LBB12_60:
    addi x1, x0, 255
    sb x1, 35(x31)
    b __LBB12_62
__LBB12_61:
    lbu x1, 35(x31)
    addi x1, x1, 8
    sb x1, 35(x31)
    b __LBB12_62
__LBB12_62:
    la x1, .L__unnamed_6
    bl x30, __z5WritePc
    lbu x1, 35(x31)
    bl x30, __z12WriteIntegeri
    la x1, .L__unnamed_7
    bl x30, __z5WritePc
    b __LBB12_63
__LBB12_63:
    b __LBB12_57
__LBB12_64:
    lbu x1, 35(x31)
    addi x2, x0, 9
    bltu x1, x2, __LBB12_66
    b __LBB12_67
__LBB12_65:
    lbu x1, 43(x31)
    bl x30, __z14WriteCharacterc
    b __LBB12_69
__LBB12_66:
    add x1, x0, x0
    sb x1, 35(x31)
    b __LBB12_68
__LBB12_67:
    lbu x1, 35(x31)
    addi x1, x1, -8
    sb x1, 35(x31)
    b __LBB12_68
__LBB12_68:
    la x1, .L__unnamed_8
    bl x30, __z5WritePc
    lbu x1, 35(x31)
    bl x30, __z12WriteIntegeri
    la x1, .L__unnamed_9
    bl x30, __z5WritePc
    b __LBB12_69
__LBB12_69:
    b __LBB12_63

	.data
.L__unnamed_1:
	.string	"Zodiac interactive terminal initialized!"

.L__unnamed_2:
	.string	"Type anything to echo, press 1-6 to toggle LEDs, or +/- to change RGB brightness."

.L__unnamed_3:
	.string	"Press the button on the board to cycle WS2812 animation modes."

.L__unnamed_4:
	.string	"WS2812 Mode: "

.L__unnamed_5:
	.string	"\n"

.L__unnamed_6:
	.string	"Brightness: "

.L__unnamed_7:
	.string	"/255\n"

.L__unnamed_8:
	.string	"Brightness: "

.L__unnamed_9:
	.string	"/255\n"

