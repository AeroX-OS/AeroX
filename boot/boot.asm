; ==================================================================
;                           AeroX Bootloader
;           Originally based on the x16-PRos bootloader,
;                     now significantly reworked.
; ==================================================================

[BITS 16]
[ORG 0x7C00]
[CPU 386]

start:
    xor ax, ax              ;   XOR on self is clear, remember that!
    mov ds, ax              ;   [command] [target], [source]. It's backwards. Copies 0 to DS
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00          ;   A stack is where all the data needed by the CPU is essentially "piled" up.
                            ;   Setting the stack pointer (SP) to 0x7C00 means that the TOP of the SP is 0x7C00.
                            ;   This allows the stack to use all the space below this location in memory freely.

    mov [boot_drive], dl    ;   BIOS passes the boot drive number in DL. Save it for later use.

    mov si, msg_loading     ;   SI = Source Index. This register is "useful for stepping through strings or arrays," - Wikipedia
    call print

    mov ah, 0x02            ;   Now we're going to read the second stage of the bootloader from the disk into memory.
                            ;   Reads the sectors.
    mov al, 4               ;   The number of sectors to be read.
    mov ch, 0               ;   Cylinder 0
    mov cl, 2               ;   Sector 2
                            ;   Sector 1 is the boot sector, sector 2 contains the second stage of the bootloader
    mov dh, 0               ;   Drive head 0
    mov dl, [boot_drive]
    mov bx, 0x7E00          ;   Destination offset
    int 0x13
    jc disk_error           ;   If Carry flag is set so an error occured

    jmp 0x0000:0x7E00       ;   Jump execution to stage 2

print:
    lodsb                   ;   Load next byte from SI into AL
    or al, al               ;   Checks for the 0 at the end of a string... (line 59)
    jz print_done           ;   nothing left to print, move on
    mov ah, 0x0E
    int 0x10                ;   Print character
    jmp print               ;   ...and continue till al = 0 (nothing left)

print_done:
    ret

disk_error:
    mov si, msg_error
    call print
    cli                     ;   clear interrupts
.halt:
    hlt
    jmp .halt

boot_drive      db 0
msg_loading     db "Loading ", 0x0D, 0x0A, 0        ;   ...this is the 0 we were talking about! ends the string (line 41)
msg_error       db "Disk error ", 0x0D, 0x0A, 0

TIMES 510-($-$$) DB 0
DW 0xAA55