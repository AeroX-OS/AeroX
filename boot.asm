;   AEROX  |   COPYRIGHT AEROX PROJECT 2026  ;
;   Change history:
;   ---------------
;   Riley, 16-09-2026:
;       Created boot.asm, completed _start function.
;       Only 16 bit at the moment, looking at how to implement more stuff in the future.
;       Committed to GitHub repo (commit #1)

org 0x7C00
bits 16

global _start

_start:
    call clear      ;   clear the screen before anything happens
    xor ax, ax      ;   exclusive or'ing a register again itself causes it to reset
    mov ds, ax      ;   then we copy that empty register to all the other ones...
    mov es, ax      ;   syntax: mov [destination, source]
    mov ss, ax
    mov sp, 0x7C00  ;   sets up a basic stack

    mov si, boot_msg
    call print_string    

    jmp $           ;   on fail jump to self/hang

print_string:
    mov ah, 0xE
.print_loop:
    lodsb           ;   load byte from DS:SI into AL
    cmp al, 0       ;   check null terminator for end of the string
    je .done
    int 0x10        ;   bios video interrupt
    jmp .print_loop ;   loads next character
.done:
    ret

clear:
    pusha
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    popa

    ret

boot_msg: db 13, 10, "Working", 0

times 510-($-$$) db 0
dw 0xAA55