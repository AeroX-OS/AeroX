[BITS 32]

global start
extern main

start:
    call main
    cli
.hang:
    hlt
    jmp .hang
