.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
  horizontal_player_x: .res 1
  horizontal_player_y: .res 1
  horizontal_player_dir: .res 1
  vertical_player_x: .res 1
  vertical_player_y: .res 1
  vertical_player_dir: .res 1
  frame_counter: .res 1
  animation_counter: .res 1
.exportzp horizontal_player_x, horizontal_player_y, vertical_player_x, vertical_player_y

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  	LDA #$00
  	STA OAMADDR
  	LDA #$02
  	STA OAMDMA

	; Updates tiles *after* DMA (Direct Memory Address) transfer
	JSR update_player_horizontal
  JSR draw_player_horizontal
  JSR update_player_vertical
  JSR draw_player_vertical

	LDA #$00
	STA $2005
	STA $2005
  RTI
.endproc

.import reset_handler

.export main
.proc main
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

  ; write sprite data
  LDX #$00


vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK

forever:
  JMP forever
.endproc

.proc update_player_horizontal
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDA horizontal_player_x
  CMP #$e0
  BCC not_at_right_edge
  ; if BCC is not taken, we are greater than $e0
  LDA #$00
  STA horizontal_player_dir    ; start moving left
  JMP direction_set ; we already chose a direction,
                    ; so we can skip the left side check
not_at_right_edge:
  LDA horizontal_player_x
  CMP #$10
  BCS direction_set
  ; if BCS not taken, we are less than $10
  LDA #$01
  STA horizontal_player_dir   ; start moving right
direction_set:
  ; now, actually update player_x
  LDA horizontal_player_dir
  CMP #$01
  BEQ move_right
  ; if player_dir minus $01 is not zero,
  ; that means player_dir was $00 and
  ; we need to move left
  DEC horizontal_player_x
  JMP exit_subroutine
move_right:
  INC horizontal_player_x
exit_subroutine:
  ; all done, clean up and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc draw_player_horizontal
  	; save registers
	PHP
	PHA
	TXA
	PHA
  TYA
  PHA
  
  
	LDA horizontal_player_dir
	CMP #$01
	BEQ rightFrame

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
	LDA horizontal_player_y
	STA $0200
	LDA horizontal_player_x
	STA $0203

	; top right tile (x + 8):
	LDA horizontal_player_y
	STA $0204
	LDA horizontal_player_x
	CLC
	ADC #$08
	STA $0207

	; bottom left tile (y + 8):
	LDA horizontal_player_y
	CLC				; Clearing carry flag preparing for addition. ->
	ADC #$08		; For now we will use this until we need to add something to a 16-bit number.
	STA $0208
	LDA horizontal_player_x
	STA $020b

	; bottom right tile (x + 8, y + 8)
	LDA horizontal_player_y
	CLC
	ADC #$08
	STA $020c
	LDA horizontal_player_x
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

.proc update_player_vertical
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; Corner collision detection 
  LDA vertical_player_x
  CMP #$10
  BEQ check_top_corner
  JMP continue_update

check_top_corner:
  LDA vertical_player_y
  CMP #$10
  BEQ out_of_corner
  JMP continue_update

out_of_corner: ; no effect when in top-right corner
  LDA #$01      ; Forcing direction right to escape corner 
  STA vertical_player_dir
  JMP continue_update

continue_update:
; Movement in the y direction
  LDA vertical_player_y
  CMP #$d0
  BCC check_middle
  ; if BCC is not taken, we are greater than $d0
  LDA #$03
  STA vertical_player_dir    ; start moving up
  JMP direction_set

check_middle:
  CMP #$10
  BCS direction_set
  ; if BCS not taken, we are less than $10
  LDA #$02
  STA vertical_player_dir   ; start moving down

direction_set:
  ; now, actually update vertical_player_y
  LDA vertical_player_dir
  CMP #$02      ; Moving down
  BEQ move_down
  CMP #$03      ; Moving up
  BEQ move_up
  
  ; If none of the above, we don't need to move vertically
  JMP update_animation

move_down:
  INC vertical_player_y
  LDA vertical_player_y
  CMP #$d0       ; Check if we are at the bottom edge
  BCC update_animation
  LDA #$03       ; If we are, set direction to up
  STA vertical_player_dir
  JMP update_animation

move_up:
  DEC vertical_player_y
  LDA vertical_player_y
  CMP #$10       ; Check if we are at the upper limit
  BCS update_animation
  LDA #$02       ; If we are, set direction to down
  STA vertical_player_dir
  JMP update_animation

update_animation:
  ; Increment animation counter
  INC animation_counter
  LDA animation_counter
  CMP #06                 ; Change this value to control animation speed
  BNE no_update           ; Skip frame update if animation counter < 6

  LDA #0                  ; Reset animation counter
  STA animation_counter
  INC frame_counter
  LDA frame_counter
  AND #%00000011          ; Kinda like andi 
  STA frame_counter

no_update:
  ; all done, clean up and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc draw_player_vertical
  	; save registers
	PHP
	PHA
	TXA
	PHA
  	TYA
  	PHA
  
  
	LDA vertical_player_dir
	CMP #$02
	BEQ downFrame
	CMP #$03
	BEQ upFrame
	JMP downFrame ; If not moving up or down, use down frame

upFrame:
    LDA frame_counter
    BEQ up_frame_1
    ; Draw up frame 2
    LDA #$2b
    STA $0221
    LDA #$2c
    STA $0225
    LDA #$3b
    STA $0229
    LDA #$3c
    STA $022d
    JMP attributes

up_frame_1:
    ; Draw up frame 1
    LDA #$27
    STA $0221
    LDA #$28
    STA $0225
    LDA #$37
    STA $0229
    LDA #$38
    STA $022d
    JMP attributes

downFrame:
    LDA frame_counter
    BEQ down_frame_1
    ; Draw down frame 2
    LDA #$0b
    STA $0221
    LDA #$0c
    STA $0225
    LDA #$1b
    STA $0229
    LDA #$1c
    STA $022d
    JMP attributes

down_frame_1:
    ; Draw down frame 1
    LDA #$07
    STA $0221
    LDA #$08
    STA $0225
    LDA #$17
    STA $0229
    LDA #$18
    STA $022d
    JMP attributes
	
attributes:
	; Player attributes 
	LDA #$00
	STA $0222
	STA $0226
	STA $022a
	STA $022e

	STA $0224
	STA $0228
	STA $022c
	STA $0230

	; store tile locations
	; top left tile:
	LDA vertical_player_y
	STA $0220
	LDA vertical_player_x
	STA $0223

	; top right tile (x + 8):
	LDA vertical_player_y
	STA $0224
	LDA vertical_player_x
	CLC
	ADC #$08
	STA $0227

	; bottom left tile (y + 8):
	LDA vertical_player_y
	CLC
	ADC #$08
	STA $0228
	LDA vertical_player_x
	STA $022b

	; bottom right tile (x + 8, y + 8)
	LDA vertical_player_y
	CLC
	ADC #$08
	STA $022c
	LDA vertical_player_x
	CLC
	ADC #$08
	STA $022f

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
palettes:
.byte $0f, $12, $23, $27
.byte $0f, $2b, $3c, $39
.byte $0f, $0c, $07, $13
.byte $0f, $19, $09, $29

.byte $0f, $26, $21, $30 ; 4 .bytes here are color for sprite
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29

.segment "CHR"
; .incbin "starfield.chr"
.incbin "bomberman_v2.chr"
