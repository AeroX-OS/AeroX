; ==================================================================
;           oh god its time for gdt and all that fun stuff
; ==================================================================

gdt_base:
    dq 0        ;   Null descriptor

    ;   Code Segment Descriptor
    dw 0xFFFF           ;   Limit (bits 0 - 15)
    dw 0x0000           ;   Base (bits 0 - 15)
    db 0x00             ;   Base (bits 16 - 23)
    db 10011010b        ;   Access byte
                        ;   Present, Ring 0, Executable, Readable
    db 11001111b        ;   Flags + Limit
    db 0x00             ;   Base (bits 24-31)

    ;   Data Segment Descriptor
    dw 0xFFFF           ;   Limit (bits 0-15)
    dw 0x0000           ;   Base (bits 0-15)
    db 0x00             ;   Base (bits 16-23)
    db 10010010b        ;   Access byte (Present, Ring 0, Data, Read/Write)
    db 11001111b        ;   Flags + Limit
    db 0x00             ;   Base (bits 24-31)
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_base - 1   ;   Size of GDT (minus 1)
    dd gdt_base                 ;   Physical address of GDT