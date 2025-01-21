;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------

; COMMENTS !

; For my for loop delay, I have an outer delay of 10, and an inner delay of 17483.
; The inner loop is supposed to be 0.1 seconds, so it loops 10 times thus creating our one second delay.
; The math for finding my inner loop was just simple math, I started with an arbitrary value, 25000.
; Running it, I found a delay of 1.43 seconds. By doing 1/1.43 I discovered it was over by 69.9300699%.
; Multiplying 25000 * .699300699, I yielded 17482.517475, rounded to 17483.

; Initially, I set CCR0 to 32000 with ACLK, since 1/32000 should be 1 second
; This was off, yielding about 0.977 seconds.
; 1/0.977 = 1.02354145343, so multiplying 32000 by 1.02354145343 yields 32753.3265098, which we round to 32753

; Both values are slightly off, fluctuating by 0.01 or so, likely due to crystal errors. Too, both lights will run out of sync
; With the delay loop seemingly ever so slightly faster. This is likely just due to inprecision of my math due to rounding and
; crystal fluctuations from my calculation (i.e, I pulled 1.43, but the average could have been something like 1.4604369).

; I would choose the timer interrupt exclusively, just due to its simplicitly to implement in my opinion. Too, the delay of
; the delay loop is dependent on how many lines are executed, each having their own time depending on parameters and what
; they are, which frankly is a total headache and why I didn't even try manually calculating that. Thus, I would only use a for
; loop in the case that I've ran out of available interrupts to use, or I don't need a precise delay.



init:
		bic.b   #BIT0,&P1OUT            ; Clear P1.0 output
        bis.b   #BIT0,&P1DIR            ; P1.0 output

        bic.b   #BIT6,&P6OUT            ; Clear P6.6 output
        bis.b   #BIT6,&P6DIR            ; P6.6 output

        ; Set up timer B0
		bis.w	#TBCLR, &TB0CTL	;Clear timer and dividers
		bis.w	#TBSSEL__ACLK, &TB0CTL ;Select ACLK as timer source
        bis.w	#MC__UP, &TB0CTL ; Choose UP Counting

        mov.w	#32753d, &TB0CCR0 ; Initialize CCR0 to 32753
        bis.w	#CCIE, &TB0CCTL0 ; Enabled capture/compare IRQ
        bic.w	#CCIFG, &TB0CCTL0 ; Clear interrupt flag

        bis.w	#GIE, SR ; Enable global maskable interrupts
        bic.w   #LOCKLPM5,&PM5CTL0      ; Unlock I/O pins

main:

		call	#DelaySubRoutine
        
		xor.b   #BIT0,&P1OUT ; Toggle red LED

		jmp main

		nop
;-------------------------------------------------------------------------------
; Delay Subroutine
;-------------------------------------------------------------------------------
DelaySubRoutine:
		mov.w	#10, R4 ; Set Outer Loop for 10 iterations

DelayOuterLoop:
		tst.w	R4  ; Check if outer loop has decremented to 0 
		jz		DelayReturn ; If so, then return
		mov.w	#17483, R5 ; Set inner loop to 0.1 s
		dec.w	R4 ; Decrement outer loop
		jmp		DelayInnerLoop ; Run inner loop (delay by 0.1 seconds)
		jmp		DelayOuterLoop ; Repeat outer loop

DelayInnerLoop:
		tst.w 	R5 ; Check if inner loop is complete
		jz		DelayOuterLoop ; If complete, return to outer loop
		dec.w	R5 ; Decrement inner loop
		jmp		DelayInnerLoop ; Repeat inner loop

DelayReturn:
		ret ; Return

;-------------------------------------------------------------------------------
; Interrupt Service Routines
;-------------------------------------------------------------------------------
ISR_TB0_CCR0:
		xor.b	#BIT6, &P6OUT ; Toggle LED2
		bic.w	#CCIFG, &TB0CCTL0 ; Clear interrupt
		reti

;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
            
            .sect	".int43"
            .short	ISR_TB0_CCR0

