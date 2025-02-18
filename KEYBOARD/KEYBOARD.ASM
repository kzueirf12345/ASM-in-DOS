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
TIMER_INT           equ 08h
ABS_ADDR_SIZE       equ 4

HOTKEY              equ 2ch                         ; ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ

;=======================MAIN======================

Start:
    xor ax, ax
    mov es, ax                                      ; es - zero segment
    mov bx, TIMER_INT*ABS_ADDR_SIZE                 ; bx - address ptr on keyboard int

    cli                                             ; OFF system interapts
    mov ax, word ptr es:[bx]                        ; Old08Of = es:[bx]
    mov Old08Of, ax
    mov ax, word ptr es:[bx+2]                      ; Old08Seg = es:[bx+2]
    mov Old08Seg, ax
;;; put TimerInt addr in 08h
    mov word ptr es:[bx], offset TimerInt           ; put offset
    push cs                                         ; put segment
    pop ax
    mov word ptr es:[bx+2], ax

    add bx, 4                                       ; bx - addr keyboard interapt

    mov ax, word ptr es:[bx]                        ; Old09Of = es:[bx]
    mov Old09Of, ax
    mov ax, word ptr es:[bx+2]                      ; Old09Seg = es:[bx+2]
    mov Old09Seg, ax
;;; put KeyboardInt addr in 09h
    mov word ptr es:[bx], offset KeyboardInt        ; put offset
    push cs                                         ; put segment
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
;Descript: 	Func for keyboard interapt. Activate or deactivate print symbol
;Entry: 	None
;Exit: 		None
;Destroy: 	None
;---------------------------------------------
KeyboardInt proc

    push ax bx cx dx si di es ds                    ; save old regs state

    in al, KEYBORARD_PORT                           ; al - clicked key
    cmp al, HOTKEY
jne qqRetHandling

    xor cs:IsActive, 0FFh

qqRetHandling:
;;; return system handling keyboard interapts
    pop ds es di si dx cx bx ax                     ; save old regs state
db 0eah                                             ; long jump
Old09Of     dw 0                                    ; offset in seg for jump
Old09Seg    dw 0                                    ; seg for jump

endp

;---------------------------------------------
;Descript: 	Func for timer interapt. Print clicked symbol
;Entry: 	None
;Exit: 		None
;Destroy: 	None
;---------------------------------------------
TimerInt proc

    cmp cs:IsActive, 0                              ; was hotkey clicked?
je qqRetHandling

    push ax bx cx dx si di es ds                    ; save old regs state
 
;;; print in videoseg clicked key
    mov ax, VIDEOSEG                                ; set es videoseg for stosw
    mov es, ax
    mov di, DEBUG_OFFSET                            ; di = DEBUG_OFFSET
    mov ah, 11101110b                               ; ah - color
    cld

    in al, KEYBORARD_PORT                           ; al - clicked key
    ; mov al, cs:IsActive
    stosw                                           ; print al with ah color on videoseg

    pop ds es di si dx cx bx ax                     ; save old regs state

qqRetHandling:
;;; return system handling Timer interapts
db 0eah                                             ; long jump
Old08Of     dw 0                                    ; offset in seg for jump
Old08Seg    dw 0                                    ; seg for jump

endp

IsActive db 00h

NEEOP:
end Start