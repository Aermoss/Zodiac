.text
.global _start
.extern Main

_start:
    li x31, 0x4000
    bl x30, Main
    hlt
