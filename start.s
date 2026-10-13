.text
.global _start
.extern Main

_start:
    li sp, 0x4000
    bl ra, Main
    hlt
