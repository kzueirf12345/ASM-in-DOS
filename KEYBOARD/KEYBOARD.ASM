.model tiny
.code
.186
locals qq
org 100h

;;; Window
VIDEOSEG 			equ 0b800h
WC_WIDTH			equ 80
WC_HEIGHT			equ 25

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

;;;Sizes
REGINFO_SIZE        equ (5+4)
REG_COUNT           equ 13
GC_RAMKA_GAP		equ 4
VC_RAMKA_GAP		equ 1
RAMKA_WIDTH         equ ((GC_RAMKA_GAP*2)+REGINFO_SIZE)
RAMKA_HEIGHT        equ ((VC_RAMKA_GAP*2)+REG_COUNT)

;;; Other
HOTKEY              equ 2ch                         ; ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ
SYM_ENDLINE         equ 66h

Start:
    jmp StartTrue

;=======================FUNCS======================

;---------------------------------------------
;Descript: 	Func for keyboard interapt. Activate or deactivate print symbol
;Entry: 	None
;Exit: 		None
;Destroy: 	None
;---------------------------------------------
KeyboardInt proc

    push ax cx si di es ds                          ; save old regs state

    in al, KEYBORARD_PORT                           ; al - clicked key
    cmp al, HOTKEY
jne qqRetHandling

    xor byte ptr cs:IsActive, 0FFh

    cmp byte ptr cs:IsActive, 0                     ; was hotkey swithed on false?
je qqNoActive

    mov ax, VIDEOSEG                                ; ds - source ramka videoseg
    mov ds, ax
    xor si, si                                      ; si - source offset ramka
    push cs                                         ; es - dest buffer1 seg
    pop es
    mov di, offset cs:Buffer1                       ; di - dest offset buffer1
    call FillBuffer

jmp qqRetHandling
qqNoActive:

    mov ax, VIDEOSEG                                ; es - dest ramka videoseg
    mov es, ax
    xor di, di                                      ; di - dest offset ramka
    push cs                                         ; ds - source buffer1 seg
    pop ds
    mov si, offset cs:Buffer1                       ; si - source offset buffer1
    call PrintBuffer

qqRetHandling:
;;; return system handling keyboard interapts
    pop ds es di si cx ax                           ; save old regs state
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

    cmp byte ptr cs:IsActive, 0                     ; was hotkey clicked?
je qqRetHandling

    call FillRegsState                              ; ochev
    push ax bx cx dx si di es ds                    ; save old regs state
 
;;; print ramka

;;; set normal dataseg
    push cs
    pop ds

    mov ax, VIDEOSEG                                ; es - videoseg for PrintRamka
    mov es, ax
    xor di, di                                      ; di - offset ramka for PrintRamka
    mov si, offset cs:Symbols                       ; si - ramka's symbols for PrintRamka
    mov ah, DEBUG_COLOR_NB                          ; ah - color for PrintRamka
    mov cx, REGINFO_SIZE+(GC_RAMKA_GAP*2)-2       ; cx - ramka's width for PrintRamka
    mov bx, (REG_COUNT)+(VC_RAMKA_GAP*2)-1        ; bx - ramka's height for PrintRamka

    call PrintRamka 

    xor di, di
    mov si, offset cs:StrAX
    call PrintRegs

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


;---------------------------------------------
;Descript: 	Fill RegsStateStr
;Entry:     All regs with firstly state
;Exit: 		Fill RegsStateStr
;Destroy: 	None
;---------------------------------------------
FillRegsState proc

    push bx cx dx di si es                          ; save regs

    push ax                                         ; save ax

    mov ax, sp                                      ; ax - trully sp val
    add ax, (5+6)*2

;;; push printed regs (without ax)
    push 1111h ss es ds 0cccch bp ax di si dx cx bx

;;; push trully ax
    mov di, sp                                      ; di = sp + (REG_COUNT-1)*2 - ax addr
    add di, (REG_COUNT-1)*2
    push ss:[di]

;;; mov ip in its stack place
    sub di, (1)*2                                   ; di - ip place
    mov si, sp
    add si, (REG_COUNT+8)*2                         ; si - ip addr
    mov si, ss:[si]                                 ; mov ss:[di] = ss:[si]
    mov ss:[di], si

; ;;; mov cs in its stack place
    mov si, sp                                      ; si - cs addr
    add si, (REG_COUNT+9)*2
    sub di, (4)*2                                   ; di - cs place
    mov si, ss:[si]                                 ; mov ss:[di] = ss:[si]
    mov ss:[di], si

    push cs                                         ; for ValToStr
    pop es

    mov di, offset cs:StrAX                         ; for ValToStr

    mov dx, (REG_COUNT)*2                           ; cx - count printed regs * 2 (offset sp)
qqCycle:
    pop ax
    call ValToStr

    sub dx, 2
    test dx, dx
jne qqCycle
    pop ax                                          ; save ax

    pop es si di dx cx bx                           ; save regs

	ret
endp


;---------------------------------------------
;Descript: 	Val to str
;Entry:     ES:DI = start to put str
;           AX = val
;Exit: 		Put string val in DI (skip first 5 symbols and 1 last)
;           DI = next place after put
;Destroy: 	BX, CX
;---------------------------------------------
ValToStr proc
    add di, 5                                       ; skip first 5 symbols

    mov ch, 4*4                                     ; ch - max left offset
    xor cl, cl                                      ; cl=0 - counter cur left offset

qqCycle:
    push ax                                         ; save val
    shl ax, cl                                      ; ax: remove left bytes
    shr ax, 3*4                                     ; ax: remove right bytes
    call DigToStr                                   ; put 1th dig
    pop ax                                          ; save val
    
    add cl, 4                                       ; next left offset
    cmp ch, cl
jne qqCycle

    ret
endp

;---------------------------------------------
;Descript: 	Digit to str
;Entry:
;           ES:DI = place for put str
;           AL = val <= 16
;Exit: 		Put string digit in DI
;           DI = next place after put
;Destroy: 	AL, BX
;---------------------------------------------
DigToStr proc
    xor bx, bx                                      ; bx = al
    mov bl, al

    mov al, byte ptr cs:[offset cs:HexTable + bx]   ; al = HexTable[bx]

    stosb                                           ; es:[di++] = al

    ret
endp

;---------------------------------------------
;Descript: 	Print regs state on videoseg
;Entry:     ES:DI = ramka place in videoseg (left top corner)
;           DS:SI = start info about regs
;Exit: 		None
;Destroy: 	BX, CX, DI, SI
;---------------------------------------------
PrintRegs proc
    add di,  GC_RAMKA_GAP*2                         ; add gorizontal offset

    mov bx, REG_COUNT                               ; bx - regs counter
qqCycle1:
    add di, WC_WIDTH*2                              ; next line to print in videoseg
    push di                                         ; save di

    mov cx, REGINFO_SIZE                            ; cx - reginfo counter
qqCycle2:
    movsb                                           ; es:[di++] = ds:[si++]
    inc di                                          ; skip color byte
loop qqCycle2

    pop di                                          ; save di
    dec bx
    test bx, bx                                     ; if (bx == 0)
jne qqCycle1

    ret
endp

;---------------------------------------------
;Descript: 	Fill buffer
;Entry:     DS:SI = address start ramka for save
;           ES:DI = address start buffer
;Exit: 		Fill buffer
;Destroy: 	AX, CX, SI, DI
;---------------------------------------------
FillBuffer proc
    ; cli

    mov ax, RAMKA_HEIGHT
qqCycle:
    push si
    mov cx, RAMKA_WIDTH
    repne movsw
    pop si

    add si, WC_WIDTH*2
    dec ax
    test ax, ax
jne qqCycle

    ret
endp

;---------------------------------------------
;Descript: 	Print buffer
;Entry:     DS:SI = address start buffer
;           ES:DI = address start ramka print
;Exit: 		Fill buffer
;Destroy: 	AX, CX, SI, DI
;---------------------------------------------
PrintBuffer proc
    ; cli 

    mov ax, RAMKA_HEIGHT
qqCycle:
    push di
    mov cx, RAMKA_WIDTH
    repne movsw
    pop di

    add di, WC_WIDTH*2
    dec ax
    test ax, ax
jne qqCycle

    ret
endp


;=======================DATA======================

HexTable        db '0123456789ABCDEF'

Symbols         db '+-+| |+-+'
IsActive        db 00h

StrAX           db 'AX = 0000' 
StrBX           db 'BX = 0000' 
StrCX           db 'CX = 0000' 
StrDX           db 'DX = 0000' 

StrSI           db 'SI = 0000' 
StrDI           db 'DI = 0000' 
StrSP           db 'SP = 0000' 
StrBP           db 'BP = 0000' 

StrCS           db 'CS = 0000' 
StrDS           db 'DS = 0000' 
StrES           db 'ES = 0000' 
StrSS           db 'SS = 0000'
StrIp           db 'IP = 0000'

SavedFillRegsRet        dw 0001h
SavedIp                 dw 0001h
SavedCs                 dw 0001h
SavedAx                 dw 0001h

Buffer1         db (RAMKA_HEIGHT*RAMKA_WIDTH*2) DUP (11)
; Buffer2         db (RAMKA_HEIGHT*RAMKA_WIDTH*2) DUP (22)

NEEOP:

;=======================MAIN======================

StartTrue:
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

end Start