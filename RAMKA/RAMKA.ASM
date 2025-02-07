.model tiny
.code
.186
org 100h

DEBUG_OFFSET	equ 880

VIDEOSEG 		equ 0b800h
WC_WIDTH		equ 80
WC_HEIGHT		equ 25
GC_RAMKA_GAP	equ 10
VC_RAMKA_GAP	equ 2

SYM_LF			equ 0ah
SYM_CR			equ 0dh

Start:		
	mov cx, VIDEOSEG
	mov es, cx

	mov di, offset Vstring
	call CountTextSizes


; ;-----------------DEBUG------------------------------
; 	mov byte ptr es:[DEBUG_OFFSET], al
; 	mov byte ptr es:[DEBUG_OFFSET+2], ah
; ;-----------------DEBUG------------------------------

	call RamkaOffset ; set in bx offset in segment
	push bx

	mov di, offset Vsymbols

	call PrintRamka

	pop bx

	mov di, offset Vstring
	call PrintText

	mov ax, 4c00h; end programm
	int 21h

;=====================FUNCS===================

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

PrintText_Cycle:
	mov ch, byte ptr [di] ; remember
	test ch, ch ; check end
je PrintText_CycleEnd
	cmp ch, SYM_CR
jne PrintText_NoNewLine
	add di, 2 ; skip LF

	mov bx, ax
	add bx, WC_WIDTH*2 ; next print line
	mov ax, bx
jmp PrintText_Cycle
PrintText_NoNewLine:
	mov es:[bx], ch ; puts(*di)

	add bx, 2
	inc di ; next symbol
jmp PrintText_Cycle
PrintText_CycleEnd:

	ret
endp

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

CountTextSizes_Cycle:
	mov cl, byte ptr [di] ; remember
	cmp cl, SYM_CR
jne CountTextSizes_NoNewLine
	inc di ; skip LF

	mov dl, ah; update max ah
	mov dh, ch
	call Max
	mov ah, dl

	xor ch, ch

	inc al ; ++count_\n
CountTextSizes_NoNewLine:
	test cl, cl ; is end of text equal zero
je	CountTextSizes_CycleEnd
	inc ch
	inc di
jmp	CountTextSizes_Cycle
CountTextSizes_CycleEnd:

	mov dl, ah; update max ah
	mov dh, ch
	call Max
	mov ah, dl

	ret
endp

;---------------------------------------------
;Descript: 	Print ramka
;Entry: 	AH = max count symbols in text line
;			AL = count \n text
;			BX = ramka offset 
;			DI = Start nine char's types
;			ES = Num segment
;Exit: 		None
;Destroy: 	CX AX BX
;---------------------------------------------
PrintRamka	proc
	add ah, 2*GC_RAMKA_GAP ; set count non repeat symbols

	push bx
	call PrintLine
	pop bx

	add di, 3 ; next triple symbols
	add al, 2*VC_RAMKA_GAP + 1
PrintRamka_Cycle:
	
	add bx, WC_WIDTH*2 ; next line
	push bx
	call PrintLine
	pop bx

	dec al
	or al, al
jne PrintRamka_Cycle

	add di, 3 ; next triple symbols
	add bx, WC_WIDTH*2 ; next line
	call PrintLine

	ret
endp

;---------------------------------------------
;Descript: 	Calculate ramka's offset
;Entry: 	AH = max count symbols in text line
;			AL= count \n text
;Exit: 		BX = ramka's offset
;Destroy: 	CX
;---------------------------------------------
RamkaOffset	proc

	mov bx, WC_WIDTH - (2*GC_RAMKA_GAP + 2) ;calculate gorizontal offset
	mov cl, ah 
	xor ch, ch
	sub bx, cx
	and bx, 11111110b ; for chet
	
	mov cl, WC_HEIGHT - (2*VC_RAMKA_GAP + 2 + 1) + 3 ;calculate vertical offset
	sub cl, al
	and cx, 11111110b ; for chet
	imul cx, WC_WIDTH

	add bx, cx

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
je PrintLine_CycleEnd
PrintLine_Cycle: 
	add bx, 2
	mov cl, byte ptr [di+1]
	mov es:[bx], cl ; puts(di[0])

	dec ch
	or ch, ch
jne PrintLine_Cycle
PrintLine_CycleEnd:

	mov cl, byte ptr [di+2]
	mov es:[bx+2], cl ; puts(di[0])
	ret
endp

;---------------------------------------------
;Descript: 	Get Max
;Entry: 	DL = First
;			DH = Second
;Exit: 		DL = MAX
;Destroy: 	None
;---------------------------------------------
Max	proc
	cmp dl, dh

jge Max_SkipSwap
	mov dl, dh
Max_SkipSwap:

	xor dh, dh

	ret
endp

;---------------------------------------------
;Descript: 	Get Min
;Entry: 	DL = First
;			DH = Second
;Exit: 		DL = MIN
;Destroy: 	None
;---------------------------------------------
Min	proc
	cmp dl, dh

jle Min_SkipSwap
	mov dl, dh
Min_SkipSwap:

	xor dh, dh

	ret
endp

;===================DATA======================
.data
Vsymbols db '+-+|.|+-+'
Vstring db 'Sweat February 14th Valentine!', SYM_CR, SYM_LF, 'Ded lox hihihi', SYM_CR, SYM_LF, 'Mne sosal Stepa Gizunov', 0h
end Start







































Vova loh 