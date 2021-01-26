; Name:     Adder
;
; Purpose:  The LC3 has an addressability of 16 bits, therefore one register or location in memory
;           can store a volue n, such that #-32768 =< n =< #+32767. The purpose of the Adder is to
;           sum values larger than the ones which can be stored in 16 bits. In this case, it can
;           add two value each as large as 10^100. In takes the first value as input, then the second,
;           and prints the sum to display.
;
; Design:   During input each digit is stored in memory in a sequence of addresses. Two pointers keep
;           track of the last digit of each number. A stack is implemented to which the result is pushed.

.ORIG x3000
MAIN
    ; R1 and R2 point at beginning of dedicated memories for numbers
    LD  R1, NUM1_PTR    
    LD  R2, NUM2_PTR
    
    LD  R4, RES_STACK_BOT
    LD  R5, RES_STACK_TOP
    LD  R6, RES_STACK_MAX
    
    JSR GET_NUMS
    JSR CALCULATE
    JSR DISPLAY_RESULT
    LD  R0, NEWLINE
    OUT
HALT
    NEWLINE         .FILL   x000A
    ; First number from user, 10^100 = 101 max digits
    NUM1            .BLKW   #101
    NUM1_PTR        .FILL   NUM1
    ; Second number from user, 10^100 = 101 max digits
    NUM2            .BLKW   #101
    NUM2_PTR        .FILL   NUM2
    ; Result to display, 10^100 + 10^100 = 10^101 = 102 max digits
    RES_STACK_BOT   .FILL   xA000
    RES_STACK_TOP   .FILL   xA000
    RES_STACK_MAX   .FILL   xB000
END_MAIN

;   Description:    Continuously prompt for input until user presses ENTER.
;                   Print char after each keystroke.
;                   Each digit input is stored into the addresses defined in MAIN.
;   Input:          Requires R1 and R2 to point at beginning of addresses dedicated.
;   Output:         R1 and R2 point at the last digit of each number.
GET_NUMS
    ST  R0, NUM1_SAVE_R0
    ST  R3, NUM1_SAVE_R3
    ST  R4, NUM1_SAVE_R4
    ST  R5, NUM1_SAVE_R5
    ST  R6, NUM1_SAVE_R6
    ST  R7, NUM1_SAVE_R7
    
    LD  R3, NEWLINE_NEG
    LD  R5, ASCII_OFFSET
    
    PROMPT_NUM1
        GETC                ; Prompt user for input
        ADD R4, R0, R3      ; Check if input was ENTER
        BRz END_PROMPT1     ; If yes, end prompt loop
        OUT                 ; Output user input
        ADD R0, R0, R5      ; Store decimal value
        STR R0, R1, #0      ; Store input into memory
        ADD R1, R1, #1      ; Increment pointer to next location
        BR  PROMPT_NUM1     ; Repeat process
    END_PROMPT1
    
    LD  R0, NEWLINE_POS     ; Used to check for newline input
    OUT
    
    PROMPT_NUM2
        GETC                ; Prompt user for input
        ADD R4, R0, R3      ; Check if input was ENTER
        BRz END_PROMPT2     ; If yes, end prompt loop
        OUT                 ; Output user input
        ADD R0, R0, R5      ; Store decimal value
        STR R0, R2, #0      ; Store input into memory
        ADD R2, R2, #1      ; Increment pointer to next location
        BR  PROMPT_NUM2     ; Repeat process
    END_PROMPT2
    
    LD  R0, NEWLINE_POS
    OUT
    
    LD  R0, NUM1_SAVE_R0
    LD  R3, NUM1_SAVE_R3
    LD  R4, NUM1_SAVE_R4
    LD  R5, NUM1_SAVE_R5
    LD  R6, NUM1_SAVE_R6
    LD  R7, NUM1_SAVE_R7
    
    RET
    ; data
    ASCII_OFFSET    .FILL   x-0030
    NEWLINE_POS     .FILL   x000A
    NEWLINE_NEG     .FILL   x-000A
    NUM1_SAVE_R0    .BLKW   #1
    NUM1_SAVE_R3    .BLKW   #1
    NUM1_SAVE_R4    .BLKW   #1
    NUM1_SAVE_R5    .BLKW   #1
    NUM1_SAVE_R6    .BLKW   #1
    NUM1_SAVE_R7    .BLKW   #1
END_GET_NUMS

;   Input:      R5, R6 = top and max pointer of stack
;               R1, R2 = pointers to least significant digits of numbers input
;   Output:     R5 = new top of stack due to calling stack push
CALCULATE
        ST  R0, CALC_SAVE_R0
        ST  R3, CALC_SAVE_R3
        ST  R4, CALC_SAVE_R4
        ST  R7, CALC_SAVE_R7
        ; Clear R7 in order to store carry
        ; and set pointers to point at last digit
        AND R4, R4, #0
        ADD R1, R1, #-1
        ADD R2, R2, #-1
        
    LOOP_CALCULATE
        JSR CHECK_NUM1_PTR
        ADD R0, R0, #0
        BRn CALC_NUM2               ; If R0 is -1, NUM1 has no more digits
        
        JSR CHECK_NUM2_PTR
        ADD R3, R3, #0
        BRn CALC_NUM1               ; If R3 is -1, NUM2 has no more digits
        
        LDR R0, R1, #0              ; R0 = value @address pointed to by R1
        LDR R3, R2, #0              ; R3 = value @address pointed to by R2
        ADD R0, R0, R3
        ADD R0, R0, R4              ; Adds 1 in case there was a carry over, else adds 0
        AND R4, R4, #0              ; Clear R7 from carry
        
        ADD R0, R0, #-10            ; Check if result is > 9
        BRn NO_CARRY                ; 1/9 - 10 = -1/9
        JSR STACK_PUSH              ; R0 = ones value after summing digits from num1 and num2
        ADD R4, R4, #1              ; Add 1 to carry over for next calculation
        ADD R1, R1, #-1             ; Decrement pointers
        ADD R2, R2, #-1
        BR  LOOP_CALCULATE
        
        NO_CARRY 
        ADD R0, R0, #10             ; Restore + sign
        JSR STACK_PUSH              ; Store result
        ADD R1, R1, #-1             ; Decrement pointers
        ADD R2, R2, #-1
        BR  LOOP_CALCULATE
        
    CALC_NUM2
        AND R0, R0, #0              ; Clear R0 after checking remaining digits
        JSR CHECK_NUM2_PTR
        ADD R3, R3, #0
        BRn END_LOOP_CALCULATE      ; If R3 is -1, NUM2 has no more digits
    
        LDR R3, R2, #0              ; R3 = value @address pointed to by R2
        ADD R0, R0, R3
        ADD R0, R0, R4              ; Adds 1 in case there was a carry over, else adds 0
        AND R4, R4, #0              ; Clear R7 from carry
        
        ADD R0, R0, #-10            ; Check if result is > 9
        BRn NO_CARRY_NUM2           ; 1/9 - 10 = -1/9
        JSR STACK_PUSH              ; R0 = ones value after summing digits from num1 and num2
        ADD R4, R4, #1              ; Add 1 to carry over for next calculation
        ADD R2, R2, #-1
        BR  CALC_NUM2
        
        NO_CARRY_NUM2 
        ADD R0, R0, #10             ; Restore + sign
        JSR STACK_PUSH              ; Store result
        ADD R2, R2, #-1
        BR  CALC_NUM2
    
    CALC_NUM1
        JSR CHECK_NUM1_PTR
        ADD R0, R0, #0
        BRn END_LOOP_CALCULATE      ; If R0 is -1, NUM1 has no more digits
    
        LDR R0, R1, #0              ; R0 = value @address pointed to by R1
        ADD R0, R0, R4              ; Adds 1 in case there was a carry over, else adds 0
        AND R4, R4, #0              ; Clear R7 from carry
        
        ADD R0, R0, #-10            ; Check if result is > 9
        BRn NO_CARRY_NUM1           ; 1/9 - 10 = -1/9
        JSR STACK_PUSH              ; R0 = ones value after summing digits from num1 and num2
        ADD R4, R4, #1              ; Add 1 to carry over for next calculation
        ADD R1, R1, #-1
        BR  CALC_NUM1
        
        NO_CARRY_NUM1 
        ADD R0, R0, #10             ; Restore + sign
        JSR STACK_PUSH              ; Store result
        ADD R1, R1, #-1
        BR  CALC_NUM1
    
    END_LOOP_CALCULATE
        ADD R4, R4, #0              
        BRz FULL_END_CALCULATE      ; If R4 is 0, no moving carry over => end calculations
        AND R0, R0, #0              ; Else the carry as leading 1 since N + M is 1 digit larger
        ADD R0, R0, R4              ; than M and N separately
        JSR STACK_PUSH
        
    FULL_END_CALCULATE
        LD  R0, CALC_SAVE_R0
        LD  R3, CALC_SAVE_R3
        LD  R4, CALC_SAVE_R4
        LD  R7, CALC_SAVE_R7
        RET
        ; data
        CALC_SAVE_R0    .BLKW   #1
        CALC_SAVE_R3    .BLKW   #1
        CALC_SAVE_R4    .BLKW   #1
        CALC_SAVE_R7    .BLKW   #1
END_CALCULATE

;   Input:  R1 points to digit in NUM1
;   Output: R0 = -1 if there are no more digits in NUM1
CHECK_NUM1_PTR
    LD  R0, NUM1_ORIG_PTR
    NOT R0, R0
    ADD R0, R0, #1
    ADD R0, R0, R1
    RET
    ; data
    NUM1_ORIG_PTR   .FILL   NUM1
END_CHECK_NUM1_PTR

;   Input:  R2 points to digit in NUM2
;   Output: R3 = -1 if there are no more digits in NUM2
CHECK_NUM2_PTR
    LD  R3, NUM2_ORIG_PTR
    NOT R3, R3
    ADD R3, R3, #1
    ADD R3, R3, R2
    RET
    ; data
    NUM2_ORIG_PTR   .FILL   NUM2
END_CHECK_NUM2_PTR

;   Input:  R4 = bot of stack, R5 = top of stack
;   Output: Prints out each digit from stack to display
DISPLAY_RESULT
        ST  R0, DISPLAY_SAVE_R0
        ST  R1, DISPLAY_SAVE_R1
        ST  R7, DISPLAY_SAVE_R7
        
        LD  R1, TO_ASCII
        
    DISPLAY_LOOP
        JSR STACK_POP               ; R0 contains value to be displayed
        ADD R0, R0, #0
        BRn END_DISPLAY_LOOP        ; Stack_pop returns R0 = -1 if no more values in stack
        ADD R0, R0, R1              ; Convert to ASCII value
        OUT                         
        BR  DISPLAY_LOOP
        
    END_DISPLAY_LOOP  
        LD  R0, DISPLAY_SAVE_R0
        LD  R1, DISPLAY_SAVE_R1
        LD  R7, DISPLAY_SAVE_R7
        RET
        ; data
        TO_ASCII        .FILL   x0030
        DISPLAY_SAVE_R0 .BLKW   #1
        DISPLAY_SAVE_R1 .BLKW   #1
        DISPLAY_SAVE_R7 .BLKW   #1
END_DISPLAY_RESULT


; Input:    R0 = value to push
;           R5 = top of stack
;           R6 = max of stack
; Output:   R5 = new top of stack
STACK_PUSH
    ST  R7, STACK_PUSH_SAVE7
    ST  R1, STACK_PUSH_SAVE1
    
    ADD R1, R5, #0              ; Get negative value of ptr to top
    NOT R1, R1                  ; in order to check for stack overflow
    ADD R1, R1, #1
    
    ADD R1, R1, R6              ; Check if there is space in stack
    BRn STACK_PUSH_OVERFLOW
    
    STR R0, R5, #0              ; Write value to memory[top of stack]
    ADD R5, R5, #1              ; Increment top of stack
    
    LD  R7, STACK_PUSH_SAVE7
    LD  R1, STACK_PUSH_SAVE1
RET
    ; in case of stack overflow
    STACK_PUSH_OVERFLOW
    LEA R0, STACK_PUSH_OVERFLOW_MSG
    PUTS
HALT
    ; data
    STACK_PUSH_SAVE7        .BLKW   #1
    STACK_PUSH_SAVE1        .BLKW   #1
    STACK_PUSH_OVERFLOW_MSG .STRINGZ    "Stack overflow!"
END_STACK_PUSH

; Input:    R5 = top of stack
;           R4 = bot of stack
; Output:   R5 = new top of stack
;           R0 = popped value
;           R0 = -1 if stack underflow
STACK_POP
    ST  R1, STACK_POP_SAVE1
    ST  R7, STACK_POP_SAVE7
    
    ; Check if stack is not empty
    ADD R1, R5, #0
    NOT R1, R1 
    ADD R1, R1, #1
    ADD R1, R1, R4
    BRzp    STACK_POP_UNDERFLOW
    
    ADD R5, R5, #-1                 ; Decrement top of stack
    LDR R0, R5, #0                  ; Read memory[top]
    
    LD  R1, STACK_POP_SAVE1
    LD  R7, STACK_POP_SAVE7
    RET
    
    STACK_POP_UNDERFLOW
    AND R0, R0, #0
    ADD R0, R0, #-1
    LD  R1, STACK_POP_SAVE1
    LD  R7, STACK_POP_SAVE7
    RET

    ; data
    STACK_POP_SAVE1         .BLKW   #1
    STACK_POP_SAVE7         .BLKW   #1
END_STACK_POP
.END
