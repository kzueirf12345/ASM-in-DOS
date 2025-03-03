.model tiny
.186
.code
org 100h

Main:
    mov ax, 0h
    mov es, ax
    mov bx, 21h*4

    cli                                 ; Start of changing

    mov ax, word ptr es:[bx]
    mov RealDOSOfs, ax
    mov ax, word ptr es:[bx+2]
    mov RealDOSSeg, ax                  ; Save the address of previous Time Controller
    mov es:[bx], offset DOSint
    mov es:[bx+2], cs                   ; Load the address of my Time Controller

    sti                                 ; End of changing

    mov ax, 3100h
    mov dx, offset EndLabel
    shr dx, 4
    inc dx
    int 21h                             ; Stop and stay resident

DOSint  proc

    cmp ah, 09h
    je Rofl

Continue:
    db 0eah                             ; Jump to real DOS int Controller
RealDOSOfs dw 0h
RealDOSSeg dw 0h

Rofl:
    inc cs:[Count]

    cmp cs:[Count], 03h
    je Lomaem

    jmp Continue

Lomaem:

    push ax bx es

    mov ax, 0h
    mov es, ax
    mov bx, 21h*4

    mov ax, cs:[RealDOSOfs]
    mov es:[bx], ax
    mov ax, cs:[RealDOSSeg]
    mov es:[bx+2], ax

    pop es bx ax

    pop cs:[Save_ip]
    push 013dh

    push ax
    mov ax, 20h
    out 20h, ax
    pop ax

    retf 2

endp

Count db 0h
Save_cs dw 0h
Save_ip dw 0h

EndLabel:

end Main