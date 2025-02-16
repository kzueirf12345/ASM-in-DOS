.model tiny
.code
.186
locals qq
org 100h

; ;-----------------DEBUG--------------------------
; 	mov byte ptr es:[DEBUG_OFFSET], al
; 	mov byte ptr es:[DEBUG_OFFSET+2], ah
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

;-----------------DEBUG--------------------------
	mov cx, VIDEOSEG
	mov es, cx
	mov byte ptr es:[DEBUG_OFFSET], bl
	mov byte ptr es:[DEBUG_OFFSET+2], bh
;-----------------DEBUG--------------------------

    mov ax, 4c00h; end programm
	int 21h

;=======================FUNCS======================

;---------------------------------------------
;Descript: 	Count sizes of text with 0 in end,
;           Max size of line - WC_WIDTH
;Entry: 	ES:DI = Start text
;Exit: 		BH = max count symbols in text line
;			BL = count text line
;			fill string_sizes
;Destroy: 	DI, AL, CX, DX
;---------------------------------------------
CountTextSizes	proc

	xor bh, bh			; bh = 0
    xor dh, dh          ; dh = 0 (counter bl)
	mov al, SYM_CR 		; for scasb

qqCycle:
	inc bh				; ++bh (new line)

	mov cl, WC_WIDTH 	; set counter
	repne scasb			; while(es:[di++] != al && cl != 0) 

;;; dl = WC_WIDTH - cl (line size)
	mov dl, WC_WIDTH - 1
	sub dl, cl

	call MinMax 		; dh max= dl

	cmp byte ptr [di], SYM_LF
je qqCycle

	mov bl, dh
	ret
endp

;---------------------------------------------
;Descript: 	Get Min
;Entry: 	DL = First
;			DH = Second
;Exit: 		DH = MAX
;			DL = MIN
;Destroy:	CH
;---------------------------------------------
MinMax	proc
	cmp dl, dh

jle qqSkipSwap
	mov ch, dl
	mov dl, dh
	mov dh, ch
qqSkipSwap:

	ret
endp

.data
Symbols db '+-+|.|+-+'
String db 	'Sweat February 14th Valentine!', SYM_CR, SYM_LF, \
		   'Ded lox hihihi', SYM_CR, SYM_LF, \
		   'Mne sosal Stepa Gizunov', SYM_CR, SYM_LF,\
		   'Masik kupi mne mashinku!!!', SYM_HEART, SYM_CR, \
		   0h
StringSizes:

end Start