; ==================================================================
;                           AeroX Bootloader
;   Loads the kernel (kernel.bin for now) to be executed.
;   Uses the FAT12 file system.
;   Subject to change!
; ==================================================================
;
;   Change history:
;   ---------------
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
    add ax, word [datasector]               ;   add the global data area offset to get the absolute sector
    ret