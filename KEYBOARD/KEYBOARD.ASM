.model tiny
.code
.186
locals qq
org 100h

VIDEOSEG 			equ 0b800h

Start:

KeyboardInt proc
    push ax di es

    mov ax, VIDEOSEG
    mov es, ax
    mov ah, 4ch

    in al, 60h
    stosw

    iret
endp

NEEOP:
end Start