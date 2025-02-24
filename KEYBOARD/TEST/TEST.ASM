.model tiny
.code
.186
locals qq
org 100h

;;; Window
VIDEOSEG 			equ 0b800h

;;; DEBUG
DEBUG_OFFSET		equ 880

;=======================MAIN======================

Start:
    mov bx, 2222h
    mov cx, 3333h
    mov dx, 4444h
    mov si, 5555h
    mov di, 6666h
    mov ax, 7777h
    mov es, ax
    mov ax, 8888h
    mov ds, ax
    ; mov ax, 9999h
    ; mov ss, ax
    mov ax, 1111h
jmp Start

end Start

