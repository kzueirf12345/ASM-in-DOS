.model tiny
.code
org 100h
start:
	mov ah, 02h
	mov dx, offset Vstring
	int 21h
	mov ax, 4c00h
	int 21h
Vstring db "Hello world", 0dh, 0ah, "$"
end start