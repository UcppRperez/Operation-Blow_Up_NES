.include "constants.inc"
.include "header.inc"

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
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
load_sprites:
  LDA sprites,X
  STA $0200,X
  INX
  CPX #$c0 ; Add more tiles sprites
  BNE load_sprites

	; write nametables
	; Drawing background tiles
	; 1 2288
	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$88
	STA PPUADDR
	LDX #$30
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$89
	STA PPUADDR
	LDX #$31
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$a8
	STA PPUADDR
	LDX #$40
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$a9
	STA PPUADDR
	LDX #$41
	STX PPUDATA

	; 2
	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$8a
	STA PPUADDR
	LDX #$32
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$8b
	STA PPUADDR
	LDX #$33
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$aa
	STA PPUADDR
	LDX #$42
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$ab
	STA PPUADDR
	LDX #$43
	STX PPUDATA
	
	; 3
	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$8c
	STA PPUADDR
	LDX #$34
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$8d
	STA PPUADDR
	LDX #$35
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$ac
	STA PPUADDR
	LDX #$44
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$ad
	STA PPUADDR
	LDX #$45
	STX PPUDATA	

	; 4
	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$8e
	STA PPUADDR
	LDX #$36
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$8f
	STA PPUADDR
	LDX #$37
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$ae
	STA PPUADDR
	LDX #$46
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$af
	STA PPUADDR
	LDX #$47
	STX PPUDATA	

	; 5 
	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$90
	STA PPUADDR
	LDX #$38
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$91
	STA PPUADDR
	LDX #$39
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$b0
	STA PPUADDR
	LDX #$48
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$b1
	STA PPUADDR
	LDX #$49
	STX PPUDATA	

	; 6
	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$92
	STA PPUADDR
	LDX #$3a
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$93
	STA PPUADDR
	LDX #$3b
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$b2
	STA PPUADDR
	LDX #$4a
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$b3
	STA PPUADDR
	LDX #$4b
	STX PPUDATA	

	; 7
	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$94
	STA PPUADDR
	LDX #$50
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$95
	STA PPUADDR
	LDX #$51
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$b4
	STA PPUADDR
	LDX #$60
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$b5
	STA PPUADDR
	LDX #$61
	STX PPUDATA	

	; 8
	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$96
	STA PPUADDR
	LDX #$52
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$97
	STA PPUADDR
	LDX #$53
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$b6
	STA PPUADDR
	LDX #$62
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$b7
	STA PPUADDR
	LDX #$63
	STX PPUDATA			

	; finally, attribute table
	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$c2
	STA PPUADDR
	LDA #%01000000
	STA PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$e0
	STA PPUADDR
	LDA #%00001100
	STA PPUDATA

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

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"
palettes:
.byte $0f, $26, $21, $30
.byte $0f, $2b, $3c, $39
.byte $0f, $0c, $07, $13
.byte $0f, $19, $09, $29

.byte $0f, $26, $21, $30 ; 4 .bytes here are color for sprite
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29

sprites:
; Bomberman
; Walking Left
.byte $65, $01, $00, $3c ; .byte y-coord, number tile, attribute, x-coord
.byte $65, $02, $00, $44
.byte $6d, $11, $00, $3c
.byte $6d, $12, $00, $44
; Standing Left
.byte $65, $03, $00, $48 
.byte $65, $04, $00, $50
.byte $6d, $13, $00, $48
.byte $6d, $14, $00, $50
; Running Left
.byte $65, $05, $00, $54 
.byte $65, $06, $00, $5c
.byte $6d, $15, $00, $54
.byte $6d, $16, $00, $5c
; Walking-R Down
.byte $65, $07, $00, $61 
.byte $65, $08, $00, $69
.byte $6d, $17, $00, $61
.byte $6d, $18, $00, $69
; Standing Down
.byte $76, $09, $00, $3c 
.byte $76, $0a, $00, $44
.byte $7e, $19, $00, $3c
.byte $7e, $1a, $00, $44
; Walking-L Down
.byte $76, $0b, $00, $48 
.byte $76, $0c, $00, $50
.byte $7e, $1b, $00, $48
.byte $7e, $1c, $00, $50
; Walking Right
.byte $76, $21, $00, $54 
.byte $76, $22, $00, $5c
.byte $7e, $31, $00, $54
.byte $7e, $32, $00, $5c
; Standing Right
.byte $76, $23, $00, $61 
.byte $76, $24, $00, $69
.byte $7e, $33, $00, $61
.byte $7e, $34, $00, $69
; Running Right
.byte $87, $25, $00, $3c 
.byte $87, $26, $00, $44
.byte $8f, $35, $00, $3c
.byte $8f, $36, $00, $44
; Walking-R Up
.byte $87, $27, $00, $48 
.byte $87, $28, $00, $50
.byte $8f, $37, $00, $48
.byte $8f, $38, $00, $50
; Standing Up
.byte $87, $29, $00, $54 
.byte $87, $2a, $00, $5c
.byte $8f, $39, $00, $54
.byte $8f, $3a, $00, $5c
; Walking-L Up
.byte $87, $2b, $00, $61 
.byte $87, $2c, $00, $69
.byte $8f, $3b, $00, $61
.byte $8f, $3c, $00, $69

.segment "CHR"

.incbin "bomberman_v2.chr"
