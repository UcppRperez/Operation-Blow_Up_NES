.include "constants.inc"

.segment "ZEROPAGE"
player_1_y: .res 1
player_direction: .res 1
player_1_x: .res 1
flag_scroll: .res 1 
change_background_flag: .res 1
controller_read_output: .res 1
.importzp pad1

.segment "CODE"
.export read_controller1
.proc read_controller1
  PHA
  TXA
  PHA
  PHP

  ; write a 1, then a 0, to CONTROLLER1
  ; to latch button states
  LDA #$01
  STA CONTROLLER1
  LDA #$00
  STA CONTROLLER1

  LDA #%00000001
  STA pad1

get_buttons:
  LDA CONTROLLER1 ; Read next button's state
  LSR A           ; Shift button state right, into carry flag
  ROL pad1        ; Rotate button state from carry flag
                  ; onto right side of pad1
                  ; and leftmost 0 of pad1 into carry flag
  BCC get_buttons ; Continue until original "1" is in carry flag

 LDA #1
  STA controller_read_output ; store it with 1 so that when that 1 gets passed to the carry flag after 8 left shifts, we can break out of the loop

LatchController:
  lda #$01
  STA $4016
  LDA #$00
  STA $4016  

; after the following loop: the controller_read_output var will contain the status of all of the buttons (if they were pressed or not) 
read_controller_loop:
  LDA $4016
  lsr A ; logical shift right to place first bit of accumulator to the carry flag
  ROL controller_read_output ; rotate left, place left most bit in controller_read_output to carry
  ;  and place what was in carry flag to the right most bit ofcontroller_read_output

  bcc read_controller_loop

;  ; direction: UP -> 0 | RIGHT -> 16 (#$10) | LEFT -> 32 (#$20) | DOWN -> 48 (#$30)

ReadA:
  LDA controller_read_output
  AND #%10000000
  beq ReadADone

  lda #$01
  sta change_background_flag

  ReadADone:

; reads B to start scroll
ReadB: 
  LDA controller_read_output
  AND #%01000000 
  BEQ ReadBDone

  LDA #$01
  STA flag_scroll  

  ReadBDone:

; Reads the right arrow key to turn right
ReadRight: ; en el original NES controller, la A está a la derecha así que la "S" en el teclado es la A

  LDA controller_read_output
  AND #%00000001 ; BIT MASK to look if accumulator holds a value different than 0 after performing the AND
  ; here we are checking to see if the A was pressed
  BEQ ReadRightDone
  
  ; if A is pressed, move sprite to the right
  LDA player_1_x
  CLC
  ADC #$01 ; x = x + 1
  STA player_1_x
  LDA #$20
  STA player_direction

  ReadRightDone:

ReadLeft:
  LDA controller_read_output
  AND #%00000010 ;check if left arrow button is pressed
  BEQ ReadLeftDone

  LDA player_1_x
  SEC ; make sure the carry flag is set for subtraction
  SBC #$01 ; X = X - 1
  sta player_1_x
  LDA #$00
  STA player_direction

  ReadLeftDone:

ReadUp:
  LDA controller_read_output
  AND #%00001000
  BEQ ReadUpDone

  ; if Up is pressed, move sprite up
  ; to move UP, we subtract from Y coordinate
  LDA player_1_y
  SEC 
  SBC #$01 ; Y = Y - 1
  STA player_1_y
  LDA #$26 ; UP is 0
  STA player_direction

  ReadUpDone:
  
ReadDown:
  LDA controller_read_output
  AND #%00000100
  BEQ ReadDownDone

  ; if Up is pressed, move sprite up
  ; to move UP, we subtract from Y coordinate
  LDA player_1_y
  CLC 
  ADC #$01 ; Y = Y + 1
  STA player_1_y
  LDA #$06 ; DOWN is $30 (48 in decimal)
  STA player_direction

ReadDownDone:

  PLP
  PLA
  TAX
  PLA
  RTS
.endproc
