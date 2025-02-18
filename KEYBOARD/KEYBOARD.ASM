.model tiny
.code
.186
locals qq
org 100h

VIDEOSEG 			equ 0b800h
DEBUG_OFFSET		equ 880

KEYBORARD_PORT      equ 60h
ESCAPE_SCANCODE     equ 1
KEYBOARD_INT        equ 09h
ABS_ADDR_SIZE       equ 4

;=======================MAIN======================

Start:
    xor ax, ax
    mov es, ax                                      ; es - zero segment
    mov bx, KEYBOARD_INT*ABS_ADDR_SIZE              ; bx - address ptr on keyboard int

    cli                                             ; OFF system interapts

    mov ax, word ptr es:[bx]                        ; Old090f = es:[bx]
    mov Old090f, ax
    mov ax, word ptr es:[bx+2]                      ; Old09Seg = es:[bx+2]
    mov Old09Seg, ax
    mov word ptr es:[bx], offset KeyboardInt        ; put offset in segment
;;; put segment
    push cs
    pop ax
    mov word ptr es:[bx+2], ax

    sti                                             ; ON system interapts


;;; call DOS func for will be resident
    mov ax, 3100h                                   ; ah - number funcs; al = 0 (exit code)
    mov dx, offset NEEOP                            ; dx - count bytes to save
    shr dx, 4                                       ; switch bytes to paragraphs
    inc dx                                          ; for end
    int 21h

;=======================FUNCS======================

;---------------------------------------------
;Descript: 	Func for keyboard interapt. Print clicked symbol
;Entry: 	None
;Exit: 		None
;Destroy: 	None
;---------------------------------------------
KeyboardInt proc

    push ax bx cx dx si di es ds                    ; save old regs state
 
;;; print in videoseg clicked key
    mov ax, VIDEOSEG                                ; set es videoseg for stosw
    mov es, ax
    mov di, DEBUG_OFFSET                            ; di = DEBUG_OFFSET
    mov ah, 11101110b                               ; ah - color
    cld

qqNextKey:
    in al, KEYBORARD_PORT                           ; al - clicked key
    stosw                                           ; print al with ah color on videoseg
    sub di, 2                                       ; return di state after stosw
    cmp al, ESCAPE_SCANCODE
jne qqNextKey

;;; return system handling keyboard interapts
    pop ds es di si dx cx bx ax                     ; save old regs state
db 0eah                                             ; long jump
Old090f     dw 0                                    ; offset in seg for jump
Old09Seg    dw 0                                    ; seg for jump

endp

NEEOP:
end Start