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

;Symbols
SYM_LF				equ 0ah
SYM_CR				equ 0dh

;;; Other
PASSWORD_SIZE       equ 17

;=======================MAIN======================

Start:
;;; print HelloStr
    mov ah, 09h
    mov dx, offset HelloStr
    int 21h

;;; print EndPasswordStr
    mov dx, offset HelloPasswordStr
    int 21h

;;; read password
    mov ah, 3fh
    xor bx, bx
    mov cx, PASSWORD_SIZE
    mov dx, offset EnteredPassword
    int 21h

    cmp byte ptr EnteredPassword, 0
je qqUlovka1

    mov si, offset EnteredPassword
    mov di, offset Password
    mov cx, PASSWORD_SIZE+1
    repe cmpsb
qqUlovka2:
    mov dx, offset TruthStr
    test cx, cx
je qqTruth
    mov dx, offset LieStr
qqTruth:
    mov ah, 09h
    int 21h

;;; end program
    mov ax, 4c00h
	int 21h

;=======================DATA======================
.data 

HelloStr            db "Hello user, just crack me!", SYM_CR, SYM_LF, '$'
HelloPasswordStr    db "Password: ", '$'

EnteredPassword     db PASSWORD_SIZE DUP (0)

Password            db "Original_password"

TruthStr            db SYM_CR, SYM_LF, "CORRECT", SYM_CR, SYM_LF, '$'
LieStr              db SYM_CR, SYM_LF, "INCORRECT", SYM_CR, SYM_LF, '$'

.code
qqUlovka1:
    xor cx, cx
jmp qqUlovka2

end Start