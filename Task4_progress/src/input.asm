.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
player_dir: .res 1
scroll: .res 1
ppuctrl_settings: .res 1
pad1: .res 1
frame_counter: .res 1
animation_counter: .res 1
camera_x: .res 1
; ppuctrl_settings: .res 1
player_1_y: .res 1
player_1_x: .res 1
current_player_x: .res 1
current_player_y: .res 1
sprite_offset: .res 1
choose_sprite_orientation: .res 1
tick_count: .res 1
controller_read_output: .res 1
wings_flap_state: .res 1 ; wings_flap_state: 0 -> wings are open, wings_flap_state: 1 -> wings are closed
player_direction: .res 1 ; direction: UP -> 0 | RIGHT -> 16 (#$10) | LEFT -> 32 (#$20) | DOWN -> 48 (#$30)
tile_to_display: .res 1
high_byte_nametable_address: .res 1
low_byte_nametable_address: .res 1
current_byte_of_tiles: .res 1
fix_low_byte_row_index: .res 1
choose_which_background: .res 1 ; 0 -> background stage 1 part 1 | 1 -> stage 1 part 2 | 2 -> stage 2 part 1 | 3 -> stage 2 part 2
current_stage: .res 1 ; 1 -> stage 1 | 2 -> stage 2
; ppuctrl_settings: .res 1
change_background_flag: .res 1
; scroll: .res 1 ;used to increment the PPUSCROLL register
flag_scroll: .res 1 ; used to know when to write on ppuscroll



.exportzp player_x, player_y, pad1

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.import read_controller1

.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
	LDA #$00

	; read controller
	JSR read_controller1

  ; update tiles *after* DMA transfer
	; and after reading controller state
	JSR update_player
  JSR draw_player

	LDA scroll
	CMP #$ff ; did we scroll to the end of a nametable?
	BNE set_scroll_positions
	; if yes,
	; Update base nametable
	LDA ppuctrl_settings
	EOR #%00000100 ; flip bit 1 to its opposite
	STA ppuctrl_settings
	STA PPUCTRL
	LDA #00
	STA scroll

set_scroll_positions:
  LDA scroll        ; Set horizontal scroll
  STA PPUSCROLL
  LDA #$00          ; Y scroll stays constant
  STA PPUSCROLL

JSR update_tick_count ;Handle the update tick (resetting to zero or incrementing)

  

  JSR update_player ; draws the player on the screen

  LDA change_background_flag
  CMP #$01
  BNE skip_change_background

    player_position_stage_2:
      LDA #31
      STA player_1_y; 
      STA current_player_y
      LDA #$00
      STA player_1_x; 
      STA current_player_x 



    LDA current_stage 
    EOR #%11
    STA current_stage

    jsr display_stage_background
    lda #$00
    sta change_background_flag
    
    reset_scrolling:
      
      STA scroll          ; reset scroll acumulator
      STA flag_scroll     ; reset scroll flag
      STA PPUSCROLL       ; PPUSCROLL_X = 0
      STA PPUSCROLL       ; PPUSCROLL_Y = 0

  skip_change_background:

  LDA flag_scroll
  CMP #$00
  BEQ skip_ppuscroll_write

  INC scroll
  LDA scroll
  BNE skip_scroll_reset
    LDA #255
    STA scroll 
  
  skip_scroll_reset:
  STA PPUSCROLL ; $2005 IS PPU SCROLL, it takes two writes: X Scroll , Y Scroll
  LDA #$00      ; writing 00 to y, so that the next time we write to ppuscroll we write to the x
  STA PPUSCROLL

  skip_ppuscroll_write: ;Skip writing the ppuscroll until the player presses


  RTI
.endproc

.import reset_handler
; .import draw_starfield
; .import draw_objects

.export main
.proc main
	LDA #239	 ; Y is only 240 lines tall!
	STA scroll

  LDA #0
  STA camera_x  ; Initialize camera_x to 0 at the game start

  ; write a palette
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR
load_palettes:
  LDA palettes,X
  STA PPUDATA
  INX
  CPX #$20
  BNE load_palettes

lda #$01
sta current_stage
; preguntart en que stage tu estas
; choose_which background = 0
JSR display_stage_background

	; ; write nametables
	; LDX #$20
	; JSR draw_starfield

	; LDX #$28
	; JSR draw_starfield

	; JSR draw_objects

vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
	STA ppuctrl_settings
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK

init_ppuscroll: ;Initialize ppu scroll to X -> 0 & Y -> 0
  LDA #$00
  STA PPUSCROLL
  STA PPUSCROLL

forever:
  JMP forever
.endproc

; display_tile subroutine
; tile_index -> $00
; low byte -> $01
; high byte -> $02
.proc display_tile
  LDA PPUSTATUS; 
  LDA $02 ; LOADING highbyte to the accumulator
  STA PPUADDR
  LDA $01 ; LOADING lowbyte to the accumulator
  STA PPUADDR
; 00000100
  LDA $00
  STA PPUDATA
  
  rts ; return from subroutine
.endproc

; PARAMS
; current_stage --> 1 for stage 1 | 2 for stage 2
.proc display_stage_background
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  disable_rendering:
    LDA #%00000000  ; turning off backgrounds not sprites
    STA PPUMASK

    
    LDA ppuctrl_settings  ;turn off NMI
    AND #%01111000
    STA PPUCTRL
    STA ppuctrl_settings

  LDA current_stage
  CMP #$02
  BEQ prep_stage_2 ; if current_stage is 2, then branch to prep for stage 2; else: jump to prep for stage 1

  prep_stage_1:
    ; current_stage = 1
    LDA #$00
    sta choose_which_background ; setting choose_which_background to 0 so it can choose the maps for stage 1

  JMP finished_preparing

  prep_stage_2:
    ; current_stage = 2
    LDA #$02
    sta choose_which_background


  finished_preparing:
  LDY #$00
  sty fix_low_byte_row_index
  STY low_byte_nametable_address

  LDA #$20
  STA high_byte_nametable_address

  JSR display_one_nametable_background

    ; MUST ADD 1 to choose_which_background to display the SECOND part of that stage
      LDA choose_which_background
      clc
      adc #$01
      sta choose_which_background ; choose_which_background += 1
    

  LDY #$00
  sty fix_low_byte_row_index
  STY low_byte_nametable_address

  LDA #$24
  STA high_byte_nametable_address

  JSR display_one_nametable_background

  enable_rendering:

    LDA #%10010000  ; turn on NMIs, sprites use first pattern table
    STA PPUCTRL
    STA ppuctrl_settings
    LDA #%00011110  ; turn on screen
    STA PPUMASK


  PLA
  TAY
  PLA
  TAX
  PLA
  PLP 
RTS
.endproc

; PARAMS:
; fix_low_byte_row_index -> should be set to zero (will go from 0 to 4 then back to 0)
; low_byte_nametable_address
; high_byte_nametable_address
; choose_which_background
.proc display_one_nametable_background
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

load_background:
  LDA choose_which_background
  CMP #$00
  BNE test_for_stage_1_part_2

    LDA background_stage_1_part_1, Y
    JMP background_selected

test_for_stage_1_part_2:
  CMP #$01
  BNE test_for_stage_2_part_1

    LDA background_stage_1_part_2, Y
    JMP background_selected
test_for_stage_2_part_1:
  CMP #$02
  BNE test_for_stage_2_part_2

    LDA background_stage_2_part_1, Y
    jmp background_selected

test_for_stage_2_part_2:
  ; at this point, this is practically an ELSE statement so it must be stage 2 part 2
    LDA background_stage_2_part_2, Y

  background_selected:
  
  STA current_byte_of_tiles
  JSR display_byte_of_tiles
  INY
  increment_fix_low_byte_row_index:
    lda fix_low_byte_row_index
    clc
    adc #$01
    sta fix_low_byte_row_index
  lda fix_low_byte_row_index
  cmp #$04 ; compare if fix_low_byte_row_index is 4
  BNE skip_low_byte_row_fix
    ; lda #$e0
    lda low_byte_nametable_address
    clc
    adc #$20 ; add 32 to skip to the next row
    sta low_byte_nametable_address
    bcc skip_overflow_fix_2
      ; if PC is here, then add 1 to high byte because of overflow
      lda high_byte_nametable_address
      clc
      adc #$01
      sta high_byte_nametable_address
    skip_overflow_fix_2:
      LDA #$00
      sta fix_low_byte_row_index

  skip_low_byte_row_fix:
    cpy #$3C
    bne load_background

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP 
RTS
.endproc

; PARAMS:
; current_byte_of_tiles
; tile_to_display
; high_byte_nametable_address 
; low_byte_nametable_address (must be updated within function)

.proc display_byte_of_tiles
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  ldx #$00 ; X will be our index to run the loop 4 times
  process_byte_of_tiles_loop:
    LDA #$00
    STA tile_to_display ; clear the tile to display var to zero (since we might have left over bits from previous loops)
    ASL current_byte_of_tiles ; place 7th bit of current_byte_of_tiles in CARRY flag and place a 0 in the current_byte_of_tiles (shift left)
    ROL tile_to_display ; rotate left the carry flag onto tile_to_display : C <- 7 6 5 4 3 2 1 0 <- C
    ASL current_byte_of_tiles ; C <- 7 6 5 4 3 2 1 0 <- 0
    ROL tile_to_display
    ; ask in which stage you are in
    ; si estas en stage 2 pues sumale 4 al tile to display
    lda current_stage
    CMP #$01
    BEQ skip_addition_to_display
      ; here it's stage 2
      lda tile_to_display
      clc
      adc #$04
      sta tile_to_display

    skip_addition_to_display:
    JSR display_4_background_tiles

    LDA low_byte_nametable_address
    CLC 
    ADC #$02 
    STA low_byte_nametable_address ; low_byte_nametable_address += 2
    
    BCC skip_overflow_fix
    ; MUST CHECK FOR OVERFLOW HERE !!! CHECK CARRY FLAG
    ;if there was overflow when adding 2 to low_byte, then increase high_byte by 1. Low_byte should have correct value already
    LDA high_byte_nametable_address
    CLC
    ADC #$01
    sta high_byte_nametable_address

    skip_overflow_fix:
      INX
      CPx #$04
      Bne process_byte_of_tiles_loop

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP   



RTS
.endproc

; PARAMS:
; tile_to_display
; high_byte_nametable_address
; low_byte_nametable_address
.proc display_4_background_tiles
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

LDA PPUSTATUS ; Read from PPUSTATUS ONCE to ensure that the next write to ppuaddr is the high byte (reset it)
; TOP LEFT
  LDA high_byte_nametable_address
  STA PPUADDR
  LDA low_byte_nametable_address
  STA PPUADDR
  LDA tile_to_display
  STA PPUDATA

; TOP RIGHT
  LDA high_byte_nametable_address
  STA PPUADDR
  LDA low_byte_nametable_address
  CLC ; CLEAR CARRY FLAG BEFORE ADDING
  ADC #$01 ; adding 1 to low byte nametable_address
  STA PPUADDR
  LDA tile_to_display
  STA PPUDATA

     ; finally, attribute table
	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$f0
	STA PPUADDR
	LDA #%01000000
	STA PPUDATA



  ; bottom LEFT
  LDX #$00
  JSR handle_bottom_left_or_right

  ; bottom RIGHT
  ldx #$01
  jsr handle_bottom_left_or_right

   PLA
  TAY
  PLA
  TAX
  PLA
  PLP


RTS
.endproc

.proc handle_bottom_left_or_right
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  ; BEFORE CALLING THIS SUBROUTINE: 
  ; if X is 0 then we are handling bottom left tile
  ; if X is 1 then we are handling bottom right tile
  TXA
  CMP #$01
  beq add_to_low_byte_right_version

  LDA low_byte_nametable_address
  CLC ; CLEAR CARRY FLAG BEFORE ADDING
  ADC #$20 ; adding 32 to low byte nametable_address
  jmp check_overflow

add_to_low_byte_right_version:
  LDA low_byte_nametable_address
  CLC ; CLEAR CARRY FLAG BEFORE ADDING
  ADC #$21 ; adding 33 to low byte nametable_address

check_overflow:
  ; MUST CHECK IF CARRY FLAG WAS ACTIVATED
  BCC add_with_no_overflow

  ; if Program Counter is here, there was OVERFLOW
  ; if carry was SET: then we must add 1 to the high byte and set low_byte to 00
  LDA high_byte_nametable_address
  clc 
  adc #$01 ; accumulator = high_byte + 1
  sta PPUADDR
  TXA
  cmp #$01 ; check if we are handling right tile
  beq store_low_byte_for_right

  ; LOW BYTE FOR LEFT
  lda low_byte_nametable_address
  clc 
  adc #$20 ; an overflow will occur BUT, the accumulator will contain the correct value for the low byte
  STA PPUADDR 
  jmp store_tile_to_ppu

  store_low_byte_for_right:
  lda low_byte_nametable_address
  clc 
  adc #$21
  STA PPUADDR
  jmp store_tile_to_ppu
  
add_with_no_overflow: 
  ; IF THERE WAS NO OVERFLOW -> high_byte stays the same
  LDA high_byte_nametable_address
  sta PPUADDR
  TXA
  cmp #$01
  beq store_low_byte_for_right_no_overflow

  LDA low_byte_nametable_address
  CLC ; CLEAR CARRY FLAG BEFORE ADDING
  ADC #$20 
  sta PPUADDR
  jmp store_tile_to_ppu

store_low_byte_for_right_no_overflow:
  LDA low_byte_nametable_address
  CLC ; CLEAR CARRY FLAG BEFORE ADDING
  ADC #$21 ; accumulator = low_byte + 0x21 since we are handling the right tile
  sta PPUADDR

store_tile_to_ppu:

  LDA tile_to_display
  STA PPUDATA


  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
RTS
.endproc
.proc update_tick_count
  LDA tick_count       ; Load the updated tick_count into A for comparison
  CLC                  ; Clear the carry flag
  ADC #$1              ; Add one to the A register

  CMP #$28               ; Compare A (tick_count) with 0x28 -> 40
  BEQ reset_tick       ; If equal, branch to resetCount label

  CMP #$14            ; Compare A again (tick_count) with 0x14 -> 20
  BNE done              ; If not equal, we are done, skip to done label
  
  ; If CMP #30 was equal, fall through to here
  STA tick_count
  LDA #$01
  STA wings_flap_state
  RTS            

reset_tick:
  LDA #$00             ; Load A with 0
  STA tick_count       ; Reset tick_count to 0 
  STA wings_flap_state    
  RTS

done:
  STA tick_count
  RTS
.endproc




.proc update_player
  PHP  ; Start by saving registers,
  PHA  ; as usual.
  TXA
  PHA
  TYA
  PHA

  LDA pad1        ; Load button presses
  AND #BTN_LEFT   ; Filter out all but Left
  BEQ check_right ; If result is zero, left not pressed
  DEC player_x  ; If the branch is not taken, move player left
check_right:
  LDA pad1
  AND #BTN_RIGHT
  BEQ check_up
  INC player_x
check_up:
  LDA pad1
  AND #BTN_UP
  BEQ check_down
  DEC player_y
check_down:
  LDA pad1
  AND #BTN_DOWN
  BEQ check_direction
  INC player_y

check_direction:
  LDA pad1
  AND #BTN_LEFT
  BEQ check_right_dir
  LDA #$03
  STA player_dir
  JMP done_checking

check_right_dir:
  LDA pad1
  AND #BTN_RIGHT
  BEQ check_up_dir
  LDA #$01
  STA player_dir
  JMP done_checking

check_up_dir:
  LDA pad1
  AND #BTN_UP
  BEQ check_down_dir
  LDA #$02
  STA player_dir
  JMP done_checking

check_down_dir:
  LDA pad1
  AND #BTN_DOWN
  BEQ done_checking
  LDA #$00
  STA player_dir

done_checking:
  ;; CHECKING FOR SCROLLING ---------------------------------
  LDA player_x              ; Load player's x position
  CMP camera_x              ; Compare it to camera_x
  BCC skip_scroll_update    ; If player < 100, don't scroll
  SBC #100                  ; Subtract the camera_x from player_x
  BMI skip_scroll_update    ; If player < 100, don't scroll

  ; Only adjust camera_x if player is moving right and pushing the screen boundary
  LDA pad1                  ; Assuming pad1 holds the current input state
  AND #BTN_RIGHT            ; Check if the right button is pressed
  BEQ skip_scroll_update    ; If right is not pressed, skip updating camera

  STA camera_x        ; Update camera position to new player position minus threshold
  INC scroll          ; Increment scroll to signal a scroll update
  DEC player_x        ; Move player back to the left by 1 pixel
skip_scroll_update:

  ; Check if player is at the left edge of the screen
  LDA player_x
  CMP #$00
  BNE no_at_left_edge
  INC player_x
no_at_left_edge:

  ;; CHECKING FOR ANIMATION ---------------------------------
  INC animation_counter
  LDA animation_counter
  CMP #06
  BNE no_update

  LDA #0
  STA animation_counter
  INC frame_counter
  LDA frame_counter
  AND #%00000011
  STA frame_counter

no_update:
  PLA ; Done with updates, restore registers
  TAY ; and return to where we called this
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc draw_player
  	; save registers
	PHP
	PHA
	TXA
	PHA
  TYA
  PHA
  
  
	LDA player_dir
	CMP #$01
	BEQ rightFrame
	CMP #$02
	BEQ upFrame
	CMP #$03
	BEQ leftFrame
	JMP downFrame

	; Player Walking left tile numbers
leftFrame:
    LDA frame_counter
    BEQ left_frame_1
    ; Draw left frame 2
    LDA #$05
    STA $0201
    LDA #$06
    STA $0205
    LDA #$15
    STA $0209
    LDA #$16
    STA $020d
    JMP attributes

left_frame_1:
    ; Draw left frame 1
    LDA #$01
    STA $0201
    LDA #$02
    STA $0205
    LDA #$11
    STA $0209
    LDA #$12
    STA $020d
    JMP attributes

rightFrame:
    LDA frame_counter
    BEQ right_frame_1
    ; Draw right frame 2
    LDA #$25
    STA $0201
    LDA #$26
    STA $0205
    LDA #$35
    STA $0209
    LDA #$36
    STA $020d
    JMP attributes

right_frame_1:
    ; Draw right frame 1
    LDA #$21
    STA $0201
    LDA #$22
    STA $0205
    LDA #$31
    STA $0209
    LDA #$32
    STA $020d
    JMP attributes

upFrame:
    LDA frame_counter
    BEQ up_frame_1
    ; Draw up frame 2
    LDA #$2b
    STA $0201
    LDA #$2c
    STA $0205
    LDA #$3b
    STA $0209
    LDA #$3c
    STA $020d
    JMP attributes

up_frame_1:
    ; Draw up frame 1
    LDA #$27
    STA $0201
    LDA #$28
    STA $0205
    LDA #$37
    STA $0209
    LDA #$38
    STA $020d
    JMP attributes

downFrame:
    LDA frame_counter
    BEQ down_frame_1
    ; Draw down frame 2
    LDA #$0b
    STA $0201
    LDA #$0c
    STA $0205
    LDA #$1b
    STA $0209
    LDA #$1c
    STA $020d
    JMP attributes

down_frame_1:
    ; Draw down frame 1
    LDA #$07
    STA $0201
    LDA #$08
    STA $0205
    LDA #$17
    STA $0209
    LDA #$18
    STA $020d
    JMP attributes
	
attributes:
	; Player attributes 
	LDA #$00
	STA $0202
	STA $0206
	STA $020a
	STA $020e

	STA $0204
	STA $0208
	STA $020c
	STA $0210

	; store tile locations
	; top left tile:
	LDA player_y
	STA $0200
	LDA player_x
	STA $0203

	; top right tile (x + 8):
	LDA player_y
	STA $0204
	LDA player_x
	CLC
	ADC #$08
	STA $0207

	; bottom left tile (y + 8):
	LDA player_y
	CLC				; Clearing carry flag preparing for addition. ->
	ADC #$08		; For now we will use this until we need to add something to a 16-bit number.
	STA $0208
	LDA player_x
	STA $020b

	; bottom right tile (x + 8, y + 8)
	LDA player_y
	CLC
	ADC #$08
	STA $020c
	LDA player_x
	CLC
	ADC #$08
	STA $020f

	; Restoring registers and return 
	PLA
  TAY
	PLA
 	TAX
 	PLA
 	PLP
 	RTS
.endproc



.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"

;include stage 1 and 2 maps
.include "worldStage_1.asm"
.include "worldStage_2.asm"

palettes:
.byte $0f, $1c, $3d, $2d
.byte $0f, $2a, $30, $11
.byte $0f, $0c, $07, $13
.byte $0f, $19, $09, $29

.byte $0f, $26, $21, $30
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29

.segment "CHR"
.incbin "bomberman_v3.chr"