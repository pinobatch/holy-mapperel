;
; Beep code output for Holy Mapperel
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

.proc beepcode_byte
  pha
  lsr a
  lsr a
  lsr a
  lsr a
  jsr beepcode_nibble
  pla
  and #$0F
.endproc
.proc beepcode_nibble
  asl a
  tax
  lda #$02 << 1
  cpx #8*2
  ror a
  sta $4000
  lda #$08
  sta $4001
  lda pitches,x
  sta $4002
  lda pitches+1,x
  sta $4003
  ldy #12
  jmp wait_y_frames
.pushseg
.segment "RODATA"
pitches:
  .word $13BF,$1356,$12F9,$12CE,$127F,$123A,$11FB,$11DF
  .word $11AB,$117C,$1152,$113F,$111C,$10FD,$10E2,$10D2
.popseg
.endproc

.proc beepcode_tweet
  ldx #2
loop:
  ldy #$BC
  sty $4000
  ldy #$08
  sty $4001
  ldy pitches,x
  sty $4002
  ldy #$00
  sty $4003
  ldy #2
  jsr wait_y_frames
  dex
  bpl loop
  ldy #$B0
  sty $4000
  rts
.pushseg
.segment "RODATA"
pitches:
  .byte $2F,$3F,$5F
.popseg
.endproc

.proc beepcode_ding
  ldy #$83
  bne beepcode_noisey
.endproc
.proc beepcode_null
  ldy #$89
.endproc
.proc beepcode_noisey
  lda #$05
  sta $400C
  sty $400E
  lda #$20
  sta $400F
  ldy #24
  jmp wait_y_frames
.endproc
