.model tiny
.code
.186
locals qq
org 100h

; ;-----------------DEBUG------------------------------
; 	mov byte ptr es:[DEBUG_OFFSET], al
; 	mov byte ptr es:[DEBUG_OFFSET+2], ah
; ;-----------------DEBUG------------------------------

DEBUG_OFFSET		equ 880

; Window
VIDEOSEG 			equ 0b800h
WC_WIDTH			equ 80
WC_HEIGHT			equ 25
GC_RAMKA_GAP		equ 10
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

;===================MAIN=========================

Start:
;;; Set num videoseg segment
	mov cx, VIDEOSEG
	mov es, cx

;;; AH = max count symbols in text line
;;; AL = count \n text
	mov di, offset Vstring
	call CountTextSizes

;;; dh = |ah-al|, dl - min(ah, al)
	mov dx, ax
	add dh, GC_RAMKA_GAP*2
	add dl, VC_RAMKA_GAP*2
	call MinMax
	sub dh, dl

;;; Save text sizes
	push ax

;;; Set start ramka sizes in ah, al (min = 0)
	cmp ah, al
jl qqDidSwap
	mov ah, dh
	xor al, al
jmp qqEndDidSwap
qqDidSwap:
	mov al, dh
	xor ah, ah
qqEndDidSwap:


	mov di, offset Vsymbols
	xor cl, cl ; counter
qqZoomRamkaCycle:
	push ax 
	push cx
	push dx
	push di

	call RamkaOffset
	call PrintRamka

;;; Pause
	mov ah, 86h
	mov cx, HUNDRED_MSECONDS1
	; xor cx, cx
	mov dx, HUNDRED_MSECONDS2
	int 15h

	pop di
	pop dx
	pop cx
	pop ax

	add ax, 101h ; inc al, inc ah
	inc cl
	cmp cl, dl
jne qqZoomRamkaCycle

	call RamkaOffset

;;; Save text sizes
	pop ax

	push bx
	mov di, offset Vsymbols
	call PrintRamkaWithGap
	pop bx

	mov di, offset Vstring
	call PrintText

	mov ax, 4c00h; end programm
	int 21h

;=====================FUNCS===================

;---------------------------------------------
;Descript: 	Count sizes of text with 0 in end
;Entry: 	DI = Start text
;Exit: 		AH = max count symbols in text line
;			AL = count \n text
;Destroy: 	DI, CX, DX
;---------------------------------------------
CountTextSizes	proc
	xor ax, ax
	xor cx, cx

qqCycle:
	mov cl, byte ptr [di] ; remember
	cmp cl, SYM_CR
jne qqNoNewLine
	inc di ; skip LF

	mov dl, ah; update max ah
	mov dh, ch
	call MinMax
	mov ah, dh

	xor ch, ch

	inc al ; ++count_\n
qqNoNewLine:
	test cl, cl ; is end of text equal zero
je	qqCycleEnd
	inc ch
	inc di
jmp	qqCycle
qqCycleEnd:

	mov dl, ah; update max ah
	mov dh, ch
	call MinMax
	mov ah, dh

	ret
endp

;---------------------------------------------
;Descript: 	Print ramka with gap
;Entry: 	AH = max count symbols in text line
;			AL = count \n text
;			BX = ramka offset 
;			DI = Start nine char's types
;			ES = Num segment
;Exit: 		None
;Destroy: 	CX AX BX DI
;---------------------------------------------
PrintRamkaWithGap	proc
	add ah, 2*GC_RAMKA_GAP ; set count non repeat symbols
	add al, 2*VC_RAMKA_GAP + 1

	call PrintRamka

	ret
endp

;---------------------------------------------
;Descript: 	Print ramka
;Entry: 	AH = width - 2
;			AL = height - 2
;			BX = ramka offset 
;			DI = Start nine char's types
;			ES = Num segment
;Exit: 		None
;Destroy: 	CX AL BX DI
;---------------------------------------------
PrintRamka	proc

	push bx
	call PrintLine
	pop bx

	add di, 3 ; next triple symbols
	test al, al
je qqCycleEnd
qqCycle:
	add bx, WC_WIDTH*2 ; next line
	push bx
	call PrintLine
	pop bx

	dec al
	test al, al
jne qqCycle
qqCycleEnd:

	add di, 3 ; next triple symbols
	add bx, WC_WIDTH*2 ; next line
	call PrintLine

	ret
endp

;---------------------------------------------
;Descript: 	Print line
;Entry: 	AH = count non repeat symbols
;			BX = Offset in segment for start print
;			DI = Start three char's types
;			ES = Num segment
;Exit: 		None
;Destroy: 	CX BX
;---------------------------------------------
PrintLine	proc
	mov cl, byte ptr [di]
	mov es:[bx], cl ; puts(di[0])

	mov ch, ah ; for cycle
	or ch, ch
je qqCycleEnd
qqCycle: 
	add bx, 2
	mov cl, byte ptr [di+1]
	mov es:[bx], cl ; puts(di[0])

	dec ch
	or ch, ch
jne qqCycle
qqCycleEnd:

	mov cl, byte ptr [di+2]
	mov es:[bx+2], cl ; puts(di[0])
	ret
endp

;---------------------------------------------
;Descript: 	Calculate ramka's offset
;Entry: 	AH = width
;			AL = height
;Exit: 		BX = ramka's offset
;Destroy: 	CX
;---------------------------------------------
RamkaOffset	proc

	; mov bx, WC_WIDTH - (2*GC_RAMKA_GAP + 2) ;calculate gorizontal offset
	mov bx, WC_WIDTH ;calculate gorizontal offset
	mov cl, ah 
	xor ch, ch
	sub bx, cx
	and bx, 11111110b ; for chet
	
	; mov cl, WC_HEIGHT - (2*VC_RAMKA_GAP + 2 + 1) + 3 ;calculate vertical offset
	mov cl, WC_HEIGHT ;calculate vertical offset
	sub cl, al
	and cx, 11111110b ; for chet
	imul cx, WC_WIDTH

	add bx, cx

	ret
endp

;---------------------------------------------
;Descript: 	print text with 0 in end
;Entry: 	BX = ramka offset 
;			DI = Start text
;Exit: 		None
;Destroy: 	DI, BX, CH, AX
;---------------------------------------------
PrintText 	proc
	add bx, (VC_RAMKA_GAP + 1)*WC_WIDTH*2 + (GC_RAMKA_GAP+1)*2; add padding in ramka
	
	mov ax, bx

qqCycle:
	mov ch, byte ptr [di] ; remember
	test ch, ch ; check end
je qqCycleEnd
	cmp ch, SYM_CR
jne qqNoNewLine
	add di, 2 ; skip LF

	mov bx, ax
	add bx, WC_WIDTH*2 ; next print line
	mov ax, bx
jmp qqCycle
qqNoNewLine:
	mov es:[bx], ch ; puts(*di)

	add bx, 2
	inc di ; next symbol
jmp qqCycle
qqCycleEnd:

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

;===================DATA======================
.data
Vsymbols db '+-+|.|+-+'
Vstring db 'Sweat February 14th Valentine!', SYM_CR, SYM_LF, \
		   'Ded lox hihihi', SYM_CR, SYM_LF, \
		   'Mne sosal Stepa Gizunov', SYM_CR, SYM_LF,\
		   'Masik kupi mne mashinku!!!', SYM_HEART, \
		   0h
end Start