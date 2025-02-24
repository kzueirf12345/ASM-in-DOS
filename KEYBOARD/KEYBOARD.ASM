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
SYM_ENDLINE         equ 66h

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

    xor byte ptr cs:IsActive, 0FFh

qqRetHandling:
;;; return system handling keyboard interapts
    pop ax                                          ; save old regs state
db 0eah                                             ; long jump
Old09Of     dw 0                                    ; offset in seg for jump
Old09Seg    dw 0                                    ; seg for jump

    iret
endp

;---------------------------------------------
;Descript: 	Func for timer interapt. Print clicked symbol
;Entry: 	None
;Exit: 		None
;Destroy: 	None
;---------------------------------------------
TimerInt proc

    cmp byte ptr cs:IsActive, 0                              ; was hotkey clicked?
je qqRetHandling

    push ax bx cx dx si di es ds                    ; save old regs state
 
;;; print ramka
    call FillRegsState                              ; ochev

;;; DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG
    push cs
    pop ds
    mov si, offset cs:StrAX
    mov ax, VIDEOSEG
    mov es, ax
    mov di, DEBUG_OFFSET
    mov cx, (4+5+1)*12
qqCycleDebug:
    movsb
    inc di
loop qqCycleDebug
;;; DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG-DEBUG
    
;;; set normal dataseg
    push cs
    pop ds

    mov ax, VIDEOSEG                                ; es - videoseg for PrintRamka
    mov es, ax
    xor di, di                                      ; di - offset ramka for PrintRamka
    mov si, offset cs:Symbols                       ; si - ramka's symbols for PrintRamka
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

    iret
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


;---------------------------------------------
;Descript: 	Fill RegsStateStr
;Entry:     All regs with firstly state
;Exit: 		Fill RegsStateStr
;Destroy: 	AX, DI, ES
;---------------------------------------------
FillRegsState proc

    mov cs:SavedES, es                              ; save es in var (use like seg for fill place)
    mov cs:SavedDI, di                              ; save di in var (use like offset for fill place)

    push cs                                         ; es = cs for ValToStr
    pop es

    mov di, offset cs:StrAX                         ; for ValToStr

;;; Fill ax (we need't move ax in ax)
    call ValToStr

;;; Fill bx
    mov ax, bx                                      ; ax - printed val
    call ValToStr

;;; Fill cx
    mov ax, cx                                      ; ax - printed val
    call ValToStr

;;; Fill dx
    mov ax, dx                                      ; ax - printed val
    call ValToStr

;;; Fill si
    mov ax, si                                      ; ax - printed val
    call ValToStr

;;; Fill di
    mov ax, word ptr cs:SavedDI                     ; ax - printed val
    call ValToStr

;;; Fill sp
    mov ax, sp                                      ; ax - printed val
    call ValToStr

;;; Fill bp
    mov ax, bp                                      ; ax - printed val
    call ValToStr

;;; Fill cs
    mov ax, cs                                      ; ax - printed val
    call ValToStr

;;; Fill ds
    mov ax, ds                                      ; ax - printed val
    call ValToStr

;;; Fill es
    mov ax, word ptr cs:SavedES                     ; ax - printed val
    call ValToStr

;;; Fill ss
    mov ax, ss                                      ; ax - printed val
    call ValToStr

	ret
endp


;---------------------------------------------
;Descript: 	Val to str
;Entry:     ES:DI = start to put str
;           AX = val
;Exit: 		Put string val in DI (skip first 5 symbols and 1 last)
;           DI = next place after put + skip last 0
;Destroy: 	AX
;---------------------------------------------
ValToStr proc
    add di, 5                                       ; skip first 5 symbols

    push ax                                         ; save val
    shr ax, 3*4                                     ; ax: TFFF -> 000T
    call DigToStr                                   ; put 1th dig
    pop ax                                          ; save val
    
    push ax                                         ; save val
    shl ax, 1*4                                     ; ax: FTFF -> TFF0
    shr ax, 3*4                                     ; ax: TFF0 -> 000T
    call DigToStr                                   ; put 2th dig
    pop ax                                          ; save val

    push ax                                         ; save val
    shl ax, 2*4                                     ; ax: FFTF -> TF00
    shr ax, 3*4                                     ; ax: TF00 -> 000T
    call DigToStr                                   ; put 3th dig
    pop ax                                          ; save val

    shl ax, 3*4                                     ; ax: FFFT -> T000
    shr ax, 3*4                                     ; ax: T000 -> 000T
    call DigToStr                                   ; put 4th dig

    inc di                                          ; skip last line symbol 0
    ret
endp

;---------------------------------------------
;Descript: 	Digit to str
;Entry:
;           ES:DI = place for put str
;           AL = val <= 16
;Exit: 		Put string digit in DI
;           DI = next place after put
;Destroy: 	AL
;---------------------------------------------
DigToStr proc
    cmp al, 09h                                     ; xheck what we need to add
jg qqIsAlpha

    add al, '0'                                     ; val + "0" (0-9)
jmp qqIsDig

qqIsAlpha:
    add al, 'A' - 10                                ; val + "A" - 10 (A-F)

qqIsDig:

    stosb                                           ; ES:[DI++] = AL

    ret
endp

;=======================DATA======================

Symbols         db '+-+| |+-+'
IsActive        db 00h

StrAX           db 'AX = 0000', 0
StrBX           db 'BX = 0000', 0
StrCX           db 'CX = 0000', 0
StrDX           db 'DX = 0000', 0

StrSI           db 'SI = 0000', 0
StrDI           db 'DI = 0000', 0
StrSP           db 'SP = 0000', 0
StrBP           db 'BP = 0000', 0

StrCS           db 'CS = 0000', 0
StrDS           db 'DS = 0000', 0
StrES           db 'ES = 0000', 0
StrSS           db 'SS = 0000', 0, \
                   SYM_ENDLINE

SavedAX         dw 0001h
SavedDI         dw 0001h
SavedES         dw 0001h

NEEOP:
end Start