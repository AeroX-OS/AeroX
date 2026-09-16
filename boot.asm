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

bpbOEM                  DB "AeroX"
bpbBytesPerSector       DW 512
bpbSectorsPerCluster    DB 1
bpbReservedSectors      DW 1
bpbNumberofFATs         DB 2
bpbRootEntries          DW 224
bpbTotalSectors         DW 2880
bpbMedia                DB 0xF0
bpbSectorsPerFAT        DW 9
bpbSectorsPerTrack      DW 18
bpbHeadsPerCylinder     DW 2
bpbHiddenSectors        DD 0
bpbTotalSectorsBig      DD 0
bsDriveNumber           DB 0
bsUnused                DB 0
bsExtBootSignature      DB 0x29
bsSerialNumber          DD 0x00000000
bsVolumeLabel           DB "AeroX"
bsFileSystem            DB "FAT12"

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