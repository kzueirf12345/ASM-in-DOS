.model tiny
.code
.186
locals qq
org 100h

;;; Window
VIDEOSEG 			equ 0b800h
WC_WIDTH			equ 80
WC_HEIGHT			equ 25
GC_RAMKA_GAP		equ 4
VC_RAMKA_GAP		equ 2

;;; DEBUG
DEBUG_OFFSET		equ 880
DEBUG_COLOR_NB      equ 01101110b
DEBUG_COLOR_B       equ 11101110b

;;; Interapts
KEYBORARD_PORT      equ 60h
ESCAPE_SCANCODE     equ 1
KEYBOARD_INT        equ 09h
TIMER_INT           equ 08h
ABS_ADDR_SIZE       equ 4

;;; Other
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

    push ax                                         ; save old regs state

    in al, KEYBORARD_PORT                           ; al - clicked key
    cmp al, HOTKEY
jne qqRetHandling

    xor cs:IsActive, 0FFh

qqRetHandling:
;;; return system handling keyboard interapts
    pop ax                                          ; save old regs state
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
 
;;; print ramka

;;; set normal dataseg
    push cs
    pop ds

    mov ax, VIDEOSEG                                ; es - videoseg for PrintRamka
    mov es, ax
    xor di, di                                      ; di - offset ramka for PrintRamka
    mov si, offset Symbols                          ; si - ramka's symbols for PrintRamka
    mov ah, DEBUG_COLOR_NB                          ; ah - color for PrintRamka
    mov cx, 10-2                                    ; cx - ramka's width for PrintRamka
    mov bx, 5-1                                     ; bx - ramka's height for PrintRamka

    call PrintRamka 

    pop ds es di si dx cx bx ax                     ; save old regs state

qqRetHandling:
;;; return system handling Timer interapts
db 0eah                                             ; long jump
Old08Of     dw 0                                    ; offset in seg for jump
Old08Seg    dw 0                                    ; seg for jump

endp

;---------------------------------------------
;Descript: 	Print ramka
;Entry: 	AH = color
;           CX = width - 2
;			BX = height - 1
;           ES:DI = videoseg start place
;			DS:SI = Start nine char's types
;Exit: 		
;Destroy: 	AL, BX, CX, DI, SI
;---------------------------------------------
PrintRamka	proc

    push cx
    push di
	call PrintLine
    pop di
    pop cx

	add si, 3           ; next triple symbols
	test bx, bx
je qqCycleEnd
qqCycle:
	add di, WC_WIDTH*2  ; next line

    push cx
    push di
	call PrintLine
    pop di
    pop cx

	dec bx
	test bx, bx
jne qqCycle
qqCycleEnd:

	add si, 3           ; next triple symbols
	add bx, WC_WIDTH*2  ; next line
	call PrintLine

	ret
endp

;---------------------------------------------
;Descript: 	Print line
;Entry: 	CX = count non repeat symbols
;           AH = color
;           DS:SI = three char's types
;			ES:DI = videoseg start place
;Exit: 		DI = address after last printed symbol
;Destroy: 	AL, CX
;---------------------------------------------
PrintLine	proc

    mov al, [si]
    stosw

    mov al, [si+1]
    rep stosw

	mov al, [si+2]
    stosw

	ret
endp

.data
IsActive    db 00h
Symbols     db '+-+| |+-+'

.code
NEEOP:
end Start