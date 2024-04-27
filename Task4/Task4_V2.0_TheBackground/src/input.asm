.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
player_x:           .res 1
player_y:           .res 1
player_dir:         .res 1
scroll:             .res 1
ppuctrl_settings:   .res 1
pad1:               .res 1
frame_counter:      .res 1
animation_counter:  .res 1
camera_x:           .res 1
counter:            .res 1
temp:               .res 1
temp2:              .res 1
temp3:              .res 2
stage:              .res 1
nametable:          .res 1

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

  LDA stage
  CMP #$01
  BNE no_stage_change
  continues:
    lda #$00
    sta $2000
    sta $2001
    JSR draw_background2
    LDA #%10010000  ; turn on NMIs, sprites use first pattern table
      STA ppuctrl_settings
      STA PPUCTRL
      LDA #%00011110  ; turn on screen
      STA PPUMASK
      LDA #$00
      STA PPUSCROLL
      STA PPUSCROLL
      STA scroll
      STA nametable
      LDA #$00
      STA player_x
      STA counter
      LDA #$20
      STA player_y
      INC stage

  no_stage_change:
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
  EOR #%00000001 
  STA ppuctrl_settings
  STA PPUCTRL
  LDA #00
  STA scroll
  STA PPUSCROLL
  STA PPUSCROLL
  LDA #$01
  STA counter
  STA nametable
  JMP meh

set_scroll_positions:
  LDA scroll        ; Set horizontal scroll
  STA PPUSCROLL
  LDA #$00          ; Y scroll stays constant
  STA PPUSCROLL

  RTI
meh:
  RTI
.endproc

.import reset_handler

.export main
.proc main
  LDA #$00
  STA scroll
  STA camera_x  ; Initialize camera_x to 0 at the game start (make sure it's 0)
  STA counter
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

  JSR drawBackground

vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA ppuctrl_settings
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK
  LDA #$00
  STA PPUSCROLL
  STA PPUSCROLL

forever:
  JMP forever
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
  CLC       ; Clearing carry flag preparing for addition. ->
  ADC #$08    ; For now we will use this until we need to add something to a 16-bit number.
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

.proc drawBackground
	LDX #$00
	STX temp2

	LDA #$10        ; Load the low byte (10 in hex)
	STA temp3       ; Store it in ztemp (low byte)
	LDA #$00        ; Load the high byte (0, since 10 is less than 256)
	STA temp3+1     ; Store it in ztemp+1 (high byte)

	LDA #$00
	STA temp

	FirstWorld:
		LDA PPUSTATUS
		LDA #$20
		STA PPUADDR    
		LDA #$00
		STA PPUADDR  

		OuterLoop:
		Start:
		LDY #$00

		LoopAgain:   
		LDX temp2
		Loop:  
			LDA tile_map,X       
			STA PPUDATA 
			LDA tile_map,X       
			STA PPUDATA    
			INX           
			CPX temp3  
			BNE Loop
		INY
		CPY #$02
		BNE LoopAgain
		
		LDA temp3       ; Load the low byte of ztemp
		CLC             ; Clear the carry flag before addition
		ADC #$10      ; Add 30 (1E in hex) to the accumulator
		STA temp3       ; Store the result back in ztemp

		LDA temp3+1     ; Load the high byte of ztemp
		ADC #$00        ; Add any carry from the previous addition
		STA temp3+1     ; Store the result back in ztemp+1

		STX temp2 

		LDA temp
		CLC       ; Clear the carry flag to ensure clean addition
		ADC #$01  ; Add with carry the value 1 to the accumulator
		STA temp

		CMP #$0F 
		BEQ END

		JMP OuterLoop
	END:
	LDX #$00
	LDA PPUSTATUS    ; Reset the address latch
	LDA #$23         ; High byte of $23C0
	STA PPUADDR
	LDA #$C0         ; Low byte of $23C0
	STA PPUADDR

	LoadAttribute:
		LDA attribute, X        ; Load an attribute byte (example data)
		STA PPUDATA      ; Write it to PPU
		INX
		CPX #$40
		BNE LoadAttribute


	LDX #$00
	STX temp2

	LDA #$10        ; Load the low byte (10 in hex)
	STA temp3       ; Store it in ztemp (low byte)
	LDA #$00        ; Load the high byte (0, since 10 is less than 256)
	STA temp3+1     ; Store it in ztemp+1 (high byte)

	LDA #$00
	STA temp

	
		LDA PPUSTATUS
		LDA #$24
		STA PPUADDR    
		LDA #$00
		STA PPUADDR  
		JMP Start1
		OuterLoop1:
		
		Start1:
		LDY #$00

		LoopAgain1:   
		LDX temp2
		Loop1:  
			LDA tile_map1,X       
			STA PPUDATA 
			LDA tile_map1,X       
			STA PPUDATA    
			INX           
			CPX temp3  
			BNE Loop1
		INY
		CPY #$02
		BNE LoopAgain1
		
		LDA temp3       ; Load the low byte of ztemp
		CLC             ; Clear the carry flag before addition
		ADC #$10      ; Add 30 (1E in hex) to the accumulator
		STA temp3       ; Store the result back in ztemp

		LDA temp3+1     ; Load the high byte of ztemp
		ADC #$00        ; Add any carry from the previous addition
		STA temp3+1     ; Store the result back in ztemp+1

		STX temp2 

		LDA temp
		CLC       ; Clear the carry flag to ensure clean addition
		ADC #$01  ; Add with carry the value 1 to the accumulator
		STA temp

		CMP #$0F 
		BEQ END1

		JMP OuterLoop1
		END1:

	LDX #$00
	LDA PPUSTATUS    ; Reset the address latchss
	LDA #$27         ; High byte of $23C0
	STA PPUADDR
	LDA #$C0         ; Low byte of $23C0
	STA PPUADDR

	LoadAttribute1:
		LDA attribute1, X        ; Load an attribute byte (example data)
		STA PPUDATA      ; Write it to PPU
		INX
		CPX #$40
		BNE LoadAttribute1

	RTS
.endproc

.proc draw_background2
	LDX #$00
	STX temp2

	LDA #$10        ; Load the low byte (10 in hex)
	STA temp3       ; Store it in ztemp (low byte)
	LDA #$00        ; Load the high byte (0, since 10 is less than 256)
	STA temp3+1     ; Store it in ztemp+1 (high byte)

	LDA #$00
	STA temp

	FirstWorld:
		LDA PPUSTATUS
		LDA #$20
		STA PPUADDR    
		LDA #$00
		STA PPUADDR  

		OuterLoop:
		Start:
		LDY #$00

		LoopAgain:   
		LDX temp2
		Loop:  
			LDA tile_map2,X       
			STA PPUDATA 
			LDA tile_map2,X       
			STA PPUDATA    
			INX           
			CPX temp3  
			BNE Loop
		INY
		CPY #$02
		BNE LoopAgain
		
		LDA temp3       ; Load the low byte of ztemp
		CLC             ; Clear the carry flag before addition
		ADC #$10      ; Add 30 (1E in hex) to the accumulator
		STA temp3       ; Store the result back in ztemp

		LDA temp3+1     ; Load the high byte of ztemp
		ADC #$00        ; Add any carry from the previous addition
		STA temp3+1     ; Store the result back in ztemp+1

		STX temp2 

		LDA temp
		CLC       ; Clear the carry flag to ensure clean addition
		ADC #$01  ; Add with carry the value 1 to the accumulator
		STA temp

		CMP #$0F 
		BEQ END

		JMP OuterLoop
	END:
	LDX #$00
	LDA PPUSTATUS    ; Reset the address latch
	LDA #$23         ; High byte of $23C0
	STA PPUADDR
	LDA #$C0         ; Low byte of $23C0
	STA PPUADDR

	LoadAttribute:
		LDA attribute2, X        ; Load an attribute byte (example data)
		STA PPUDATA      ; Write it to PPU
		INX
		CPX #$40
		BNE LoadAttribute


	LDX #$00
	STX temp2

	LDA #$10        ; Load the low byte (10 in hex)
	STA temp3       ; Store it in ztemp (low byte)
	LDA #$00        ; Load the high byte (0, since 10 is less than 256)
	STA temp3+1     ; Store it in ztemp+1 (high byte)

	LDA #$00
	STA temp

	
		LDA PPUSTATUS
		LDA #$24
		STA PPUADDR    
		LDA #$00
		STA PPUADDR  
		JMP Start1
		OuterLoop1:
		
		Start1:
		LDY #$00

		LoopAgain1:   
		LDX temp2
		Loop1:  
			LDA tile_map3,X       
			STA PPUDATA 
			LDA tile_map3,X       
			STA PPUDATA    
			INX           
			CPX temp3  
			BNE Loop1
		INY
		CPY #$02
		BNE LoopAgain1
		
		LDA temp3       ; Load the low byte of ztemp
		CLC             ; Clear the carry flag before addition
		ADC #$10      ; Add 30 (1E in hex) to the accumulator
		STA temp3       ; Store the result back in ztemp

		LDA temp3+1     ; Load the high byte of ztemp
		ADC #$00        ; Add any carry from the previous addition
		STA temp3+1     ; Store the result back in ztemp+1

		STX temp2 

		LDA temp
		CLC       ; Clear the carry flag to ensure clean addition
		ADC #$01  ; Add with carry the value 1 to the accumulator
		STA temp

		CMP #$0F 
		BEQ END1

		JMP OuterLoop1
		END1:

	LDX #$00
	LDA PPUSTATUS    ; Reset the address latchss
	LDA #$27         ; High byte of $23C0
	STA PPUADDR
	LDA #$C0         ; Low byte of $23C0
	STA PPUADDR

	LoadAttribute1:
		LDA attribute3, X        ; Load an attribute byte (example data)
		STA PPUDATA      ; Write it to PPU
		INX
		CPX #$40
		BNE LoadAttribute1

	RTS
.endproc


.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"
palettes:
.byte $0f, $1c, $3d, $2d
.byte $0f, $2a, $30, $11
.byte $0f, $0c, $07, $13
.byte $0f, $19, $09, $29

.byte $0f, $26, $21, $30
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29

tile_map:
  .byte $00, $00, $00, $00, $00, $00, $00, $00, $B2, $00, $00, $00, $00, $00, $00, $00, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $00, $00, $00, $A7, $87, $87, $55, $92, $00, $00, $55, $87, $00, $00, $55, $77, $00, $55, $00, $55, $56, $87, $92, $92, $55, $87, $55, $87, $55, $00, $55, $77, $00, $55, $00, $00, $55, $56, $56, $56, $57, $87, $87, $87, $55, $00, $55, $77, $87, $55, $56, $56, $56, $92, $00, $00, $55, $87, $55, $87, $55, $00, $55, $77, $87, $A8, $00, $55, $87, $87, $55, $00, $00, $87, $55, $87, $55, $00, $55, $77, $87, $55, $92, $00, $87, $55, $57, $56, $56, $56, $56, $87, $55, $00, $00, $77, $87, $55, $00, $55, $87, $00, $55, $92, $00, $00, $87, $87, $55, $56, $56, $77, $87, $55, $92, $55, $87, $55, $57, $92, $55, $57, $87, $87, $55, $00, $55, $77, $00, $55, $00, $55, $87, $87, $55, $92, $92, $55, $00, $55, $56, $00, $55, $77, $00, $55, $00, $55, $57, $57, $57, $57, $00, $55, $92, $00, $55, $00, $55, $77, $A8, $55, $00, $55, $87, $87, $87, $55, $00, $55, $56, $00, $55, $00, $55, $B2, $00, $55, $B7, $87, $87, $55, $87, $87, $87, $55, $00, $00, $00, $00, $55, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77

attribute:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$20,$a4,$19,$80,$98,$91,$aa
	.byte $44,$a2,$a8,$0a,$8a,$95,$99,$aa,$44,$20,$46,$a9,$a0,$a9,$99,$2a
	.byte $44,$22,$66,$a8,$80,$64,$99,$8a,$00,$22,$a6,$a9,$20,$22,$8a,$88
	.byte $00,$22,$56,$65,$52,$2a,$08,$88,$00,$00,$00,$00,$00,$00,$00,$00

tile_map1:
.byte $50, $50, $55, $50, $80, $90, $95, $20, $88, $99, $8A, $A6, $88, $A1, $65, $88,
attribute1:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$20,$a4,$19,$80,$98,$91,$aa
	.byte $44,$a2,$a8,$0a,$8a,$95,$99,$aa,$44,$20,$46,$a9,$a0,$a9,$99,$2a
	.byte $44,$22,$66,$a8,$80,$64,$99,$8a,$00,$22,$a6,$a9,$20,$22,$8a,$88
	.byte $00,$22,$56,$65,$52,$2a,$08,$88,$00,$00,$00,$00,$00,$00,$00,$00

tile_map2:
  .byte $00, $00, $00, $00, $00, $00, $00, $00, $B2, $00, $00, $00, $00, $00, $00, $00, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $00, $00, $00, $A7, $87, $87, $55, $92, $00, $00, $55, $87, $00, $00, $55, $77, $00, $55, $00, $55, $56, $87, $92, $92, $55, $87, $55, $87, $55, $00, $55, $77, $00, $55, $00, $00, $55, $56, $56, $56, $57, $87, $87, $87, $55, $00, $55, $77, $87, $55, $56, $56, $56, $92, $00, $00, $55, $87, $55, $87, $55, $00, $55, $77, $87, $A8, $00, $55, $87, $87, $55, $00, $00, $87, $55, $87, $55, $00, $55, $77, $87, $55, $92, $00, $87, $55, $57, $56, $56, $56, $56, $87, $55, $00, $00, $77, $87, $55, $00, $55, $87, $00, $55, $92, $00, $00, $87, $87, $55, $56, $56, $77, $87, $55, $92, $55, $87, $55, $57, $92, $55, $57, $87, $87, $55, $00, $55, $77, $00, $55, $00, $55, $87, $87, $55, $92, $92, $55, $00, $55, $56, $00, $55, $77, $00, $55, $00, $55, $57, $57, $57, $57, $00, $55, $92, $00, $55, $00, $55, $77, $A8, $55, $00, $55, $87, $87, $87, $55, $00, $55, $56, $00, $55, $00, $55, $B2, $00, $55, $B7, $87, $87, $55, $87, $87, $87, $55, $00, $00, $00, $00, $55, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77

attribute2:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$20,$a4,$19,$80,$98,$91,$aa
	.byte $44,$a2,$a8,$0a,$8a,$95,$99,$aa,$44,$20,$46,$a9,$a0,$a9,$99,$2a
	.byte $44,$22,$66,$a8,$80,$64,$99,$8a,$00,$22,$a6,$a9,$20,$22,$8a,$88
	.byte $00,$22,$56,$65,$52,$2a,$08,$88,$00,$00,$00,$00,$00,$00,$00,$00

tile_map3:
  .byte $00, $00, $00, $00, $00, $00, $00, $00, $B2, $00, $00, $00, $00, $00, $00, $00, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $00, $00, $00, $A7, $87, $87, $55, $92, $00, $00, $55, $87, $00, $00, $55, $77, $00, $55, $00, $55, $56, $87, $92, $92, $55, $87, $55, $87, $55, $00, $55, $77, $00, $55, $00, $00, $55, $56, $56, $56, $57, $87, $87, $87, $55, $00, $55, $77, $87, $55, $56, $56, $56, $92, $00, $00, $55, $87, $55, $87, $55, $00, $55, $77, $87, $A8, $00, $55, $87, $87, $55, $00, $00, $87, $55, $87, $55, $00, $55, $77, $87, $55, $92, $00, $87, $55, $57, $56, $56, $56, $56, $87, $55, $00, $00, $77, $87, $55, $00, $55, $87, $00, $55, $92, $00, $00, $87, $87, $55, $56, $56, $77, $87, $55, $92, $55, $87, $55, $57, $92, $55, $57, $87, $87, $55, $00, $55, $77, $00, $55, $00, $55, $87, $87, $55, $92, $92, $55, $00, $55, $56, $00, $55, $77, $00, $55, $00, $55, $57, $57, $57, $57, $00, $55, $92, $00, $55, $00, $55, $77, $A8, $55, $00, $55, $87, $87, $87, $55, $00, $55, $56, $00, $55, $00, $55, $B2, $00, $55, $B7, $87, $87, $55, $87, $87, $87, $55, $00, $00, $00, $00, $55, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77

attribute3:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$20,$a4,$19,$80,$98,$91,$aa
	.byte $44,$a2,$a8,$0a,$8a,$95,$99,$aa,$44,$20,$46,$a9,$a0,$a9,$99,$2a
	.byte $44,$22,$66,$a8,$80,$64,$99,$8a,$00,$22,$a6,$a9,$20,$22,$8a,$88
	.byte $00,$22,$56,$65,$52,$2a,$08,$88,$00,$00,$00,$00,$00,$00,$00,$00
.segment "CHR"
.incbin "bomberman_v3.chr"
