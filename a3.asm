#define LCD_LIBONLY
.include "lcd.asm"


;Defining X, Y, Z pointers
.def XH=r27
.def XL=r26
.def YH=r29
.def YL=r28
.def ZH=r31
.def ZL=r30

.cseg
    call lcd_init            ; call lcd_init to Initialize the LCD
    call init_strings        ; copy string from program to data memory

    call init_pointer1        ; Set pointer 1 to point at the start of the display string
    call init_pointer2        ; Set pointer 2 to point at the start of the display string


lp:
    call lcd_clr
;    call display_buffers
    call fill_buffers   
    call display_buffers

    call mov_pointers

    call delay

    jmp lp

done: jmp done

init_strings:
    push r16
    ; copy strings from program memory to data memory
    ldi r16, high(msg1)        ; this the destination
    push r16
    ldi r16, low(msg1)
    push r16
    ldi r16, high(msg1_p << 1) ; this is the source
    push r16
    ldi r16, low(msg1_p << 1)
    push r16
    call str_init            ; copy from program to data
    pop r16                    ; remove the parameters from the stack
    pop r16
    pop r16
    pop r16

    ldi r16, high(msg2)
    push r16
    ldi r16, low(msg2)
    push r16
    ldi r16, high(msg2_p << 1)
    push r16
    ldi r16, low(msg2_p << 1)
    push r16
    call str_init
    pop r16
    pop r16
    pop r16
    pop r16

    pop r16
    ret

display_buffers:

    ; This subroutine sets the position the next
    ; character will be output on the lcd
    ;
    ; The first parameter pushed on the stack is the Y position
    ;
    ; The second parameter pushed on the stack is the X position
    ;
    ; This call moves the cursor to the top left (ie. 0,0)

    push r16

    call lcd_clr

    ldi r16, 0x00
    push r16
    ldi r16, 0x00
    push r16
    call lcd_gotoxy
    pop r16
    pop r16

    ; Now display msg1 on the first line
    ldi r16, high(line1)
    push r16
    ldi r16, low(line1)
    push r16
    call lcd_puts
    pop r16
    pop r16

    ; Now move the cursor to the second line (ie. 0,1)
    ldi r16, 0x01
    push r16
    ldi r16, 0x00
    push r16
    call lcd_gotoxy
    pop r16
    pop r16

    ; Now display msg1 on the second line
    ldi r16, high(line2)
    push r16
    ldi r16, low(line2)
    push r16
    call lcd_puts
    pop r16
    pop r16

    pop r16
    ret



; init_pointer1 subroutine
; Sets line1ptr to point at the start of the display string
; set l1ptr and l2ptr to point at the start of the display strings

init_pointer1:

    push XH
    push XL
    push r17

    ldi    XH, high(l1ptr)        ;Setting X to line1ptr
    ldi XL, low(l1ptr)

    ;storing in little endian
    ldi r17, low(msg1)    ;putting low byte address of msg1 in l1ptr   
    st X+, r17
    ldi r17, high(msg1)    ;putting the high byte address of msg1 in l1ptr
    st X, r17

    pop r17
    pop XL
    pop XH

    ret

; init_pointer2    subroutine
init_pointer2:

    push XH
    push XL
    push r17

    ldi    XH, high(l2ptr)        ;Setting X to line1ptr
    ldi XL, low(l2ptr)
   
    ;storing in little endian
    ldi r17, low(msg2)    ;putting low byte address of msg1 in l1ptr   
    st X+, r17
    ldi r17, high(msg2)    ;putting the high byte address of msg1 in l1ptr
    st X, r17

    pop r17
    pop XL
    pop XH

    ret

   

; fill_buffers subroutine

fill_buffers:

    push XL
    push XH
    push YL
    push YH
    push ZL
    push ZH
    push r16
    push r17
    push r18

    clr r17
    clr r16
    clr r18
    ldi r18, 0x00    ;counter

;First Line
;    ldi    XH, high(l1ptr)        ;Setting Y to l1ptr
;    ldi XL, low(l1ptr)

    ldi    ZH, high(line1)        ;Setting Z to line1
    ldi ZL, low(line1)

;    ld r16, X+
;    mov YL, r16
;    ld r16, X
;    mov YH, r16

    lds YL, l1ptr
    lds YH, l1ptr+1

buffer_lp1:
    ld r17, Y+           
    cpi r17, 0x00   
    brne next1        ;breaks if reached a null terminator

    ;wrap
    ldi YH, high(msg1)
    ldi YL, low(msg1)
    ld r17, Y+
   
next1:   
    st Z+, r17
    inc r18
    cpi r18, 0x10
    brne buffer_lp1

   
    ldi r18, 0x00
    st X, r18        ; setting the null terminator


;Second Line
    ldi    ZH, high(line2)        ;Setting Z to line1
    ldi ZL, low(line2)

    lds YL, l2ptr
    lds YH, l2ptr+1
;Second line

    lds ZL, l2ptr
    lds ZH, l2ptr+1

    adiw ZH:ZL, 0x01

    ld r16, Z
    cpi r16, 0x00        ;hit null terminator
    brne normal2

    ldi    ZH, high(l2ptr)        ;Setting X to line2ptr
    ldi ZL, low(l2ptr)

;storing in little endian
    ldi r16, low(msg2)    ;putting low byte address of msg1 in l1ptr   
    st Z+, r16
    ldi r16, high(msg2)    ;putting the high byte address of msg1 in l1ptr
    st Z, r16
    jmp finish2

normal2:
    sts l2ptr, ZL
    sts l2ptr+1, ZH

finish2:


    pop r16
    pop ZL
    pop ZH

    ret

delay:   
    push r20
    push r21
    push r22
    ldi r20, 0x10   

del1:    nop
        ldi r21,0xFF
del2:    nop
        ldi r22, 0xFF
del3:    nop
        dec r22
        brne del3
        dec r21
        brne del2
        dec r20
        brne del1

    pop r22
    pop r21
    pop r20
           
        ret



; sample strings
; These are in program memory
msg1_p: .db "Hello there, looping?.", 0
msg2_p: .db "Second Line ", 0

.dseg
;
; The program copies the strings from program memory
; into data memory.
; l1ptr and l2ptr index into these strings
;
msg1:    .byte 200
msg2:    .byte 200
; These strings contain the 16 characters to be displayed on the LCD
; Each time through the loop, the pointers l1ptr and l2ptr are incremented
; and then 16 characters are copied into these memory locations
line1:    .byte 17
line2:    .byte 17
; These keep track of where in the string each line currently is
l1ptr:    .byte 2
l2ptr:    .byte 2 
