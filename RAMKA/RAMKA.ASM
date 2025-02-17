.model tiny
.code
.186
locals qq
org 100h

; ;-----------------DEBUG--------------------------
; 	mov cx, VIDEOSEG
; 	mov es, cx
; 	mov byte ptr es:[DEBUG_OFFSET], bl
; 	mov byte ptr es:[DEBUG_OFFSET+2], bh

;     mov di, DEBUG_OFFSET+4
;     xor cx, cx
;     mov cl, bh
;     mov si, offset StringSizes
; qqCycle:
;     mov al, byte ptr [si]
;     stosb
;     add di, 2
;     inc si
; loop qqCycle
; ;-----------------DEBUG--------------------------

DEBUG_OFFSET		equ 880

; Window
VIDEOSEG 			equ 0b800h
WC_WIDTH			equ 80
WC_HEIGHT			equ 25
GC_RAMKA_GAP		equ 4
VC_RAMKA_GAP		equ 2

;Symbols
SYM_LF				equ 0ah
SYM_CR				equ '\'
SYM_HEART			equ 03h

;Times
TWO_SECONDS1		equ 1eh
TWO_SECONDS2		equ 8480h
ONE_SECONDS1		equ 0fh
ONE_SECONDS2		equ 4240h
HUNDRED_MSECONDS1	equ 1h
HUNDRED_MSECONDS2	equ 86A0h
TEN_MSECONDS		equ 2710h

;Options
ARGS_ADDR           equ 80h

;=======================MAIN======================

Start:
    call GetOpt

    push ax                 ; save color
    mov di, offset String
    call CountTextSizes
    mov cx, dx

    add cx, (2*GC_RAMKA_GAP) + 2
    add bx, (2*VC_RAMKA_GAP) + 2
    mov ax, VIDEOSEG
	mov es, ax
    mov si, offset Symbols
    pop ax                  ; save color

    push cx
    push bx
    call ZoomRamka
    pop bx
    pop cx

    call CountRamkaOffset

    add di, (1+VC_RAMKA_GAP)*WC_WIDTH*2 ; border + gap
    mov si, offset String
    mov bx, offset StringSizes

    call PrintText

    mov ax, 4c00h           ; end programm
	int 21h

;=======================FUNCS======================
;---------------------------------------------
;Descript: 	color style[1-6] ?+-+|.|+-+ message
;Entry: 	None
;Exit: 		AH = color
;           SI = symbols for ramka  (fill Symbols)
;           DI = string             (fill String)
;Destroy: 	
;---------------------------------------------
GetOpt proc
;;; set default
    mov ah, 00001111b

;;; set bx and dl
    mov bx, ARGS_ADDR
    mov dl, byte ptr [bx]
    test dl, dl
je qqExit
    dec dl
    add bx, 2

;;; set color
    mov ah, byte ptr [bx]
    sub dl, 2
    test dl, dl
je qqExit
    add bx, 2

;;; set style
    mov dh, byte ptr [bx]
    sub dh, '0'
    cmp dh, 1
je qqStyle1
    cmp dh, 2
je qqStyle2
    cmp dh, 3
je qqStyle3
    cmp dh, 4
je qqStyle4
    cmp dh, 5
je qqStyle5
    cmp dh, 6
je qqStyle6
qqStyleEnd:
    mov di, offset Symbols  ; dest movsb
    mov cx, 9               ; count symbols
    rep movsb
    sub dl, 2
    test dl, dl
je qqExit
    add bx, 2

;;; set string
    mov cl, dl              ; count symbols in string
    mov si, bx              ; source movsb
    mov di, offset String   ; dest movsb
    rep movsb
jmp qqExit

qqExit:
    mov si, offset Symbols
    mov di, offset String
    ret


qqStyle1:
    mov si, offset Symbols1
jmp qqStyleEnd

qqStyle2:
    mov si, offset Symbols2
jmp qqStyleEnd

qqStyle3:
    mov si, offset Symbols3
jmp qqStyleEnd

qqStyle4:
    mov si, offset Symbols4
jmp qqStyleEnd

qqStyle5:
    mov si, offset Symbols5
jmp qqStyleEnd

qqStyle6:
    sub dl, 9
    add bx, 2
    mov si, bx
    add bx, 9-1             ; minus space
jmp qqStyleEnd

endp

;---------------------------------------------
;Descript: 	Count sizes of text with 0 in end,
;           Max size of line - WC_WIDTH
;Entry: 	ES:DI = Start text
;Exit: 		DX = max count symbols in text line
;			BX = count text line
;			fill string_sizes
;Destroy: 	DI, AX, CX, DX, BX
;---------------------------------------------
CountTextSizes	proc

	xor bx, bx			; bx = 0
    xor dx, dx          ; dx = 0

qqCycle:
	inc bx				; ++bx (new line)

	mov cx, WC_WIDTH 	; set counter
    mov al, SYM_CR 		; Stop symbol
	repne scasb			; while(es:[di++] != al && cx != 0) 

;;; ax = WC_WIDTH - 1 - cx (line size)
	mov ax, WC_WIDTH - 1
	sub ax, cx

;;; dx max= ax
    cmp dx, ax
jge qqSkipSwap
    mov dx, ax
qqSkipSwap:

;;; *StingSizes + (2*(bx-1)) = ax
    push bx
    dec bx
    shl bx, 1
    add bx, offset StringSizes
    mov word ptr [bx], ax
    pop bx

	cmp byte ptr [di], '$'
jne qqCycle

	ret
endp

;---------------------------------------------
;Descript: 	Calculate ramka's offset
;Entry: 	CX = width
;			BX = height
;Exit: 		DI = ramka's offset
;Destroy: 	AX
;---------------------------------------------
CountRamkaOffset	proc

;;; calculate gorizontal offset
;;; (WC_WIDTH - CX)*2/2
	mov di, WC_WIDTH
	sub di, cx
    and di, 0FFFEh          ; for chet
	
;;; calculate vertical offset
;;; ((WC_HEIGHT - BX + 2)*2/2)*WC_WIDTH
	mov ax, WC_HEIGHT 
	sub ax, bx
    add ax, 2               ; because scroll
	and ax, 0FFFEh          ; for chet
	imul ax, WC_WIDTH

	add di, ax

	ret
endp

;---------------------------------------------
;Descript: 	print small versions ramka without 
;           text up to the present size
;Entry: 	AH = color
;			CX = final width
;           BX = final height
;           SI = Start nine char's types
;           ES = videoseg
;Exit: 		None
;Destroy: 	BX, CX, DX
;---------------------------------------------
ZoomRamka	proc

;;; dx = min(cx, bx)
;;; min(cx, bx) = 0
;;; max(cx, bx) -= min(cx, bx)
    cmp cx, bx
jle qqWidthGreater
    sub cx, bx
    mov dx, bx
    xor bx, bx
jmp qqEndSwap
qqWidthGreater:
    sub bx, cx
    mov dx, cx
    xor cx, cx
qqEndSwap:


qqCycle:
;;; next size
	inc cx 
    inc bx

	push ax
    push bx
    push cx
	push dx
	push si

    push ax
	call CountRamkaOffset
    pop ax
    dec bx
	call PrintRamka

;;; Pause
	mov ah, 86h
	mov cx, HUNDRED_MSECONDS1
	mov dx, HUNDRED_MSECONDS2
	int 15h

	pop si
	pop dx
    pop cx
    pop bx
	pop ax

    dec dx
	test dx, dx
jne qqCycle

	ret
endp

;---------------------------------------------
;Descript: 	Print ramka
;Entry: 	AH = color
;           CX = width - 2
;			BX = height - 1
;           ES:DI = videoseg start place
;			SI = Start nine char's types
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
;           SI = three char's types
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
;Descript: 	print text with $ in end
;           lines separate with SYM_CR
;Entry: 	DS:SI = text
;           DS:BX = string sizes
;			ES:DI = RAMKA videoseg start place
;           CX = ramka width
;Exit: 		None
;Destroy: 	
;---------------------------------------------
PrintText 	proc
	
qqCycle:
    push di
    call PrintTextLine
    pop di

    add di, WC_WIDTH*2      ; next videoseg line
    add bx, 2               ; next line size

    cmp byte ptr [si], '$'
jne qqCycle

	ret
endp

;---------------------------------------------
;Descript: 	print text line with SYM_CR in end
;Entry: 	DS:SI = text
;           DS:BX = address string size
;			ES:DI = RAMKA videoseg start place
;                 + count_prev_lines*WC_WIDTH
;           CX = ramka width
;Exit: 		SI = symbol in line after SYM_CR
;Destroy: 	DI
;---------------------------------------------
PrintTextLine 	proc

;;; add gorizontal padding
;;; (cx - [bx] + 1)*2/2
    add di, cx
    sub di, word ptr ds:[bx]
    add di, 2
    and di, 0FFFEh  ; for chet

qqCycle:
    movsb

    inc di          ; skip color byte
    cmp byte ptr ds:[si], SYM_CR
jne qqCycle
    inc si          ; next sym

	ret
endp

.data
Symbols1 db '+-+| |+-+'
Symbols2 db '~~~| |~~~'
Symbols3 db '@*@| |@*@'
Symbols4 db '///| |///'
Symbols5 db '%%%| |%%%'
Symbols  db '000000000'
String db 	'Sweat February 14th Valentine!', SYM_CR, \
		   'Ded lox hihihi', SYM_CR, \
		   'Mne sosal Stepa Gizunov', SYM_CR, \
		   'Masik kupi mne mashinku!!!', SYM_HEART, SYM_CR, \
		   '$'
StringSizes:

end Start