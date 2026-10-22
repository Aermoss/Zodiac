	.text

	.global	__z14WriteCharacteri8
__z14WriteCharacteri8:
__LBB0_0:
__LBB0_1:
    li t0, 63488
    lw t0, 2044(t0)
    andi t0, t0, 2
    bne t0, zero, __LBB0_3
__LBB0_2:
    li t0, 63488
    sb a0, 2047(t0)
    br ra
__LBB0_3:
    b __LBB0_1

	.global	__z5WritePi8
__z5WritePi8:
    sw ra, -4(sp)
    sw fp, -8(sp)
    addi fp, sp, 0
    addi sp, sp, -12
    sw s1, 0(sp)
__LBB1_0:
    addi s1, a0, 0
__LBB1_1:
    lbu t0, 0(s1)
    andi t0, t0, 255
    bne t0, zero, __LBB1_3
__LBB1_2:
    lw s1, 0(sp)
    lw ra, -4(fp)
    addi sp, fp, 0
    lw fp, -8(sp)
    br ra
__LBB1_3:
    lbu a0, 0(s1)
    bl ra, __z14WriteCharacteri8
    addi t0, s1, 1
    addi s1, t0, 0
    b __LBB1_1

	.global	__z9WriteLinePi8
__z9WriteLinePi8:
    sw ra, -4(sp)
    sw fp, -8(sp)
    addi fp, sp, 0
    addi sp, sp, -8
__LBB2_0:
    bl ra, __z5WritePi8
    li a0, 10
    bl ra, __z14WriteCharacteri8
    lw ra, -4(fp)
    addi sp, fp, 0
    lw fp, -8(sp)
    br ra

	.global	__z12WriteIntegeri32
__z12WriteIntegeri32:
    sw ra, -4(sp)
    sw fp, -8(sp)
    addi fp, sp, 0
    addi sp, sp, -16
    sw s1, 0(sp)
    sw s2, 4(sp)
__LBB3_0:
    addi s1, a0, 0
    bge s1, zero, __LBB3_5
__LBB3_1:
    li a0, 45
    bl ra, __z14WriteCharacteri8
    sub t0, zero, s1
    addi s2, t0, 0
__LBB3_2:
    li t0, 10
    blt s2, t0, __LBB3_4
__LBB3_3:
    li t0, 10
    div a0, s2, t0
    bl ra, __z12WriteIntegeri32
__LBB3_4:
    li t0, 10
    rem t0, s2, t0
    addi a0, t0, 48
    bl ra, __z14WriteCharacteri8
    lw s1, 0(sp)
    lw s2, 4(sp)
    lw ra, -4(fp)
    addi sp, fp, 0
    lw fp, -8(sp)
    br ra
__LBB3_5:
    addi s2, s1, 0
    b __LBB3_2

	.global	__z12WriteIntegeru32
__z12WriteIntegeru32:
    sw ra, -4(sp)
    sw fp, -8(sp)
    addi fp, sp, 0
    addi sp, sp, -12
    sw s1, 0(sp)
__LBB4_0:
    addi s1, a0, 0
    li t0, 10
    bltu s1, t0, __LBB4_2
__LBB4_1:
    li t0, 10
    divu a0, s1, t0
    bl ra, __z12WriteIntegeru32
__LBB4_2:
    li t0, 10
    remu t0, s1, t0
    addi a0, t0, 48
    bl ra, __z14WriteCharacteri8
    lw s1, 0(sp)
    lw ra, -4(fp)
    addi sp, fp, 0
    lw fp, -8(sp)
    br ra

	.global	__z16WriteHexadecimalu32
__z16WriteHexadecimalu32:
    sw ra, -4(sp)
    sw fp, -8(sp)
    addi fp, sp, 0
    addi sp, sp, -20
    sw s1, 0(sp)
    sw s2, 4(sp)
    sw s3, 8(sp)
__LBB5_0:
    addi s1, a0, 0
    la a0, string.0
    bl ra, __z5WritePi8
    li t0, 7
    addi s2, t0, 0
__LBB5_1:
    slli t0, s2, 2
    srl t0, s1, t0
    andi s3, t0, 15
    andi t0, s3, 255
    li t1, 10
    bltu t0, t1, __LBB5_3
__LBB5_2:
    subi t0, s3, 10
    addi a0, t0, 65
    bl ra, __z14WriteCharacteri8
    b __LBB5_4
__LBB5_3:
    addi a0, s3, 48
    bl ra, __z14WriteCharacteri8
__LBB5_4:
    beq s2, zero, __LBB5_6
__LBB5_5:
    subi t0, s2, 1
    addi s2, t0, 0
    b __LBB5_1
__LBB5_6:
__LBB5_7:
    lw s1, 0(sp)
    lw s2, 4(sp)
    lw s3, 8(sp)
    lw ra, -4(fp)
    addi sp, fp, 0
    lw fp, -8(sp)
    br ra

	.global	__z7SetLEDsi8
__z7SetLEDsi8:
__LBB6_0:
    li t0, 63488
    sb a0, 2032(t0)
    br ra

	.global	__z9SetWS2812u8u8u8u8
__z9SetWS2812u8u8u8u8:
    sw ra, -4(sp)
    sw fp, -8(sp)
    addi fp, sp, 0
    addi sp, sp, -36
    sw s1, 0(sp)
    sw s2, 4(sp)
    sw s3, 8(sp)
    sw s4, 12(sp)
__LBB7_0:
    addi s1, a3, 0
    andi t0, a0, 255
    sw t0, -20(fp)
    andi t0, a1, 255
    sw t0, -16(fp)
    andi t0, a2, 255
    sw t0, -12(fp)
    lw s2, -20(fp)
    lw s3, -16(fp)
    lw s4, -12(fp)
    addi a0, fp, -20
    bl ra, __z16_7E_28u32_2C_20u32_2C_20u32_29MRTu32u32u32E
    andi t0, s1, 255
    li t1, 255
    bgeu t0, t1, __LBB7_3
__LBB7_1:
    andi t0, s1, 255
    mul t0, s2, t0
    li t1, 255
    divu t0, t0, t1
    andi t1, s1, 255
    mul t1, s3, t1
    li t2, 255
    divu t1, t1, t2
    andi t2, s1, 255
    mul t2, s4, t2
    li t3, 255
    divu t2, t2, t3
__LBB7_2:
    slli t3, t1, 16
    slli t4, t0, 8
    or t3, t3, t4
    or t3, t3, t2
    li t4, 63488
    sw t3, 2016(t4)
    lw s1, 0(sp)
    lw s2, 4(sp)
    lw s3, 8(sp)
    lw s4, 12(sp)
    lw ra, -4(fp)
    addi sp, fp, 0
    lw fp, -8(sp)
    br ra
__LBB7_3:
    addi t2, s4, 0
    addi t1, s3, 0
    addi t0, s2, 0
    b __LBB7_2

	.global	__z12HasCharacter
__z12HasCharacter:
__LBB8_0:
    li t0, 63488
    lw t0, 2044(t0)
    andi t0, t0, 1
    sltu a0, zero, t0
    br ra

	.global	__z13ReadCharacter
__z13ReadCharacter:
__LBB9_0:
    li t0, 63488
    lw a0, 2047(t0)
    br ra

	.global	__z13ButtonPressed
__z13ButtonPressed:
__LBB10_0:
    li t0, 63488
    lw t0, 2036(t0)
    andi t0, t0, 1
    sltiu a0, t0, 1
    br ra

	.global	__z7GetTime
__z7GetTime:
__LBB11_0:
    li t0, 63488
    lw a0, 2028(t0)
    br ra

	.global	__z5Sleepu32
__z5Sleepu32:
    sw ra, -4(sp)
    sw fp, -8(sp)
    addi fp, sp, 0
    addi sp, sp, -16
    sw s1, 0(sp)
    sw s2, 4(sp)
__LBB12_0:
    addi s1, a0, 0
    bl ra, __z7GetTime
    addi s2, a0, 0
__LBB12_1:
    bl ra, __z7GetTime
    sub t0, a0, s2
    bltu t0, s1, __LBB12_3
__LBB12_2:
    lw s1, 0(sp)
    lw s2, 4(sp)
    lw ra, -4(fp)
    addi sp, fp, 0
    lw fp, -8(sp)
    br ra
__LBB12_3:
    b __LBB12_1

	.global	__z11SetBaudRateu32
__z11SetBaudRateu32:
__LBB13_0:
    li t0, 45000000
    divu t0, t0, a0
    li t1, 63488
    sw t0, 2040(t1)
    br ra

	.global	Main
Main:
    sw ra, -4(sp)
    sw fp, -8(sp)
    addi fp, sp, 0
    addi sp, sp, -180
    sw s1, 0(sp)
    sw s2, 4(sp)
    sw s3, 8(sp)
    sw s4, 12(sp)
    sw s5, 16(sp)
    sw s6, 20(sp)
    sw s7, 24(sp)
    sw s8, 28(sp)
    sw s9, 32(sp)
    sw s10, 36(sp)
    sw s11, 40(sp)
__LBB14_0:
    li a0, 115200
    bl ra, __z11SetBaudRateu32
    la a0, string.1
    bl ra, __z9WriteLinePi8
    la a0, string.2
    bl ra, __z9WriteLinePi8
    la a0, string.3
    bl ra, __z9WriteLinePi8
    la a0, string.4
    bl ra, __z9WriteLinePi8
    li t0, -559038737
    li t1, 1073741824
    sw t0, 0(t1)
    la a0, string.5
    bl ra, __z5WritePi8
    li a0, -559038737
    bl ra, __z16WriteHexadecimalu32
    la a0, string.6
    bl ra, __z5WritePi8
    li a0, 1073741824
    bl ra, __z16WriteHexadecimalu32
    la a0, string.7
    bl ra, __z9WriteLinePi8
    li t0, 1073741824
    lw s4, 0(t0)
    la a0, string.8
    bl ra, __z5WritePi8
    addi a0, s4, 0
    bl ra, __z16WriteHexadecimalu32
    la a0, string.9
    bl ra, __z5WritePi8
    li a0, 1073741824
    bl ra, __z16WriteHexadecimalu32
    la a0, string.7
    bl ra, __z9WriteLinePi8
    li t0, -559038737
    xor t0, s4, t0
    beq t0, zero, __LBB14_2
__LBB14_1:
    la a0, string.10
    bl ra, __z9WriteLinePi8
    b __LBB14_3
__LBB14_2:
    la a0, string.11
    bl ra, __z9WriteLinePi8
__LBB14_3:
    li t0, -2146435072
    addi s4, zero, 0
    addi s5, t0, 0
__LBB14_4:
    li t0, 16
    blt s4, t0, __LBB14_72
__LBB14_5:
    li t0, 255
    sb t0, -11(fp)
    sb zero, -10(fp)
    sb zero, -9(fp)
    lbu s6, -11(fp)
    lbu s7, -10(fp)
    lbu s8, -9(fp)
    addi a0, fp, -11
    bl ra, __z13_7E_28u8_2C_20u8_2C_20u8_29MRTu8u8u8E
    li a0, 63
    bl ra, __z7SetLEDsi8
    bl ra, __z13ButtonPressed
    xori s9, a0, 1
    bl ra, __z7GetTime
    addi t0, a0, 10
    li t1, 64
    li t2, 63
    addi t5, t1, 0
    sw t5, -16(fp)
    addi t5, t0, 0
    sw t5, -64(fp)
    addi t5, zero, 0
    sw t5, -88(fp)
    addi t5, t2, 0
    sw t5, -20(fp)
    addi t5, s8, 0
    sw t5, -44(fp)
    addi t5, s7, 0
    sw t5, -60(fp)
    addi t5, s6, 0
    sw t5, -48(fp)
    addi t5, zero, 0
    sw t5, -52(fp)
__LBB14_6:
    bl ra, __z7GetTime
    addi t5, a0, 0
    sw t5, -68(fp)
    bl ra, __z13ButtonPressed
    andi t0, a0, 1
    bne t0, zero, __LBB14_8
__LBB14_7:
    li t0, 1
    addi t5, t0, 0
    sw t5, -32(fp)
    lw t5, -88(fp)
    sw t5, -36(fp)
    b __LBB14_13
__LBB14_8:
    andi t0, s9, 1
    beq t0, zero, __LBB14_74
__LBB14_9:
    lw t5, -88(fp)
    addi t5, t5, 1
    sw t5, -76(fp)
    li t0, 4
    lw t5, -76(fp)
    bge t0, t5, __LBB14_75
__LBB14_10:
    addi t5, zero, 0
    sw t5, -72(fp)
__LBB14_11:
    la a0, string.12
    bl ra, __z5WritePi8
    lw t5, -72(fp)
    addi a0, t5, 0
    bl ra, __z12WriteIntegeri32
    la a0, string.13
    bl ra, __z5WritePi8
    addi t5, zero, 0
    sw t5, -80(fp)
    lw t5, -72(fp)
    sw t5, -84(fp)
__LBB14_12:
    lw t5, -80(fp)
    sw t5, -32(fp)
    lw t5, -84(fp)
    sw t5, -36(fp)
__LBB14_13:
    lw t5, -68(fp)
    lw t6, -64(fp)
    bltu t5, t6, __LBB14_76
__LBB14_14:
    lw t5, -68(fp)
    addi t5, t5, 10
    sw t5, -56(fp)
    lw t5, -36(fp)
    beq t5, zero, __LBB14_24
__LBB14_15:
    lw t5, -36(fp)
    xori t0, t5, 1
    beq t0, zero, __LBB14_23
__LBB14_16:
    lw t5, -36(fp)
    xori t0, t5, 2
    beq t0, zero, __LBB14_22
__LBB14_17:
    lw t5, -36(fp)
    xori t0, t5, 3
    beq t0, zero, __LBB14_21
__LBB14_18:
    b __LBB14_20
__LBB14_19:
    hlt
__LBB14_20:
    addi a0, zero, 0
    addi a1, zero, 0
    addi a2, zero, 0
    lw t5, -16(fp)
    addi a3, t5, 0
    bl ra, __z9SetWS2812u8u8u8u8
    lw t5, -44(fp)
    addi s7, t5, 0
    lw t5, -60(fp)
    addi s11, t5, 0
    lw t5, -48(fp)
    addi s2, t5, 0
    lw t5, -52(fp)
    addi s8, t5, 0
    b __LBB14_53
__LBB14_21:
    li a2, 255
    addi a0, zero, 0
    addi a1, zero, 0
    lw t5, -16(fp)
    addi a3, t5, 0
    bl ra, __z9SetWS2812u8u8u8u8
    lw t5, -44(fp)
    addi s7, t5, 0
    lw t5, -60(fp)
    addi s11, t5, 0
    lw t5, -48(fp)
    addi s2, t5, 0
    lw t5, -52(fp)
    addi s8, t5, 0
    b __LBB14_53
__LBB14_22:
    li a1, 255
    addi a0, zero, 0
    addi a2, zero, 0
    lw t5, -16(fp)
    addi a3, t5, 0
    bl ra, __z9SetWS2812u8u8u8u8
    lw t5, -44(fp)
    addi s7, t5, 0
    lw t5, -60(fp)
    addi s11, t5, 0
    lw t5, -48(fp)
    addi s2, t5, 0
    lw t5, -52(fp)
    addi s8, t5, 0
    b __LBB14_53
__LBB14_23:
    li a0, 255
    addi a1, zero, 0
    addi a2, zero, 0
    lw t5, -16(fp)
    addi a3, t5, 0
    bl ra, __z9SetWS2812u8u8u8u8
    lw t5, -44(fp)
    addi s7, t5, 0
    lw t5, -60(fp)
    addi s11, t5, 0
    lw t5, -48(fp)
    addi s2, t5, 0
    lw t5, -52(fp)
    addi s8, t5, 0
    b __LBB14_53
__LBB14_24:
    lw t5, -52(fp)
    beq t5, zero, __LBB14_49
__LBB14_25:
    lw t5, -52(fp)
    xori t0, t5, 1
    beq t0, zero, __LBB14_45
__LBB14_26:
    lw t5, -52(fp)
    xori t0, t5, 2
    beq t0, zero, __LBB14_42
__LBB14_27:
    lw t5, -52(fp)
    xori t0, t5, 3
    beq t0, zero, __LBB14_38
__LBB14_28:
    lw t5, -52(fp)
    xori t0, t5, 4
    beq t0, zero, __LBB14_35
__LBB14_29:
    b __LBB14_31
__LBB14_30:
    hlt
__LBB14_31:
    lw t5, -44(fp)
    andi t0, t5, 255
    li t1, 5
    bgeu t1, t0, __LBB14_33
__LBB14_32:
    lw t5, -44(fp)
    subi t0, t5, 5
    lw t5, -52(fp)
    addi t1, t5, 0
    b __LBB14_34
__LBB14_33:
    addi t0, zero, 0
    addi t1, zero, 0
__LBB14_34:
    addi s1, t0, 0
    lw t5, -60(fp)
    addi s6, t5, 0
    lw t5, -48(fp)
    addi s3, t5, 0
    addi s10, t1, 0
    b __LBB14_52
__LBB14_35:
    lw t5, -48(fp)
    addi t5, t5, 5
    sw t5, -92(fp)
    lw t5, -92(fp)
    andi t0, t5, 255
    li t1, 255
    bltu t0, t1, __LBB14_77
__LBB14_36:
    li t0, 255
    li t1, 5
    addi t5, t0, 0
    sw t5, -96(fp)
    addi t5, t1, 0
    sw t5, -100(fp)
__LBB14_37:
    lw t5, -44(fp)
    addi s1, t5, 0
    lw t5, -60(fp)
    addi s6, t5, 0
    lw t5, -96(fp)
    addi s3, t5, 0
    lw t5, -100(fp)
    addi s10, t5, 0
    b __LBB14_52
__LBB14_38:
    lw t5, -60(fp)
    andi t0, t5, 255
    li t1, 5
    bgeu t1, t0, __LBB14_40
__LBB14_39:
    lw t5, -60(fp)
    subi t0, t5, 5
    lw t5, -52(fp)
    addi t1, t5, 0
    b __LBB14_41
__LBB14_40:
    li t2, 4
    addi t0, zero, 0
    addi t1, t2, 0
__LBB14_41:
    lw t5, -44(fp)
    addi s1, t5, 0
    addi s6, t0, 0
    lw t5, -48(fp)
    addi s3, t5, 0
    addi s10, t1, 0
    b __LBB14_52
__LBB14_42:
    lw t5, -44(fp)
    addi t5, t5, 5
    sw t5, -104(fp)
    lw t5, -104(fp)
    andi t0, t5, 255
    li t1, 255
    bltu t0, t1, __LBB14_78
__LBB14_43:
    li t0, 255
    li t1, 3
    addi t5, t0, 0
    sw t5, -108(fp)
    addi t5, t1, 0
    sw t5, -112(fp)
__LBB14_44:
    lw t5, -108(fp)
    addi s1, t5, 0
    lw t5, -60(fp)
    addi s6, t5, 0
    lw t5, -48(fp)
    addi s3, t5, 0
    lw t5, -112(fp)
    addi s10, t5, 0
    b __LBB14_52
__LBB14_45:
    lw t5, -48(fp)
    andi t0, t5, 255
    li t1, 5
    bgeu t1, t0, __LBB14_47
__LBB14_46:
    lw t5, -48(fp)
    subi t0, t5, 5
    lw t5, -52(fp)
    addi t1, t5, 0
    b __LBB14_48
__LBB14_47:
    li t2, 2
    addi t0, zero, 0
    addi t1, t2, 0
__LBB14_48:
    lw t5, -44(fp)
    addi s1, t5, 0
    lw t5, -60(fp)
    addi s6, t5, 0
    addi s3, t0, 0
    addi s10, t1, 0
    b __LBB14_52
__LBB14_49:
    lw t5, -60(fp)
    addi t5, t5, 5
    sw t5, -116(fp)
    lw t5, -116(fp)
    andi t0, t5, 255
    li t1, 255
    bltu t0, t1, __LBB14_79
__LBB14_50:
    li t0, 255
    li t1, 1
    addi t5, t0, 0
    sw t5, -120(fp)
    addi t5, t1, 0
    sw t5, -124(fp)
__LBB14_51:
    lw t5, -44(fp)
    addi s1, t5, 0
    lw t5, -120(fp)
    addi s6, t5, 0
    lw t5, -48(fp)
    addi s3, t5, 0
    lw t5, -124(fp)
    addi s10, t5, 0
__LBB14_52:
    addi a0, s3, 0
    addi a1, s6, 0
    addi a2, s1, 0
    lw t5, -16(fp)
    addi a3, t5, 0
    bl ra, __z9SetWS2812u8u8u8u8
    addi s7, s1, 0
    addi s11, s6, 0
    addi s2, s3, 0
    addi s8, s10, 0
__LBB14_53:
    lw t5, -56(fp)
    sw t5, -128(fp)
    addi t5, s7, 0
    sw t5, -132(fp)
    addi t5, s11, 0
    sw t5, -136(fp)
    addi s7, s8, 0
__LBB14_54:
    bl ra, __z12HasCharacter
    andi t0, a0, 1
    beq t0, zero, __LBB14_80
__LBB14_55:
    bl ra, __z13ReadCharacter
    addi s8, a0, 0
    slli t0, s8, 24
    srai t0, t0, 24
    slti t0, t0, 49
    xori t0, t0, 1
    slli t1, s8, 24
    srai t1, t1, 24
    li t2, 54
    slt t1, t2, t1
    xori t1, t1, 1
    and t0, t0, t1
    andi t0, t0, 1
    bne t0, zero, __LBB14_69
__LBB14_56:
    andi t0, s8, 255
    xori t0, t0, 43
    beq t0, zero, __LBB14_65
__LBB14_57:
    andi t0, s8, 255
    xori t0, t0, 45
    beq t0, zero, __LBB14_61
__LBB14_58:
    b __LBB14_60
__LBB14_59:
    hlt
__LBB14_60:
    addi a0, s8, 0
    bl ra, __z14WriteCharacteri8
    lw t5, -40(fp)
    addi s10, t5, 0
    lw t5, -28(fp)
    addi s11, t5, 0
    lw t5, -16(fp)
    addi s1, t5, 0
    lw t5, -20(fp)
    addi s3, t5, 0
    b __LBB14_70
__LBB14_61:
    lw t5, -16(fp)
    andi t0, t5, 255
    li t1, 8
    bgeu t1, t0, __LBB14_63
__LBB14_62:
    lw t5, -16(fp)
    subi t0, t5, 8
    addi s6, t0, 0
    b __LBB14_64
__LBB14_63:
    addi s6, zero, 0
__LBB14_64:
    la a0, string.14
    bl ra, __z5WritePi8
    andi a0, s6, 255
    bl ra, __z12WriteIntegeru32
    la a0, string.15
    bl ra, __z5WritePi8
    addi s10, s6, 0
    lw t5, -28(fp)
    addi s11, t5, 0
    addi s1, s6, 0
    lw t5, -20(fp)
    addi s3, t5, 0
    b __LBB14_70
__LBB14_65:
    lw t5, -16(fp)
    andi t0, t5, 255
    li t1, 247
    bgeu t0, t1, __LBB14_67
__LBB14_66:
    lw t5, -16(fp)
    addi t0, t5, 8
    addi s6, t0, 0
    b __LBB14_68
__LBB14_67:
    li t0, 255
    addi s6, t0, 0
__LBB14_68:
    la a0, string.14
    bl ra, __z5WritePi8
    andi a0, s6, 255
    bl ra, __z12WriteIntegeru32
    la a0, string.15
    bl ra, __z5WritePi8
    lw t5, -40(fp)
    addi s10, t5, 0
    addi s11, s6, 0
    addi s1, s6, 0
    lw t5, -20(fp)
    addi s3, t5, 0
    b __LBB14_70
__LBB14_69:
    subi t0, s8, 49
    li t1, 1
    sll t0, t1, t0
    lw t5, -20(fp)
    xor s6, t5, t0
    addi a0, s6, 0
    bl ra, __z7SetLEDsi8
    lw t5, -40(fp)
    addi s10, t5, 0
    lw t5, -28(fp)
    addi s11, t5, 0
    lw t5, -16(fp)
    addi s1, t5, 0
    addi s3, s6, 0
__LBB14_70:
    addi s6, s10, 0
    addi s10, s11, 0
__LBB14_71:
    addi t5, s6, 0
    sw t5, -40(fp)
    addi t5, s10, 0
    sw t5, -28(fp)
    addi t5, s8, 0
    sw t5, -24(fp)
    addi t5, s1, 0
    sw t5, -16(fp)
    lw t5, -128(fp)
    sw t5, -64(fp)
    lw t5, -32(fp)
    addi s9, t5, 0
    lw t5, -36(fp)
    sw t5, -88(fp)
    addi t5, s3, 0
    sw t5, -20(fp)
    lw t5, -132(fp)
    sw t5, -44(fp)
    lw t5, -136(fp)
    sw t5, -60(fp)
    addi t5, s2, 0
    sw t5, -48(fp)
    addi t5, s7, 0
    sw t5, -52(fp)
    b __LBB14_6
__LBB14_72:
    lw s11, 0(s5)
    la a0, string.8
    bl ra, __z5WritePi8
    addi a0, s11, 0
    bl ra, __z16WriteHexadecimalu32
    la a0, string.9
    bl ra, __z5WritePi8
    addi a0, s5, 0
    bl ra, __z16WriteHexadecimalu32
    la a0, string.7
    bl ra, __z9WriteLinePi8
    addi t0, s5, 4
__LBB14_73:
    addi t1, s4, 1
    addi s4, t1, 0
    addi s5, t0, 0
    b __LBB14_4
__LBB14_74:
    addi t5, s9, 0
    sw t5, -80(fp)
    lw t5, -88(fp)
    sw t5, -84(fp)
    b __LBB14_12
__LBB14_75:
    lw t5, -76(fp)
    sw t5, -72(fp)
    b __LBB14_11
__LBB14_76:
    lw t5, -64(fp)
    sw t5, -128(fp)
    lw t5, -44(fp)
    sw t5, -132(fp)
    lw t5, -60(fp)
    sw t5, -136(fp)
    lw t5, -48(fp)
    addi s2, t5, 0
    lw t5, -52(fp)
    addi s7, t5, 0
    b __LBB14_54
__LBB14_77:
    lw t5, -92(fp)
    sw t5, -96(fp)
    lw t5, -52(fp)
    sw t5, -100(fp)
    b __LBB14_37
__LBB14_78:
    lw t5, -104(fp)
    sw t5, -108(fp)
    lw t5, -52(fp)
    sw t5, -112(fp)
    b __LBB14_44
__LBB14_79:
    lw t5, -116(fp)
    sw t5, -120(fp)
    lw t5, -52(fp)
    sw t5, -124(fp)
    b __LBB14_51
__LBB14_80:
    lw t5, -40(fp)
    addi s6, t5, 0
    lw t5, -28(fp)
    addi s10, t5, 0
    lw t5, -24(fp)
    addi s8, t5, 0
    lw t5, -16(fp)
    addi s1, t5, 0
    lw t5, -20(fp)
    addi s3, t5, 0
    b __LBB14_71

	.global	__z15_28u32_2C_20u32_2C_20u32_29MRTu32u32u32ERTu32u32u32E
__z15_28u32_2C_20u32_2C_20u32_29MRTu32u32u32ERTu32u32u32E:
__LBB15_0:
    lw t0, 0(a1)
    sw t0, 0(a0)
    lw t0, 4(a1)
    sw t0, 4(a0)
    lw t0, 8(a1)
    sw t0, 8(a0)
    br ra

	.global	__z16_7E_28u32_2C_20u32_2C_20u32_29MRTu32u32u32E
__z16_7E_28u32_2C_20u32_2C_20u32_29MRTu32u32u32E:
__LBB16_0:
    br ra

	.global	__z9operator_3DMRTu32u32u32ERTu32u32u32E
__z9operator_3DMRTu32u32u32ERTu32u32u32E:
__LBB17_0:
    lw t0, 0(a1)
    sw t0, 0(a0)
    lw t0, 4(a1)
    sw t0, 4(a0)
    lw t0, 8(a1)
    sw t0, 8(a0)
    br ra

	.global	__z12_28u8_2C_20u8_2C_20u8_29MRTu8u8u8ERTu8u8u8E
__z12_28u8_2C_20u8_2C_20u8_29MRTu8u8u8ERTu8u8u8E:
__LBB18_0:
    lbu t0, 0(a1)
    sb t0, 0(a0)
    lbu t0, 1(a1)
    sb t0, 1(a0)
    lbu t0, 2(a1)
    sb t0, 2(a0)
    br ra

	.global	__z13_7E_28u8_2C_20u8_2C_20u8_29MRTu8u8u8E
__z13_7E_28u8_2C_20u8_2C_20u8_29MRTu8u8u8E:
__LBB19_0:
    br ra

	.global	__z9operator_3DMRTu8u8u8ERTu8u8u8E
__z9operator_3DMRTu8u8u8ERTu8u8u8E:
__LBB20_0:
    lbu t0, 0(a1)
    sb t0, 0(a0)
    lbu t0, 1(a1)
    sb t0, 1(a0)
    lbu t0, 2(a1)
    sb t0, 2(a0)
    br ra

	.data
	.align	4
	.global	CLK_FREQ
CLK_FREQ:
	.byte	64, 165, 174, 2
string.0:
	.byte	48, 120, 0
string.1:
	.byte	90, 111, 100, 105, 97, 99, 32, 105, 110, 116, 101, 114, 97, 99, 116, 105
	.byte	118, 101, 32, 116, 101, 114, 109, 105, 110, 97, 108, 32, 105, 110, 105, 116
	.byte	105, 97, 108, 105, 122, 101, 100, 33, 0
string.2:
	.byte	84, 121, 112, 101, 32, 97, 110, 121, 116, 104, 105, 110, 103, 32, 116, 111
	.byte	32, 101, 99, 104, 111, 44, 32, 112, 114, 101, 115, 115, 32, 49, 45, 54
	.byte	32, 116, 111, 32, 116, 111, 103, 103, 108, 101, 32, 76, 69, 68, 115, 44
	.byte	32, 111, 114, 32, 43, 47, 45, 32, 116, 111, 32, 99, 104, 97, 110, 103
	.byte	101, 32, 82, 71, 66, 32, 98, 114, 105, 103, 104, 116, 110, 101, 115, 115
	.byte	46, 0
string.3:
	.byte	80, 114, 101, 115, 115, 32, 116, 104, 101, 32, 98, 117, 116, 116, 111, 110
	.byte	32, 111, 110, 32, 116, 104, 101, 32, 98, 111, 97, 114, 100, 32, 116, 111
	.byte	32, 99, 121, 99, 108, 101, 32, 87, 83, 50, 56, 49, 50, 32, 97, 110
	.byte	105, 109, 97, 116, 105, 111, 110, 32, 109, 111, 100, 101, 115, 46, 0
string.4:
	.byte	82, 117, 110, 110, 105, 110, 103, 32, 83, 68, 82, 65, 77, 32, 116, 101
	.byte	115, 116, 46, 46, 46, 0
string.5:
	.byte	87, 114, 105, 116, 116, 101, 110, 32, 0
string.6:
	.byte	32, 116, 111, 32, 0
string.7:
	.byte	46, 0
string.8:
	.byte	82, 101, 97, 100, 32, 0
string.9:
	.byte	32, 102, 114, 111, 109, 32, 0
string.10:
	.byte	83, 68, 82, 65, 77, 32, 116, 101, 115, 116, 32, 102, 97, 105, 108, 101
	.byte	100, 33, 0
string.11:
	.byte	83, 68, 82, 65, 77, 32, 116, 101, 115, 116, 32, 115, 117, 99, 99, 101
	.byte	115, 115, 102, 117, 108, 33, 0
string.12:
	.byte	87, 83, 50, 56, 49, 50, 32, 77, 111, 100, 101, 58, 32, 0
string.13:
	.byte	10, 0
string.14:
	.byte	66, 114, 105, 103, 104, 116, 110, 101, 115, 115, 58, 32, 0
string.15:
	.byte	47, 50, 53, 53, 10, 0
