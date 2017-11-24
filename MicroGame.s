  AREA flash, CODE, READONLY
  EXPORT __Vectors
  EXPORT Reset_Handler

; Vector table: Initial stack and entry point address. PM0056 p. 36
__Vectors
  DCD 0x20000400          ; Intial stack: 1k into SRAM, datasheet p. 11
  DCD Reset_Handler + 1   ; Entry point (+1 for thumb mode)
  SPACE 52
  DCD systick_handler + 1 ; System timer interrupt
  SPACE 24
  DCD ext0_handler + 1    ; IRQ6: external interrupt from EXTI controller

PORTC_ODR  equ 0x4001100c ; Port C output data register
STK_BASE   equ 0xe000e010 ; System timer base address
NVIC_ICPR0 equ 0xe000e280 ; Interrupt clear pending register
EXTI_PR    equ 0x40010414 ; EXTI pending register

SCORE equ 0x20000400 ; Address of current score.
GREEN equ 0x20000404 ; Address of current state.
ROUND equ 0x20000408 ; Address of current round.
COUNT equ 0x20000412 ; Address of current count.
BUTTON equ 0x20000416 ; Address of current button
ROUNDP2 equ 0x20000420

Reset_Handler
  ; Disable interrupts during initialization.
  cpsid i

  ; Enable I/O port clocks
  ldr r0, =0x40021018 ; RCC->apb2enr, see RM0041 p. 84
  mov r1, #0x14       ; Enable clock for I/O ports A and C, and AFIO
  str r1, [r0]        ; Store instruction, see PM0056 p. 61

  ; GPIO Port C bits 8,9: push-pull low speed (2MHz) outputs
  ldr r0, =0x40011004 ; PORTC->crh, see RM0041 p. 111
  ldr r1, =0x22       ; Bits 8/9, 2MHz push/pull; see RM0041 p. 112
  str r1, [r0]

  ; GPIO Port A: all bits: inputs with no pull-up/pull down
  ; This step is technically unnecessary, since the initial state of all
  ; GPIOs is to be floating inputs.
  ldr r0, =0x40010800 ; PORTA->crl, see RM0041 p. 111
  ldr r1, =0x44444444 ; All inputs; RM0041 p. 112
  str r1, [r0]

  ; Set EXTI0 source to Port A
  ldr r0, =0x40010008 ; AFIO->exticr1, see RM0041 p. 124
  ldr r1, [r0]
  bic r1, #0xf        ; Mask out the last 4 bits (set to 0, Port A)
  str r1, [r0]

  ; Set up interrupt on rising edge of port A bit 0 on the EXTI (external
  ; interrupt controller); see RM0041 p. 134
  ldr r0, =0x40010400 ; EXTI base address
  mov r1, #1
  str r1, [r0, #8]    ; EXTI->rtsr; event 0 rising; see RM0041 p. 139
  str r1, [r0, #0]    ; EXTI->imr; unmask line 0

  ; Set up the IRQ in the NVIC. See PM0056 p. 118
  ldr r0, =0xe000e404 ; Address of NVIC->ipr1; PM0056 p. 128
  ldr r1, [r0]        ; NVIC->ipr1; PM0056 p. 125
  bic r1, #0xff0000   ; Zero out bits corresponding to IRQ6
  str r1, [r0]        ; Set IRQ6 priority to 0 (highest)

  ldr r0, =0xe000e100 ; NVIC->iser0; PM0056 p. 120
  mov r2, #0x40       ; Bit corresponding to IRQ6
  str r2, [r0]        ; NVC->iser0; set enabled

  ; Switch to 24MHz clock.
  ldr r0, =0x40021000
  ldr r1, =0x110000 ; RCC->cfgr, PLL mul x6, pll src ext; RM0041 p. 80
  str r1, [r0, #4]

  ldr r1, [r0]      ; RCC->cr, turn on PLL, RM0041 p. 78
  mov r2, #0x1000000
  orr r2, #0x10000
  orr r1, r2
  str r1, [r0]

  ldr r1, =0x110002 ; Switch PLL source to HSE
  str r1, [r0, #4]

  ; Configure initial systick interrupt to happen soon.
  mov r0, #0x1000
  bl set_systick

  ; Clear score and set initial LED state to "green".
  ldr r0, =SCORE
  mov r1, #0
  str r1, [r0]     ; *SCORE = 0
  mov r1, #1
  str r1, [r0, #4] ; *GREEN = 1
  mov r1, #1
  str r1, [r0, #4] ; *ROUND = 1
  mov r1, #0
  str r1, [r0, #4] ; *COUNT = 0
  str r1, [r0, #4] ; *BUTTON = 0
  str r1, [r0, #4]
  mov r0, #0
  mov r1, #0
  mov r2, #0

skip
  ; Enable interrupts.
  cpsie i

  ; Do nothing forever
loop
  b loop

ext0_handler
  push {lr}

  ldr r2, =COUNT
  ldr r1, [r2]
  cmp r1, #10
  mov r1, #0
  mov r2, #0
  blt beginning

game_play
  ldr r0, =GREEN
  ldr r1, [r0]
  cmp r1, #0
  bne end_exception



green_press
  ; Increment score
  ldr r1, =SCORE
  ldr r0, [r1]
  add r0, #1
  str r0, [r1]
  bne end_exception






beginning
  ldr r1, =BUTTON
  ldr r0, [r1]
  add r0, #1
  str r0, [r1]
  mov r1, #0
  mov r2, #0



end_exception
  ; Clear pending bit in EXTI_PR and NVIC_ICPR
  ldr r0, =EXTI_PR
  mov r1, #1
  str r1, [r0]

  ldr r0, =NVIC_ICPR0
  mov r1, #0x40
  str r1, [r0]



  cpsie i

  ; Reset systick
  mov r0, #0x1000
  bl set_systick

  pop {pc}





; Advance state and re-set handler.
systick_handler
  push {lr}

  mov r2, #0
  ldr r2, =COUNT
  ldr r1, [r2]
  add r1, #1
  str r1, [r2]
  cmp r1, #10
  mov r1, #0
  mov r2, #0
  bge player_check


inital_state
  mov r1, #0
  ldr r0, =GREEN
  ldr r1, [r0]
  eor r1, #1
  str r1, [r0]

  cbz r1, on_state

off_state
  bl leds_off
  ldr r0, =3000000
  b systick_reload

on_state
  bl leds_on
  ldr r0, =3000000
  b systick_reload


player_check
	ldr r0, =BUTTON
	ldr r1, [r0]
	add r1, #1
	cmp r1, #0
	beq end_game

	cmp r1, #1
	beq one_player

    cmp r1, #2
	beq end_game




one_player

  ldr r2, =ROUND
  ldr r1, [r2]
  add r1, #1
  str r1, [r2]
  cmp r1, #12
  bge display_score
  mov r1, #0

  ;ldr r1, =SCORE
  ;ldr r0, =3000000
  ;ldr r1, [r1]
  ;add r1, #1
  ;udiv r0, r1
  ;str r7, [r0]

  mov r1, #0
  ldr r0, =GREEN
  ldr r1, [r0]
  eor r1, #1
  str r1, [r0]

  cbz r1, systick_green


systick_blue
  bl leds_blue
  ldr r0, =3000000
  b systick_reload


systick_green
  bl leds_green
  ldr r0, =3000000
  b systick_reload




display_score
  bl blink
  b end_game




;two_player
  ;push{lr}
  ;pop {pc}




; Now load the value in r0 into the timer.
systick_reload
      bl set_systick
      pop {pc}

disable_systick
  push {r0, r1, r2, lr}
  ldr r1, =STK_BASE
  ldr r2, [r1]
  bic r2, #3
  str r2, [r1]
  pop {r0, r1, r2, pc}

set_systick
  push {r0, r1, r2, lr}
  ldr r1, =STK_BASE


  ldr r2, [r1]
  bic r2, #3
  str r2, [r1]

  ; Reload systick with new timeout.
  str r0, [r1, #4]

  ; Enable systick
  orr r2, #3
  str r2, [r1]

  pop {r0, r1, r2, pc}



; Display the score by blinking N times.
end_game
  push {lr}

  bl leds_off
  b disable_systick

  pop {pc}

blink
  push {lr}

  ldr r0, =SCORE
  ldr r1, [r0]

blink_loop
  cbz r1, blink_ret

  ; Turn on the LEDs.
  bl leds_on

  mov r0, #0x800000
  bl delay

  ; Turn off the LEDs.
  bl leds_off

  mov r0, #0x800000
  bl delay

  sub r1, #1
  b blink_loop

blink_ret
  pop {pc}




; Write value on r0 to LEDs.
led_wr
  push {r0, r1, lr}
  lsl r0, #8
  ldr r1, =PORTC_ODR
  str r0, [r1]
  pop {r0, r1, pc}

; Turn both LEDs on.
leds_on
  mov r0, #3
  b led_wr

; Turn both LEDs off.
leds_off
  mov r0, #0
  b led_wr

; Turn green LED on.
leds_green
  mov r0, #1
  b led_wr

; Turn blue LED on.
leds_blue
  mov r0, #2
  b led_wr

; Simple delay loop
delay
  cmp r0, #0
  it eq
  bxeq lr

delay_loop
  subs r0, #1
  bne delay_loop

  bx lr

  align
  END


green_press
  ; Increment score
  ldr r1, =SCORE
  ldr r0, [r1]
  add r0, #1
  str r0, [r1]
  bne end_exception






beginning
  ldr r1, =BUTTON
  ldr r0, [r1]
  add r0, #1
  str r0, [r1]
  mov r1, #0
  mov r2, #0



end_exception
  ; Clear pending bit in EXTI_PR and NVIC_ICPR
  ldr r0, =EXTI_PR
  mov r1, #1
  str r1, [r0]

  ldr r0, =NVIC_ICPR0
  mov r1, #0x40
  str r1, [r0]



  cpsie i

  ; Reset systick
  mov r0, #0x1000
  bl set_systick

  pop {pc}





; Advance state and re-set handler.
systick_handler
  push {lr}

  mov r2, #0
  ldr r2, =COUNT
  ldr r1, [r2]
  add r1, #1
  str r1, [r2]
  cmp r1, #10
  mov r1, #0
  mov r2, #0
  bge player_check


inital_state
  mov r1, #0
  ldr r0, =GREEN
  ldr r1, [r0]
  eor r1, #1
  str r1, [r0]

  cbz r1, on_state

off_state
  bl leds_off
  ldr r0, =3000000
  b systick_reload

on_state
  bl leds_on
  ldr r0, =3000000
  b systick_reload


player_check
	ldr r0, =BUTTON
	ldr r1, [r0]
	add r1, #1
	cmp r1, #0
	beq end_game

	cmp r1, #1
	beq one_player

    cmp r1, #2
	beq end_game




one_player

  ldr r2, =ROUND
  ldr r1, [r2]
  add r1, #1
  str r1, [r2]
  cmp r1, #12
  bge display_score
  mov r1, #0

  ;ldr r1, =SCORE
  ;ldr r0, =3000000
  ;ldr r1, [r1]
  ;add r1, #1
  ;udiv r0, r1
  ;str r7, [r0]

  mov r1, #0
  ldr r0, =GREEN
  ldr r1, [r0]
  eor r1, #1
  str r1, [r0]

  cbz r1, systick_green


systick_blue
  bl leds_blue
  ldr r0, =3000000
  b systick_reload


systick_green
  bl leds_green
  ldr r0, =3000000
  b systick_reload




display_score
  bl blink
  b end_game




;two_player
  ;push{lr}
  ;pop {pc}




; Now load the value in r0 into the timer.
systick_reload
      bl set_systick
      pop {pc}

disable_systick
  push {r0, r1, r2, lr}
  ldr r1, =STK_BASE
  ldr r2, [r1]
  bic r2, #3
  str r2, [r1]
  pop {r0, r1, r2, pc}

set_systick
  push {r0, r1, r2, lr}
  ldr r1, =STK_BASE


  ldr r2, [r1]
  bic r2, #3
  str r2, [r1]

  ; Reload systick with new timeout.
  str r0, [r1, #4]

  ; Enable systick
  orr r2, #3
  str r2, [r1]

  pop {r0, r1, r2, pc}



; Display the score by blinking N times.
end_game
  push {lr}

  bl leds_off
  b disable_systick

  pop {pc}

blink
  push {lr}

  ldr r0, =SCORE
  ldr r1, [r0]

blink_loop
  cbz r1, blink_ret

  ; Turn on the LEDs.
  bl leds_on

  mov r0, #0x800000
  bl delay

  ; Turn off the LEDs.
  bl leds_off

  mov r0, #0x800000
  bl delay

  sub r1, #1
  b blink_loop

blink_ret
  pop {pc}




; Write value on r0 to LEDs.
led_wr
  push {r0, r1, lr}
  lsl r0, #8
  ldr r1, =PORTC_ODR
  str r0, [r1]
  pop {r0, r1, pc}

; Turn both LEDs on.
leds_on
  mov r0, #3
  b led_wr

; Turn both LEDs off.
leds_off
  mov r0, #0
  b led_wr

; Turn green LED on.
leds_green
  mov r0, #1
  b led_wr

; Turn blue LED on.
leds_blue
  mov r0, #2
  b led_wr

; Simple delay loop
delay
  cmp r0, #0
  it eq
  bxeq lr

delay_loop
  subs r0, #1
  bne delay_loop

  bx lr

  align
  END
