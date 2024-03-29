.import mainprep, map_mode
.export RESET
.include "snes.inc"

; Mask off low byte to allow use of $000000-$00000F as local variables
ZEROPAGE_BASE   = $000000 & $FF00

; Make sure these conform to the linker script (e.g. lorom256.cfg).
STACK_BASE      = $0100
STACK_SIZE      = $0100
LAST_STACK_ADDR = STACK_BASE + STACK_SIZE - 1

PPU_BASE        = $2100
CPUIO_BASE      = $4200

.segment "BANK0"

.proc RESET
  sei                ; turn off IRQs
  clc
  xce                ; turn off 6502 emulation mode
  cld                ; turn off decimal ADC/SBC
  jmp reset_fastrom  ; Bank $00 is not fast, but its mirror $80 is
.endproc

.proc reset_fastrom
  setaxy16             
  ldx #LAST_STACK_ADDR
  txs                   ; set the stack pointer

  lda #CPUIO_BASE       ; Initialize the CPU I/O registers to predictable values
  tad                   ; temporarily move direct page to S-CPU I/O area
  lda #$FF00
  sta $00
  stz $02
  stz $04
  stz $06
  stz $08
  stz $0A
  stz $0C

  ; Initialize the PPU registers to predictable values
  lda #PPU_BASE
  tad                   ; temporarily move direct page to PPU I/O area

  ; first clear the regs that take a 16-bit write
  lda #$0080
  sta $00               ; Enable forced blank
  stz $02
  stz $05
  stz $07
  stz $09
  stz $0B
  stz $16
  stz $24
  stz $26
  stz $28
  stz $2A
  stz $2C
  stz $2E
  ldx #$0030
  stx $30               ; Disable color math
  ldy #$00E0
  sty $32               ; Clear red, green, and blue components of COLDATA

  ; now clear the regs that need 8-bit writes
  sep #$20
  sta $15               ; still $80: Inc VRAM pointer after high byte write
  stz $1A
  stz $21
  stz $23
  STZ $4016

  ; The scroll registers $210D-$2114 need double 8-bit writes
  .repeat 8, I
    stz $0D+I
    stz $0D+I
  .endrepeat

  ; As do the mode 7 registers, which we set to the identity matrix
  ; [ $0100  $0000 ]
  ; [ $0000  $0100 ]
  lda #$01
  stz $1B
  sta $1B
  stz $1C
  stz $1C
  stz $1D
  stz $1D
  stz $1E
  sta $1E
  stz $1F
  stz $1F
  stz $20
  stz $20

  ; Set fast ROM if the internal header so requests
  lda map_mode
  and #$10
  beq not_fastrom
  lda #$01
  sta MEMSEL
not_fastrom:

  rep #$20
  lda #ZEROPAGE_BASE
  tad                 ; return direct page to real zero page

  ; Unlike on the NES, we don't have to wait 2 vblanks to do
  ; any of the following remaining tasks.
  ; * Fill or clear areas of VRAM that will be used
  ; * Clear areas of WRAM that will be used
  ; * Load palette data into CGRAM
  ; * Fill shadow OAM and then copy it to OAM
  ; * Boot the S-SMP
  ; The main routine can do these in any order.

  jml mainprep
.endproc


