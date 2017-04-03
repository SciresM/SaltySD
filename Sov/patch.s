.arm.little

.open "code.bin","code_saltysd.bin",0x100000

.loadtable "unicode.tbl"

mount_sto equ 0x5EF370
open_special_archive equ 0x10C708
register_archive equ 0x1156A4
alloc equ 0x222474
free equ 0x22244C
memcpy equ 0x3004A4
TryOpenFile equ 0x11ED04

; stack vars
str_allocation equ 0x0
 
.org 0x1439E0
; nn::fs::MountSdmc is not present in SoV. Implementation here matches other games.
mount_phtsd:
    push {r3-r5, lr}
        mov r4, r0
        mov r1, #9
        mov r0, sp
        bl open_special_archive
        movs r1, r0,lsr#31
        bne mount_phtsd_exit
        mov r3, #0
        ldr r1, [sp,#0x0]
        mov r2, r3
        mov r0, r4
        bl register_archive
        mov r4, r0
        movs r0, r0,lsr#31
        beq mount_phtsd_exit
        ldr r0, [sp,#0x0]
        ldr r1, [r0]
        ldr r1, [r1, #0x30]
        blx r1
        mov r0, r4
mount_phtsd_exit:
    pop {r3-r5, pc}

; Patch for nn::fs::TryOpenFile
tryopen_payload:
    mov r6, r0
    cmp r4, #0xBA ;magic check
    beq exit
    push {r0-r12, lr}
        sub sp, sp, #0x20
        mov r7, r1 ;input file path
        mov r8, r2
        
        ldrh r3, [r7, #0x0]
        cmp r3, #0x64 ; Explicitly filter data:/
        beq abort
        
        bl check_mount_sd
        mov r0, r7
        
        ; Here we allocate some space for our path,
        ; and then modify it to point to sd_ so that
        ; we can check if it exists
        mov r0, #0x400
        bl alloc
        str r0, [sp, #str_allocation]
        
        ldr r0, [sp, #str_allocation]
        ldr r1, =sdmount_wchar
        mov r2, #(sdmount_wchar_end-sdmount_wchar-2)
        bl memcpy
        
        ldr r0, [sp, #str_allocation]
        add r0, #(sdmount_wchar_end-sdmount_wchar-2)
        mov r1, r7
        ldrh r3, [r7, #0x6]
        cmp r3, #0x3A
        addeq r1, #0xA
        addne r1, #0xC ; Most other archives have 4 letters, ie data:/ vs rom:/
        mov r2, #0x0
        ldr r4, =0x400-(sdmount_wchar_end-sdmount_wchar-2)
        strcpy_top:
            ldrh r3, [r1, r2]
            strh r3, [r0, r2]
            cmp r3, #0x0
            beq strcpy_done
            add r2, r2, #0x2
            cmp r2, r4
            bge strcpy_done
            b strcpy_top
        strcpy_done:        
        mov r0, r6
        ldr r1, [sp, #str_allocation]
        mov r2, r8
        mov r4, #0xBA ;magic check
        bl TryOpenFile
        mov r4, r0
        
        ldr r0, [sp, #str_allocation]
        bl free
        
        ; If we get a 0 result, we have a good file handle
        ; and can return
        cmp r4, #0x0
        beq success

abort:        
        add sp, sp, #0x20
    pop {r0-r12, lr}
exit:
    b TryOpenFile+8
    
success:
    add sp, sp, #0x20
    pop {r0-r12, lr}
    b TryOpenFile+0x8C
    
check_mount_sd:
    push {r0-r4, lr}
        ldr r0, =mount_sto
        ldr r0, [r0]
        cmp r0, #0x0
        bne skip_mount
        ldr r0, =sdmount
        mov r1, #0xF0000001
        bl mount_phtsd
        ldr r0, =mount_sto
        mov r1, #0x1
        str r1, [r0]
        
skip_mount:
    pop {r0-r4, pc}    
    
sdmount: .ascii "sd_:"
.byte 0

sdmount_wchar:
.string "sd_:/saltysd/SoV/"
sdmount_wchar_end:

.pool

; nn::fs::TryOpenFile
.org TryOpenFile+4
    b tryopen_payload
.pool


.Close
