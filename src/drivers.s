;
; Discrete mapper drivers for Holy Mapperel
;
; Copyright 2013-2017 Damian Yerrick
; 
; This software is provided 'as-is', without any express or implied
; warranty.  In no event will the authors be held liable for any damages
; arising from the use of this software.
; 
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
; 
; 1. The origin of this software must not be misrepresented; you must not
;    claim that you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation would be
;    appreciated but is not required.
; 2. Altered source versions must be plainly marked as such, and must not be
;    misrepresented as being the original software.
; 3. This notice may not be removed or altered from any source distribution.
;
.include "nes.inc"
.include "global.inc"

.macro rtslast
.local retff_fail
  lda IS_LAST_BANK
  beq retff_fail
  rts
retff_fail:
  lda #VBLANK_NMI
  sta PPUCTRL
  lda #MORSE_R
  jsr morsebeep
  lda #MORSE_B
  jsr morsebeep
  ldy #TWOCELLS * 2
  jsr wait_y_frames
  jmp retff_fail
.endmacro

.segment "ZEROPAGE"
driver_prg_result: .res 1
driver_chr_result: .res 1

; Reserved for Paul's flash mfr ID code
prg_flash_mfrid: .res 1
prg_flash_devid: .res 1
prg_flash_width: .res 1
prg_flash_size: .res 1
chr_flash_mfrid: .res 1
chr_flash_devid: .res 1
chr_flash_width: .res 1
chr_flash_size: .res 1

; NROM/CNROM/GNROM ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; $8000-$FFFF, bits 7-4 (with bus conflicts): 32K PRG ROM
; $8000-$FFFF, bits 3-0 (with bus conflicts): 8K CHR ROM

.segment "DRIVER_GNROM"
  rts  ; CNROM and GNROM don't support PRG RAM
  nop  ; Family BASIC does
  nop
  jmp gnrom_set_chr_8k
.proc gnrom_test_mapper
addrlo = 0
addrhi = 1
cur_banktag = 2
  ; Read all PRG ROM bank tags through each PRG ROM window
  lda #<CUR_BANK
  sta addrlo
  lda CUR_BANK
  sta cur_banktag
loop:
  lda #$FF
  sta CONSTANT_FF
  lda cur_banktag
  asl a
  and #$F0
  tay
  sta identity,y
  lda cur_banktag
  asl a
  asl a
  asl a
  asl a
  ora #$8F & >CUR_BANK
  sta addrhi
  ldy #0
  lda (addrlo),y
  cmp cur_banktag
  bne prg_failure
  dec cur_banktag
  bpl loop

  ; No PRG RAM protection, non-8K CHR banking, or IRQ tests
  lda #0
  beq have_prg_result
prg_failure:
  lda #MAPTEST_PRGWIN1
have_prg_result:
  sta driver_prg_result

  lda #$00
  sta driver_chr_result
  ; No PRG RAM protection, alternate CHR windows, or IRQ tests
  lda #$FF
  sta CONSTANT_FF
  rtslast
.endproc
.proc gnrom_set_chr_8k
  ora #$F0
  tay
  sta identity,y
  rts
.endproc

; BNROM/AOROM/Color Dreams ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; $8000-$FFFF, bits 3-0 (with bus conflicts): 32K PRG ROM
; $8000-$FFFF, bits 7-4 (with bus conflicts): 8K CHR ROM

.segment "DRIVER_BNROM"
  rts  ; BNROM doesn't support PRG RAM
  nop
  nop
  jmp colordreams_set_chr_8k
.proc bnrom_test_mapper
addrlo = 0
addrhi = 1
cur_banktag = 2
  ; Read all PRG ROM bank tags through each PRG ROM window
  lda #<CUR_BANK
  sta addrlo
  lda CUR_BANK
  sta cur_banktag
loop:
  lda #$FF
  sta CONSTANT_FF
  lda cur_banktag
  lsr a
  lsr a
  lsr a
  tay
  sta identity,y
  lda cur_banktag
  asl a
  asl a
  asl a
  asl a
  ora #$8F & >CUR_BANK
  sta addrhi
  ldy #0
  lda (addrlo),y
  cmp cur_banktag
  bne prg_failure
  dec cur_banktag
  bpl loop

  lda #0
  beq have_prg_result
prg_failure:
  lda #MAPTEST_PRGWIN1
have_prg_result:
  sta driver_prg_result

  ; No PRG RAM protection, non-8K CHR banking, or IRQ tests
  ldy #0
  sty driver_chr_result
  sty $7FFE
  iny
  sty $7FFF  ; in case it gets mixed with NINA

  lda #$FF
  sta CONSTANT_FF
  rtslast
.endproc
.proc colordreams_set_chr_8k
  asl a
  asl a
  asl a
  asl a
  ora #$0F
  tay
  sta identity,y
  rts
.endproc


; UNROM (both normal and Crazy Climber versions) and Holy Diver ;;;;;

.segment "DRIVER_UNROM"
  rts  ; UNROM doesn't support PRG RAM
  nop
  nop
  jmp holydiver_set_chr_8k
.proc unrom_test_mapper
  ; Read all PRG ROM bank tags through PRG ROM window $8000
addrlo = 0
addrhi = 1
cur_banktag = 2
addrhi_base = 3
  lda #$8F & >CUR_BANK
  bit cur_mapper
  bpl not_crazy1
  lda #$CF & >CUR_BANK
not_crazy1:
  sta addrhi_base

  ; Read all PRG ROM bank tags through each PRG ROM window
  lda #<CUR_BANK
  sta addrlo
  lda CUR_BANK
  sta cur_banktag
loop:
  lda #$FF
  sta CONSTANT_FF
  lda cur_banktag
  lsr a
  lsr a
  tay
  sta identity,y
  lda cur_banktag
  and #$03
  asl a
  asl a
  asl a
  asl a
  ora addrhi_base
  sta addrhi
  ldy #0
  lda (addrlo),y
  cmp cur_banktag
  bne prg_failure
  dec cur_banktag
  bpl loop

  lda #0
  beq have_prg_result
prg_failure:
  lda #MAPTEST_PRGWIN1
have_prg_result:
  sta driver_prg_result

  ; No PRG RAM protection, CHR banking, or IRQ tests
  ldy #0
  sty driver_chr_result
  sty CONSTANT_00
  bit cur_mapper
  bpl not_crazy2
  ldy #$FF
  sty CONSTANT_FF
not_crazy2:
  rtslast
.endproc
.proc holydiver_set_chr_8k
  bit cur_mapper  ; Skip entirely for UNROM (Crazy Climber)
  bmi :+
  asl a
  asl a
  asl a
  asl a
  ora #$0F
  tay
  sta identity,y
:
  rts
.endproc

; Loading a driver ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.import __DRIVER_GNROM_LOAD__, __DRIVER_BNROM_LOAD__
.import __DRIVER_MMC1_LOAD__, __DRIVER_MMC3_LOAD__
.import __DRIVER_FME7_LOAD__, __DRIVER_UNROM_LOAD__
.import __DRIVER_A53_LOAD__, __DRIVER_MMC2_LOAD__

.segment "CODE"
.proc load_mapper_driver
  ldx #mapper_driver_list_end
loop:
  cmp mapper_driver_list-3,x
  beq found
  dex
  dex
  dex
  bne loop
mapper_not_found:
  lda #VBLANK_NMI
  sta PPUCTRL
  lda #MORSE_D
  jsr morsebeep
  lda #MORSE_R
  jsr morsebeep
  lda #MORSE_V
  jsr morsebeep
  ldy #TWOCELLS*2
  jsr wait_y_frames
  jmp mapper_not_found
found:
  lda mapper_driver_list-2,x
  sta 0
  lda mapper_driver_list-1,x
  sta 1
  ldy #0
  sty 2
  lda #$04
  sta 3
  ldx #<-3  ; 768 byte limit on mapper driver size
copyloop:
  lda (0),y
  sta (2),y
  iny
  bne copyloop
  inc 1
  inc 3
  inx
  bne copyloop
  rts
.endproc

.segment "RODATA"
mapper_driver_list:
  .byte MAPPER_NROM
  .addr __DRIVER_GNROM_LOAD__
  .byte MAPPER_CNROM
  .addr __DRIVER_GNROM_LOAD__
  .byte MAPPER_GNROM
  .addr __DRIVER_GNROM_LOAD__
  .byte MAPPER_BNROM
  .addr __DRIVER_BNROM_LOAD__
  .byte MAPPER_AOROM
  .addr __DRIVER_BNROM_LOAD__
  .byte MAPPER_COLORDREAMS
  .addr __DRIVER_BNROM_LOAD__
  .byte MAPPER_MMC1
  .addr __DRIVER_MMC1_LOAD__
  .byte MAPPER_MMC3
  .addr __DRIVER_MMC3_LOAD__
  .byte MAPPER_MMC3_TLSROM
  .addr __DRIVER_MMC3_LOAD__
  .byte MAPPER_FME7
  .addr __DRIVER_FME7_LOAD__
  .byte MAPPER_HOLYDIVER
  .addr __DRIVER_UNROM_LOAD__
  .byte MAPPER_UNROM
  .addr __DRIVER_UNROM_LOAD__
  .byte MAPPER_UNROM_CRAZY
  .addr __DRIVER_UNROM_LOAD__
  .byte MAPPER_A53
  .addr __DRIVER_A53_LOAD__
  .byte MAPPER_MMC2
  .addr __DRIVER_MMC2_LOAD__
  .byte MAPPER_MMC4
  .addr __DRIVER_MMC2_LOAD__

mapper_driver_list_end = * - mapper_driver_list
