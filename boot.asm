; ==================================================================
;                           AeroX Bootloader
;   Loads the kernel (kernel.bin for now) to be executed.
;   Uses the FAT12 file system.
;   Subject to change!
; ==================================================================
;
;   Change history:
;   ---------------
;   Riley, 18-09-2026:
;       Worked on load_root function
;   
;   Riley, 17-09-2026:
;       First major bootloader rewrite
;
;   Riley, 16-09-2026:
;       Created boot.asm, completed _start function.
;       Only 16 bit at the moment, looking at how to implement more stuff in the future.
;       Committed to GitHub repo (commit #1)
;

[BITS 16]
[ORG 0x0000]
[CPU 386]

start: jmp main

bpbOEM                  DB "AeroX"      ;   8-byte OEM identifier
bpbBytesPerSector       DW 512          ;   bytes per sector (512)
bpbSectorsPerCluster    DB 1            ;   sectors per allocation unit (also known as clusters!)
bpbReservedSectors      DW 1            ;   includes boot sector
bpbNumberofFATs         DB 2            ;   number of fat copies
bpbRootEntries          DW 224          ;   max root directory entries
bpbTotalSectors         DW 2880         ;   total sectors on disk
bpbMedia                DB 0xF0         ;   media desciptor (0xF0 means removable)
bpbSectorsPerFAT        DW 9            ;   sectors per fat table
bpbSectorsPerTrack      DW 18           ;   sectors per track
bpbHeadsPerCylinder     DW 2            ;   number of heads
bpbHiddenSectors        DD 0            ;   no hidden sectors
bpbTotalSectorsBig      DD 0            ;   no large sectors
bsDriveNumber           DB 0            ;   0 = auto drive number association
bsUnused                DB 0            ;   reserved
bsExtBootSignature      DB 0x29         ;   extended boot signature
bsSerialNumber          DD 0x00000000   ;   volume serial number
bsVolumeLabel           DB "AeroX     " ;   11 byte volume name
bsFileSystem            DB "FAT12  "    ;   8 byte filesystem type

print:
    lodsb
    or al, al
    jz print_done
    mov ah, 0eh
    int 10h
    jmp print
print_done:
    ret

absoluteSector  db 0x00
absoluteHead    db 0x00
absoluteTrack   db 0x00

cluster_lba:
    sub ax, 0x0002                          ;   clusters start at 2 (0 and 1 are reserved)
                                            ;   sub 2 to make it 0 (which is the start of the data area)
    xor cx, cx                              ;   exclusive or on self sets to 0
    mov cl, BYTE [bpbSectorsPerCluster]     ;   find out how many sectors there are in a single cluster
    mul cx                                  ;   in 16-bit, mul targets AX, so this would be AX * CX
                                            ;   (e.g. if cluster was 2, AX was 2, now 0 * sectors = 0 offset)
    add ax, WORD [datasector]               ;   add the global data area offset to get the absolute sector
    ret

lbachs:
    xor dx, dx                              ;   clear dx before division
    div WORD [bpbSectorsPerTrack]           ;   div DX:AX by sectors per track (18)
    inc dl                                  ;   sectors start at 1 (remainders at 0)
    mov BYTE [absoluteSector], dl           ;   save the sector number

    xor dx, dx                              ;   clear dx again for div
    div WORD [bpbHeadsPerCylinder]          ;   div track count by heads per cylinder (2)
    mov BYTE [absoluteHead], dl             ;   remainder is head number
    mov BYTE [absoluteTrack], al
    ret

read_sectors:
.main:
    mov di, 0x0005  ;   read 5 times before fail
.sector_loop:
    push ax
    push bx
    push cx
    call lbachs
    mov ah, 0x02
    mov al, 0x01
    mov ch, BYTE [absoluteTrack]
    mov cl, BYTE [absoluteSector]
    mov dh, BYTE [absoluteHead]
    mov dl, BYTE [bsDriveNumber]
    int 0x13
    jnc .success

    dec di
    pop cx
    pop bx
    pop ax
    jnz .sector_loop
    int 0x18
.success:
    mov si, msg_progress
    call print
    pop cx
    pop bx
    pop ax
    add bx, WORD [bpbBytesPerSector]
    jnc .next

    mov dx, es
    cmp dx, 0x2000
    jne .wrap_fail
    jmp failure
.wrap_fail:
    int 0x18
.next:
    inc ax
    loop .main
    ret

load_root:
    xor cx, cx                          ;   clear cx and dx
    xor dx, dx
    mov ax, 0x0020
    mul WORD [bpbRootEntries]           ;   for reference WORD is 2 bytes (16 bits)
    div WORD [bpbBytesPerSector]
    xchg ax, cx                         ;   exchanges the contents of the destination, AX (0x0020), with the source, CX, 0)
    mov al, BYTE [bpbNumberofFATs]
    mul WORD [bpbNumberofFATs]
    add ax, WORD [bpbReservedSectors]
    mov WORD [datasector], ax
    add WORD [datasector], cx
    mov bx, 0x0200
    call read_sectors

main:
    cli
    mov ax, 0x7C00
    mov es, ax
    mov ax, 0x0000
    mov ss, ax
    mov sp, 0xFFFF
    sti
    mov si, msg_loading
    call print

failure:
    mov si, msg_failure
    call print

datasector dw 0x0000
cluster dw 0x0000

msg_loading db 0x0D, 0x0A, "Perchance, but of course", 0x0D, 0x0A, 0x00
msg_progress db ".", 0x00
msg_failure db 0x0D, 0x0A, "Kernel not found", 0x0D, 0x0A, 0x00

TIMES 510-($-$$) DB 0
DW 0xAA55