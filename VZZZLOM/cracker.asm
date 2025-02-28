
;Symbols
SYM_LF				equ 0ah
SYM_CR				equ 0dh

Start:
    call Foo1
    call Foo2

    mov ax, 4c00h
    int 21h

;FUNCS

Foo3 proc
    mov ah, 09h
    push cs
    pop ds
    int 21h
    ret
endp

Foo1 proc
    mov dx, offset Hello1
    call Foo3
    ret
endp

Foo2 proc
    call Foo4

endp

Foo4 proc
    pop di
    pop si
    push si
    push di
    mov ah, 0ah
    mov cx, 0005h
qqCycle:
    push 0                                  ; push 0 - x5
    loop qqCycle
    push 0010h
    mov dx, sp                              ; FFEEh
    int 21h

    inc dx
    mov bx, dx
    mov al, ss:[bx]
    inc dx
    mov ah, 0
    add dx, ax                              ; add ss:[bx]
    mov bx, dx
    mov ss:byte ptr[bx], 0
    mov bx, sp
    add bx, 000ch
    push ss:word ptr [bx]
    add bx, 2
    mov ss:[bx], si
endp
;010B
;014A

;DATA
Hello db 'Hello dear user!', SYM_CR, SYM_LF, "Print the password or stay daun:$"
Answer1 db SYM_CR, SYM_LF, 'LEGENDA GONOK$'
Answer2 db SYM_CR, SYM_LF, 'DAUN POIMAN$'

end Start