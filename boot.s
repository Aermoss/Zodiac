.text
.global _start
.extern main

_start:
    li x31, 0x4000
    bl x30, main
    hlt
