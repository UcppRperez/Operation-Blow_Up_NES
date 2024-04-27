; .include "constants.inc"
; .include "header.inc"
; .include "input.asm"
; .segment "CODE"

; ; display_tile subroutine
; ; tile_index -> $00
; ; low byte -> $01
; ; high byte -> $02
; .proc display_tile
;   LDA PPUSTATUS; 
;   LDA $02 ; LOADING highbyte to the accumulator
;   STA PPUADDR
;   LDA $01 ; LOADING lowbyte to the accumulator
;   STA PPUADDR
; ; 00000100
;   LDA $00
;   STA PPUDATA
  
;   rts ; return from subroutine
; .endproc

; ; PARAMS
; ; current_stage --> 1 for stage 1 | 2 for stage 2
; .proc display_stage_background
;   PHP
;   PHA
;   TXA
;   PHA
;   TYA
;   PHA

;   disable_rendering:
;     LDA #%00000000  ; turning off backgrounds not sprites
;     STA PPUMASK

    
;     LDA ppuctrl_settings  ;turn off NMI
;     AND #%01111000
;     STA PPUCTRL
;     STA ppuctrl_settings

;   LDA current_stage
;   CMP #$02
;   BEQ prep_stage_2 ; if current_stage is 2, then branch to prep for stage 2; else: jump to prep for stage 1

;   prep_stage_1:
;     ; current_stage = 1
;     LDA #$00
;     sta choose_which_background ; setting choose_which_background to 0 so it can choose the maps for stage 1

;   JMP finished_preparing

;   prep_stage_2:
;     ; current_stage = 2
;     LDA #$02
;     sta choose_which_background


;   finished_preparing:
;   LDY #$00
;   sty fix_low_byte_row_index
;   STY low_byte_nametable_address

;   LDA #$20
;   STA high_byte_nametable_address

;   JSR display_one_nametable_background

;     ; MUST ADD 1 to choose_which_background to display the SECOND part of that stage
;       LDA choose_which_background
;       clc
;       adc #$01
;       sta choose_which_background ; choose_which_background += 1
    

;   LDY #$00
;   sty fix_low_byte_row_index
;   STY low_byte_nametable_address

;   LDA #$24
;   STA high_byte_nametable_address

;   JSR display_one_nametable_background

;   enable_rendering:

;     LDA #%10010000  ; turn on NMIs, sprites use first pattern table
;     STA PPUCTRL
;     STA ppuctrl_settings
;     LDA #%00011110  ; turn on screen
;     STA PPUMASK


;   PLA
;   TAY
;   PLA
;   TAX
;   PLA
;   PLP 
; RTS
; .endproc

; ; PARAMS:
; ; fix_low_byte_row_index -> should be set to zero (will go from 0 to 4 then back to 0)
; ; low_byte_nametable_address
; ; high_byte_nametable_address
; ; choose_which_background
; .proc display_one_nametable_background
;   PHP
;   PHA
;   TXA
;   PHA
;   TYA
;   PHA

; load_background:
;   LDA choose_which_background
;   CMP #$00
;   BNE test_for_stage_1_part_2

;     LDA background_stage_1_part_1, Y
;     JMP background_selected

; test_for_stage_1_part_2:
;   CMP #$01
;   BNE test_for_stage_2_part_1

;     LDA background_stage_1_part_2, Y
;     JMP background_selected
; test_for_stage_2_part_1:
;   CMP #$02
;   BNE test_for_stage_2_part_2

;     LDA background_stage_2_part_1, Y
;     jmp background_selected

; test_for_stage_2_part_2:
;   ; at this point, this is practically an ELSE statement so it must be stage 2 part 2
;     LDA background_stage_2_part_2, Y

;   background_selected:
  
;   STA current_byte_of_tiles
;   JSR display_byte_of_tiles
;   INY
;   increment_fix_low_byte_row_index:
;     lda fix_low_byte_row_index
;     clc
;     adc #$01
;     sta fix_low_byte_row_index
;   lda fix_low_byte_row_index
;   cmp #$04 ; compare if fix_low_byte_row_index is 4
;   BNE skip_low_byte_row_fix
;     ; lda #$e0
;     lda low_byte_nametable_address
;     clc
;     adc #$20 ; add 32 to skip to the next row
;     sta low_byte_nametable_address
;     bcc skip_overflow_fix_2
;       ; if PC is here, then add 1 to high byte because of overflow
;       lda high_byte_nametable_address
;       clc
;       adc #$01
;       sta high_byte_nametable_address
;     skip_overflow_fix_2:
;       LDA #$00
;       sta fix_low_byte_row_index

;   skip_low_byte_row_fix:
;     cpy #$3C
;     bne load_background

;   PLA
;   TAY
;   PLA
;   TAX
;   PLA
;   PLP 
; RTS
; .endproc

; ; PARAMS:
; ; current_byte_of_tiles
; ; tile_to_display
; ; high_byte_nametable_address 
; ; low_byte_nametable_address (must be updated within function)

; .proc display_byte_of_tiles
;   PHP
;   PHA
;   TXA
;   PHA
;   TYA
;   PHA
;   ldx #$00 ; X will be our index to run the loop 4 times
;   process_byte_of_tiles_loop:
;     LDA #$00
;     STA tile_to_display ; clear the tile to display var to zero (since we might have left over bits from previous loops)
;     ASL current_byte_of_tiles ; place 7th bit of current_byte_of_tiles in CARRY flag and place a 0 in the current_byte_of_tiles (shift left)
;     ROL tile_to_display ; rotate left the carry flag onto tile_to_display : C <- 7 6 5 4 3 2 1 0 <- C
;     ASL current_byte_of_tiles ; C <- 7 6 5 4 3 2 1 0 <- 0
;     ROL tile_to_display
;     ; ask in which stage you are in
;     ; si estas en stage 2 pues sumale 4 al tile to display
;     lda current_stage
;     CMP #$01
;     BEQ skip_addition_to_display
;       ; here it's stage 2
;       lda tile_to_display
;       clc
;       adc #$04
;       sta tile_to_display

;     skip_addition_to_display:
;     JSR display_4_background_tiles

;     LDA low_byte_nametable_address
;     CLC 
;     ADC #$02 
;     STA low_byte_nametable_address ; low_byte_nametable_address += 2
    
;     BCC skip_overflow_fix
;     ; MUST CHECK FOR OVERFLOW HERE !!! CHECK CARRY FLAG
;     ;if there was overflow when adding 2 to low_byte, then increase high_byte by 1. Low_byte should have correct value already
;     LDA high_byte_nametable_address
;     CLC
;     ADC #$01
;     sta high_byte_nametable_address

;     skip_overflow_fix:
;       INX
;       CPx #$04
;       Bne process_byte_of_tiles_loop

;   PLA
;   TAY
;   PLA
;   TAX
;   PLA
;   PLP   



; RTS
; .endproc

; ; PARAMS:
; ; tile_to_display
; ; high_byte_nametable_address
; ; low_byte_nametable_address
; .proc display_4_background_tiles
;   PHP
;   PHA
;   TXA
;   PHA
;   TYA
;   PHA

; LDA PPUSTATUS ; Read from PPUSTATUS ONCE to ensure that the next write to ppuaddr is the high byte (reset it)
; ; TOP LEFT
;   LDA high_byte_nametable_address
;   STA PPUADDR
;   LDA low_byte_nametable_address
;   STA PPUADDR
;   LDA tile_to_display
;   STA PPUDATA

; ; TOP RIGHT
;   LDA high_byte_nametable_address
;   STA PPUADDR
;   LDA low_byte_nametable_address
;   CLC ; CLEAR CARRY FLAG BEFORE ADDING
;   ADC #$01 ; adding 1 to low byte nametable_address
;   STA PPUADDR
;   LDA tile_to_display
;   STA PPUDATA

;      ; finally, attribute table
; 	LDA PPUSTATUS
; 	LDA #$23
; 	STA PPUADDR
; 	LDA #$f0
; 	STA PPUADDR
; 	LDA #%01000000
; 	STA PPUDATA



;   ; bottom LEFT
;   LDX #$00
;   JSR handle_bottom_left_or_right

;   ; bottom RIGHT
;   ldx #$01
;   jsr handle_bottom_left_or_right

;    PLA
;   TAY
;   PLA
;   TAX
;   PLA
;   PLP


; RTS
; .endproc

; .proc handle_bottom_left_or_right
;   PHP
;   PHA
;   TXA
;   PHA
;   TYA
;   PHA
;   ; BEFORE CALLING THIS SUBROUTINE: 
;   ; if X is 0 then we are handling bottom left tile
;   ; if X is 1 then we are handling bottom right tile
;   TXA
;   CMP #$01
;   beq add_to_low_byte_right_version

;   LDA low_byte_nametable_address
;   CLC ; CLEAR CARRY FLAG BEFORE ADDING
;   ADC #$20 ; adding 32 to low byte nametable_address
;   jmp check_overflow

; add_to_low_byte_right_version:
;   LDA low_byte_nametable_address
;   CLC ; CLEAR CARRY FLAG BEFORE ADDING
;   ADC #$21 ; adding 33 to low byte nametable_address

; check_overflow:
;   ; MUST CHECK IF CARRY FLAG WAS ACTIVATED
;   BCC add_with_no_overflow

;   ; if Program Counter is here, there was OVERFLOW
;   ; if carry was SET: then we must add 1 to the high byte and set low_byte to 00
;   LDA high_byte_nametable_address
;   clc 
;   adc #$01 ; accumulator = high_byte + 1
;   sta PPUADDR
;   TXA
;   cmp #$01 ; check if we are handling right tile
;   beq store_low_byte_for_right

;   ; LOW BYTE FOR LEFT
;   lda low_byte_nametable_address
;   clc 
;   adc #$20 ; an overflow will occur BUT, the accumulator will contain the correct value for the low byte
;   STA PPUADDR 
;   jmp store_tile_to_ppu

;   store_low_byte_for_right:
;   lda low_byte_nametable_address
;   clc 
;   adc #$21
;   STA PPUADDR
;   jmp store_tile_to_ppu
  
; add_with_no_overflow: 
;   ; IF THERE WAS NO OVERFLOW -> high_byte stays the same
;   LDA high_byte_nametable_address
;   sta PPUADDR
;   TXA
;   cmp #$01
;   beq store_low_byte_for_right_no_overflow

;   LDA low_byte_nametable_address
;   CLC ; CLEAR CARRY FLAG BEFORE ADDING
;   ADC #$20 
;   sta PPUADDR
;   jmp store_tile_to_ppu

; store_low_byte_for_right_no_overflow:
;   LDA low_byte_nametable_address
;   CLC ; CLEAR CARRY FLAG BEFORE ADDING
;   ADC #$21 ; accumulator = low_byte + 0x21 since we are handling the right tile
;   sta PPUADDR

; store_tile_to_ppu:

;   LDA tile_to_display
;   STA PPUDATA


;   PLA
;   TAY
;   PLA
;   TAX
;   PLA
;   PLP
; RTS
; .endproc
; .proc update_tick_count
;   LDA tick_count       ; Load the updated tick_count into A for comparison
;   CLC                  ; Clear the carry flag
;   ADC #$1              ; Add one to the A register

;   CMP #$28               ; Compare A (tick_count) with 0x28 -> 40
;   BEQ reset_tick       ; If equal, branch to resetCount label

;   CMP #$14            ; Compare A again (tick_count) with 0x14 -> 20
;   BNE done              ; If not equal, we are done, skip to done label
  
;   ; If CMP #30 was equal, fall through to here
;   STA tick_count
;   LDA #$01
;   STA wings_flap_state
;   RTS            

; reset_tick:
;   LDA #$00             ; Load A with 0
;   STA tick_count       ; Reset tick_count to 0 
;   STA wings_flap_state    
;   RTS

; done:
;   STA tick_count
;   RTS
; .endproc







; .export draw_starfield
; .proc draw_starfield
; 	LDA PPUSTATUS      ; Load PPU status register
; 	TXA                ; Transfer X to accumulator
; 	ADC #$20           ; Add 3 to the high byte of the nametable address (adjust this based on your starting offset)
; 	STA PPUADDR       ; Store the result in PPUADDR to set the high byte of the nametable address

; 	LDA #$00         ; Load the offset for the first tile
; 	STA PPUADDR       ; Store the offset in PPUADDR
; 	LDA #$20
; 	STA PPUADDR
; 	LDA #$00          ; Load the tile data for the first tile
; 	STA PPUDATA       ; Store the tile data in PPUDATA

; 	LDA #$9c         ; Load the offset for the first tile
; 	STA PPUADDR       ; Store the offset in PPUADDR
; 	LDA #$20
; 	STA PPUADDR
; 	LDA #$30          ; Load the tile data for the first tile
; 	STA PPUDATA 

; 	LDA #$9d         ; Load the offset for the second tile
; 	STA PPUADDR       ; Store the offset in PPUADDR
; 	LDA #$20
; 	STA PPUADDR
; 	LDA #$31          ; Load the tile data for the second tile
; 	STA PPUDATA       ; Store the tile data in PPUDATA

; 	LDA #$bc         ; Load the offset for the third tile
; 	STA PPUADDR       ; Store the offset in PPUADDR
; 	LDA #$20
; 	STA PPUADDR
; 	LDA #$40          ; Load the tile data for the third tile
; 	STA PPUDATA       ; Store the tile data in PPUDATA

; 	LDA #$bD         ; Load the offset for the fourth tile
; 	STA PPUADDR       ; Store the offset in PPUADDR
; 	LDA #$20
; 	STA PPUADDR
; 	LDA #$41          ; Load the tile data for the fourth tile
; 	STA PPUDATA       ; Store the tile data in PPUDATA
	


; 	LDA PPUSTATUS      ; Load PPU status register
; 	TXA                ; Transfer X to accumulator
; 	ADC #$20           ; Add 3 to the high byte of the nametable address (adjust this based on your starting offset)
; 	STA PPUADDR       ; Store the result in PPUADDR to set the high byte of the nametable address

; 	LDA #$00         ; Load the offset for the first tile
; 	STA PPUADDR       ; Store the offset in PPUADDR
; 	LDA #$20
; 	STA PPUADDR
; 	LDA #$00          ; Load the tile data for the first tile
; 	STA PPUDATA       ; Store the tile data in PPUDATA

; 	LDA #$dc         ; Load the offset for the first tile
; 	STA PPUADDR       ; Store the offset in PPUADDR
; 	LDA #$20
; 	STA PPUADDR
; 	LDA #$50          ; Load the tile data for the first tile
; 	STA PPUDATA 

; 	LDA #$dd         ; Load the offset for the second tile
; 	STA PPUADDR       ; Store the offset in PPUADDR
; 	LDA #$20
; 	STA PPUADDR
; 	LDA #$51          ; Load the tile data for the second tile
; 	STA PPUDATA       ; Store the tile data in PPUDATA

; 	LDA #$fc         ; Load the offset for the third tile
; 	STA PPUADDR       ; Store the offset in PPUADDR
; 	LDA #$20
; 	STA PPUADDR
; 	LDA #$60          ; Load the tile data for the third tile
; 	STA PPUDATA       ; Store the tile data in PPUDATA

; 	LDA #$fD         ; Load the offset for the fourth tile
; 	STA PPUADDR       ; Store the offset in PPUADDR
; 	LDA #$20
; 	STA PPUADDR
; 	LDA #$61          ; Load the tile data for the fourth tile
; 	STA PPUDATA       ; Store the tile data in PPUDATA
	

; 	; finally, attribute table
; 	LDA PPUSTATUS
; 	LDA #$23
; 	STA PPUADDR
; 	LDA #$cf
; 	STA PPUADDR
; 	LDA #%01010101
; 	STA PPUDATA

; 	; LDA PPUSTATUS
; 	; LDA #$23
; 	; STA PPUADDR
; 	; LDA #$e0
; 	; STA PPUADDR
; 	; LDA #%10001100
; 	; STA PPUDATA

; 	; ; finally, attribute table for the second set of tiles (using palette 1)
; 	; LDA PPUSTATUS
; 	; LDA #$23
; 	; STA PPUADDR
; 	; LDA #$c3
; 	; STA PPUADDR
; 	; LDA #%01000001 ; Use palette 1 instead of palette 0
; 	; STA PPUDATA

; 	; LDA PPUSTATUS
; 	; LDA #$23
; 	; STA PPUADDR
; 	; LDA #$e1
; 	; STA PPUADDR
; 	; LDA #%00001101 ; Use palette 1 instead of palette 0
; 	; STA PPUDATA

; 	RTS
; .endproc

; .export draw_objects
; .proc draw_objects
; 	; Draw objects on top of the starfield,
;   ; and update attribute tables

; 	LDA PPUSTATUS      ; Load PPU status register
; 	TXA                ; Transfer X to accumulator
; 	ADC #$24           ; Add 3 to the high byte of the nametable address (adjust this based on your starting offset)
; 	STA PPUADDR       ; Store the result in PPUADDR to set the high byte of the nametable address

; 	LDA #$00         ; Load the offset for the first tile
; 	STA PPUADDR       ; Store the offset in PPUADDR
; 	LDA #$24
; 	STA PPUADDR
; 	LDA #$00          ; Load the tile data for the first tile
; 	STA PPUDATA       ; Store the tile data in PPUDATA

; 	LDA #$1c         ; Load the offset for the first tile
; 	STA PPUADDR       ; Store the offset in PPUADDR
; 	LDA #$24
; 	STA PPUADDR
; 	LDA #$30          ; Load the tile data for the first tile
; 	STA PPUDATA 

; 	LDA #$1d         ; Load the offset for the second tile
; 	STA PPUADDR       ; Store the offset in PPUADDR
; 	LDA #$24
; 	STA PPUADDR
; 	LDA #$31          ; Load the tile data for the second tile
; 	STA PPUDATA       ; Store the tile data in PPUDATA

; 	LDA #$3c         ; Load the offset for the third tile
; 	STA PPUADDR       ; Store the offset in PPUADDR
; 	LDA #$24
; 	STA PPUADDR
; 	LDA #$40          ; Load the tile data for the third tile
; 	STA PPUDATA       ; Store the tile data in PPUDATA

; 	LDA #$3D         ; Load the offset for the fourth tile
; 	STA PPUADDR       ; Store the offset in PPUADDR
; 	LDA #$24
; 	STA PPUADDR
; 	LDA #$41          ; Load the tile data for the fourth tile
; 	STA PPUDATA       ; Store the tile data in PPUDATA



; 	; finally, attribute tables
; 	LDA PPUSTATUS
; 	LDA #$23
; 	STA PPUADDR
; 	LDA #$dc
; 	STA PPUADDR
; 	LDA #%00000001
; 	STA PPUDATA

; 	LDA PPUSTATUS
; 	LDA #$2b
; 	STA PPUADDR
; 	LDA #$ca
; 	STA PPUADDR
; 	LDA #%10100000
; 	STA PPUDATA

; 	LDA PPUSTATUS
; 	LDA #$2b
; 	STA PPUADDR
; 	LDA #$d2
; 	STA PPUADDR
; 	LDA #%00001010
; 	STA PPUDATA

; 	RTS
; .endproc



	; ; new additions: galaxy and planet
	; LDA PPUSTATUS
	; LDA #$21
	; STA PPUADDR
	; LDA #$90
	; STA PPUADDR
	; LDX #$30
	; STX PPUDATA
	; LDX #$31
	; STX PPUDATA

	; LDA PPUSTATUS
	; LDA #$21
	; STA PPUADDR
	; LDA #$b0
	; STA PPUADDR
	; LDX #$32
	; STX PPUDATA
	; LDX #$33
	; STX PPUDATA

	; LDA PPUSTATUS
	; LDA #$20
	; STA PPUADDR
	; LDA #$42
	; STA PPUADDR
	; LDX #$38
	; STX PPUDATA
	; LDX #$39
	; STX PPUDATA

	; LDA PPUSTATUS
	; LDA #$20
	; STA PPUADDR
	; LDA #$62
	; STA PPUADDR
	; LDX #$3a
	; STX PPUDATA
	; LDX #$3b
	; STX PPUDATA

	; ; nametable 2 additions: big galaxy, space station
	; LDA PPUSTATUS
	; LDA #$28
	; STA PPUADDR
	; LDA #$c9
	; STA PPUADDR
	; LDA #$41
	; STA PPUDATA
	; LDA #$42
	; STA PPUDATA
	; LDA #$43
	; STA PPUDATA

	; LDA PPUSTATUS
	; LDA #$28
	; STA PPUADDR
	; LDA #$e8
	; STA PPUADDR
	; LDA #$50
	; STA PPUDATA
	; LDA #$51
	; STA PPUDATA
	; LDA #$52
	; STA PPUDATA
	; LDA #$53
	; STA PPUDATA

	; LDA PPUSTATUS
	; LDA #$29
	; STA PPUADDR
	; LDA #$08
	; STA PPUADDR
	; LDA #$60
	; STA PPUDATA
	; LDA #$61
	; STA PPUDATA
	; LDA #$62
	; STA PPUDATA
	; LDA #$63
	; STA PPUDATA

	; LDA PPUSTATUS
	; LDA #$29
	; STA PPUADDR
	; LDA #$28
	; STA PPUADDR
	; LDA #$70
	; STA PPUDATA
	; LDA #$71
	; STA PPUDATA
	; LDA #$72
	; STA PPUDATA

	; ; space station
	; LDA PPUSTATUS
	; LDA #$29
	; STA PPUADDR
	; LDA #$f2
	; STA PPUADDR
	; LDA #$44
	; STA PPUDATA
	; STA PPUDATA

	; LDA PPUSTATUS
	; LDA #$29
	; STA PPUADDR
	; LDA #$f6
	; STA PPUADDR
	; LDA #$44
	; STA PPUDATA
	; STA PPUDATA

	; LDA PPUSTATUS
	; LDA #$2a
	; STA PPUADDR
	; LDA #$12
	; STA PPUADDR
	; LDA #$54
	; STA PPUDATA
	; STA PPUDATA
	; LDA #$45
	; STA PPUDATA
	; LDA #$46
	; STA PPUDATA
	; LDA #$54
	; STA PPUDATA
	; STA PPUDATA

	; LDA PPUSTATUS
	; LDA #$2a
	; STA PPUADDR
	; LDA #$32
	; STA PPUADDR
	; LDA #$44
	; STA PPUDATA
	; STA PPUDATA
	; LDA #$55
	; STA PPUDATA
	; LDA #$56
	; STA PPUDATA
	; LDA #$44
	; STA PPUDATA
	; STA PPUDATA

	; LDA PPUSTATUS
	; LDA #$2a
	; STA PPUADDR
	; LDA #$52
	; STA PPUADDR
	; LDA #$44
	; STA PPUDATA
	; STA PPUDATA

	; LDA PPUSTATUS
	; LDA #$2a
	; STA PPUADDR
	; LDA #$56
	; STA PPUADDR
	; LDA #$44
	; STA PPUDATA
	; STA PPUDATA


	; 	; X register stores high byte of nametable
	; ; write nametables
	; ; big stars first
	; LDA PPUSTATUS
	; TXA
	; STA PPUADDR
	; LDA #$6b
	; STA PPUADDR
	; LDY #$2f
	; STY PPUDATA

	; LDA PPUSTATUS
	; TXA
	; ADC #$01
	; STA PPUADDR
	; LDA #$57
	; STA PPUADDR
	; STY PPUDATA

	; LDA PPUSTATUS
	; TXA
	; ADC #$02
	; STA PPUADDR
	; LDA #$23
	; STA PPUADDR
	; STY PPUDATA

	; LDA PPUSTATUS
	; TXA
	; ADC #$03
	; STA PPUADDR
	; LDA #$52
	; STA PPUADDR
	; STY PPUDATA

	; ; next, small star 1
	; LDA PPUSTATUS
	; TXA
	; STA PPUADDR
	; LDA #$74
	; STA PPUADDR
	; LDY #$2d
	; STY PPUDATA

	; LDA PPUSTATUS
	; TXA
	; ADC #$01
	; STA PPUADDR
	; LDA #$43
	; STA PPUADDR
	; STY PPUDATA

	; LDA PPUSTATUS
	; TXA
	; ADC #$01
	; STA PPUADDR
	; LDA #$5d
	; STA PPUADDR
	; STY PPUDATA

	; LDA PPUSTATUS
	; TXA
	; ADC #$01
	; STA PPUADDR
	; LDA #$73
	; STA PPUADDR
	; STY PPUDATA

	; LDA PPUSTATUS
	; TXA
	; ADC #$02
	; STA PPUADDR
	; LDA #$2f
	; STA PPUADDR
	; STY PPUDATA

	; LDA PPUSTATUS
	; TXA
	; ADC #$02
	; STA PPUADDR
	; LDA #$f7
	; STA PPUADDR
	; STY PPUDATA

	; ; finally, small star 2
	; LDA PPUSTATUS
	; TXA
	; STA PPUADDR
	; LDA #$f1
	; STA PPUADDR
	; LDY #$2e
	; STY PPUDATA

	; LDA PPUSTATUS
	; TXA
	; ADC #$01
	; STA PPUADDR
	; LDA #$a8
	; STA PPUADDR
	; STY PPUDATA

	; LDA PPUSTATUS
	; TXA
	; ADC #$02
	; STA PPUADDR
	; LDA #$7a
	; STA PPUADDR
	; STY PPUDATA

	; LDA PPUSTATUS
	; TXA
	; ADC #$03
	; STA PPUADDR
	; LDA #$44
	; STA PPUADDR
	; STY PPUDATA

	; LDA PPUSTATUS
	; TXA
	; ADC #$03
	; STA PPUADDR
	; LDA #$7c
	; STA PPUADDR
	; STY PPUDATA