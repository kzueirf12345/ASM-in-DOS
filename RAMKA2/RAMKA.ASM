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
SYM_CR				equ 0dh
SYM_HEART			equ 03h

;Times
TWO_SECONDS1		equ 1eh
TWO_SECONDS2		equ 8480h
ONE_SECONDS1		equ 0fh
ONE_SECONDS2		equ 4240h
HUNDRED_MSECONDS1	equ 1h
HUNDRED_MSECONDS2	equ 86A0h
TEN_MSECONDS		equ 2710h

;=======================MAIN======================

Start:
    mov di, offset String
    call CountTextSizes

    mov cx, dx
    add bx, (2*VC_RAMKA_GAP)
    add cx, (2*GC_RAMKA_GAP)
    add bx, 2               ; borders
    add cx, 2               ; borders
    call CountRamkaOffset

    dec bx
    mov ax, VIDEOSEG
	mov es, ax
    mov si, offset Symbols
    mov ah, 01101110b

    push cx
    push di
    call PrintRamka
    pop di
    pop cx

    add di, (1+VC_RAMKA_GAP)*WC_WIDTH*2
    mov si, offset String
    mov bx, offset StringSizes

    call PrintText


    mov ax, 4c00h           ; end programm
	int 21h

;=======================FUNCS======================

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

	cmp byte ptr [di], 0h
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
;Descript: 	print text with 0 in end
;           lines separate with SYM_CR, SYM_LF
;           last symbol in last line SYM_CR
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

    cmp byte ptr [si], 0h
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
Symbols db '+-+|.|+-+'
String db 	'Sweat February 14th Valentine!', SYM_CR, \
		   'Ded lox hihihi', SYM_CR, \
		   'Mne sosal Stepa Gizunov', SYM_CR, \
		   'Masik kupi mne mashinku!!!', SYM_HEART, SYM_CR, \
		   0h
StringSizes:

end Start