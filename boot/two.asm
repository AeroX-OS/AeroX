; ==================================================================
;                       AeroX Bootloader Stage 2
;               Brings the CPU into 32-bit protected mode.
; ==================================================================

[BITS 16]
[ORG 0x7E00]

main:
    mov ax, 0x0003          ;   Another clear, get rid of the first stage output
    int 0x10                ;   Still can use BIOS interrupts since we're in 16 bit!!!

    mov si, msg_real_mode
    call print16b           ;   We're still in 16-bit mode, BIOS interrupts will still work.
                            ;   When we enter 32-bit protected, we have to write to the VGA text-mode VRAM
                            ;   if we want to display anything on screen.

    cli                     ;   Disable interrupts
    lgdt [gdt_descriptor]   ;   pointer

    mov eax, cr0            ;   enable protected mode by setting the PE bit in CR0
                            ;   new registers... scary
    or eax, 1
    mov cr0, eax

    jmp dword 0x08:init_pm  ;   0x08 is the offset of the 32-bit code descriptor in the GDT

.halt:
    hlt
    jmp .halt

print16b:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print16b
.done:
    ret

msg_real_mode db 0x0D, 0x0A, "Entering 32-bit protected mode ", 0

; ==================================================================
;               FROM HERE ON 32-BIT PROTECTED MODE
; ==================================================================

[BITS 32]

init_pm:
    mov ax, 0x10        ;   Set up 32-bit segment registers
                        ;   Our data descriptor is at index 0x10...
    mov ds, ax          ;   ...so we copy ax to all the registers we need
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov esp, 0x90000    ;   Secure stack pointer

    call clear_screen

    ;   As I mentioned before (line 10), printing to the screen works a little different in 32-bit mode.
    ;   We can't use BIOS interrupts like in 16-bit mode, so instead we have to write each character to VGA memory directly.
    ;   Each character on screen takes two bytes:
    ;   1.  The character byte;
    ;   2.  The attribute or colour byte.

    mov edi, 0xB8000        ;   VGA text buffer address
    mov esi, msg_prot_mode
    mov ah, 0x0A            ;   Colour attribute
                            ;   This is Light Green (0x0) on Black (0xA)
    
.print:
    lodsb           ;   Load next character from string into AL
    or al, al       ;   Check if there's anything left in the string...
    jz .hang        ;   ...and if not, go to hang because we reached the end of the string
    mov [edi], ax   ;   Write next character + attribute to the buffer
    add edi, 2      ;   Next character cell
    jmp .print

.hang:
    cli
    hlt
    jmp .hang

clear_screen:
    push edi
    push ecx
    push eax

    mov edi, 0xB8000
    mov ecx, 2000       ;   80 x 25
    mov ax, 0x0720      ;   Space character
                        ;   This is light gray on black
    rep stosw

    pop eax
    pop ecx
    pop edi
    ret

msg_prot_mode db "Now running in 32-bit protected mode ", 0

%include "boot/gdt.asm"