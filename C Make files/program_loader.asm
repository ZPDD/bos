.text
.global _start
_start:
    call main
    mov $0x0,%edx
    int $0xFF
