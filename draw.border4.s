
GBASL       = $26   ; 16-bit pointer to start of D/HGR scanline
GBASH       = $27

GBAS2       = $28   ; pointer to opposite DHGR page

HGR_PAGE    = $E2

;zKey        = $F0   ; cached key press
zTimer      = $F0

zDstX       = $EE   ; Sprite Dest X
zSaveY      = $EF
zSpriteX    = $F0
zSpriteY    = $F1
zSpriteW    = $F2   ; end col
zSpriteH    = $F3   ; rows remaining
zSpritePtr  = $F4 ; SPRITE: 16-bit poiter

zPix        = $F6 ; BYTE: Color to write
zColors     = $F7 ; FLAG: Pixels1 or Pixels2
zTempRow    = $F8
zRowPix2    = $F9 ; Orange row offset from Magenta
zFullCol    = $FA

zCol1       = $FB ; left->middle
zCol2       = $FC ; right->middle
zRow1       = $FD ; middle->top
zRow2       = $FE ; middle->bot
zIntroState = $FF

KEY         = $C000
KEYSTROBE   = $C010

SW_STORE80  = $C000 ; Off allow SW_AUXRDOFF/etc
SW_STORE81  = $C001 ; $C055 = page 2

RDMAINRAM   = $C002 ; 2=OFF, 3=ON
WRMAINRAM   = $C004

SW_AUXRDOFF = $C002 ; $+0 = Read  Main $0200..$BFFF, $+1 = Read  Aux $0200..$BFFF
SW_AUXRDON  = $C003
SW_AUXWROFF = $C004 ; $+0 = Write Main $0200..$BFFF, $+1 = Write Aux $0200..$BFFF
SW_AUXWRON  = $C005

SET40COL    = $C00C
SET80COL    = $C00D

CLRALTCHAR  = $C00E

RDVBL       = $C019

AUXMOVE     = $C311 ; Main<->Aux
MOVE        = $FE2C ; Main<->Main

GR          = $C050
FULL        = $C052
MIXED       = $C053
SW_PAGE1    = $C054
SW_PAGE2    = $C055
HGR         = $C057
DHGR        = $C05E


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

;       ORG $800 ; end = $33FE
        ORG $6000

Main
        STA SW_STORE80  ; Allow to access AUX via WRMAINRAM

        STA SW_AUXWRON  ; AUX
        JSR ZeroHGR12   ; $2000..$5FFF

        STA SW_AUXWROFF ; MAIN
        JSR ZeroHGR12   ; $2000..$5FFF

        STA HGR         ; $C057
        STA GR          ; $C050
        STA DHGR        ; $C05E
        STA FULL        ; $C052
        STA SET80COL    ; $C00D

        LDY #192/2-1
        STY zRow1
        INY
        STY zRow2

; 560 px 1-bit color
; 140 px 4-bit color

; Draw Columns -- from middle to out both ends
; ==========
State1

; Scanline Row 1
        LDY zRow1
        CPY #$03
        BEQ State2
        JSR GetHgrY

; Columns
;   A B     CD F    = Column
;   M M     MX X    = Main/Aux
; Mag Org  Org Mag  = Magenta/Orange

; Border Outside
        LDY #0              ; Col A
        LDA #$11            ; pixel: magenta
        JSR PutHgrMainPages ; Draw border on page 1 & 2

        LDY #$4E/2          ; Col F
        LDA #$22            ; pixel: magenta
        JSR PutHgrAuxPages  ; Draw border on page 1 & 2

; Border Inside
        LDY zRow1
        CPY #$9
        BCC Scan2a

        LDY #1          ; Col B
        LDA #$66        ; pixel: orange
        JSR PutHgrMainPages ; Draw border on page 1 & 2

        LDY #$4B/2      ; Col C
        LDA #$60        ; pixel: orange
        JSR PutHgrMainPages ; Draw border on page 1 & 2

        INY             ; Col D
        LDA #$0C        ; pixel: orange
        JSR PutHgrAuxPages  ; Draw border on page 1 & 2

; Scanline Row 2
Scan2a
        LDY zRow2
        JSR GetHgrY

; Border Outside
        LDY #0              ; Col A
        LDA #$11            ; pixel: magenta
        JSR PutHgrMainPages ; Draw border on page 1 & 2

        LDY #$4E/2          ; Col F
        LDA #$22            ; pixel: magenta
        JSR PutHgrAuxPages  ; Draw border on page 1 & 2

; Border Inside
        LDY zRow2
        CPY #$B7
        BCS Scan3a

        LDY #1              ; Col B
        LDA #$66            ; pixel: orange
        JSR PutHgrMainPages ; Draw border on page 1 & 2


        LDY #$4B/2          ; Col C
        LDA #$60            ; pixel: orange
        JSR PutHgrMainPages ; Draw border on page 1 & 2

        INY                 ; Col D
        LDA #$0C            ; pixel: orange
        JSR PutHgrAuxPages  ; Draw border on page 1 & 2

Scan3a
        DEC zRow1
        INC zRow2

NoDelay
        JSR Delay

        CLC
        BCC State1      ; always

; Draw Rows - from outside in to middle
; ==========
State2

        ; Sync up outside/inside borders to same column
        LDX #2          ; Column
        STX zCol1
        INC zRow1

        DEC zRow2
        DEC zRow2
        DEC zRow2

        LDX #$4D
        STX zCol2
        BNE DrawTopBotOuterLines

DrawTopBotInnerLines

        CLC
        LDA zRow1
        ADC #5
        STA zRowPix2

        SEC             ; Orange
        TAY
        LDX zCol1
        JSR Draw3Lines

        LDY zRowPix2
        LDX zCol2
        CPX #$4C        ; HACK: Skip end orange byte
        BEQ DrawTopBotOuterLines
        SEC             ; Orange
        JSR Draw3Lines

        SEC
        LDA zRow2
        SBC #5
        STA zRowPix2

        SEC             ; Orange
        TAY
        LDX zCol1
        JSR Draw3Lines

        SEC             ; Orange
        LDY zRowPix2
        LDX zCol2
        JSR Draw3Lines

DrawTopBotOuterLines
        CLC         ; Magenta
        LDY zRow1
        LDX zCol1
        JSR Draw3Lines

        CLC         ; Magenta
        LDY zRow1
        LDX zCol2
        JSR Draw3Lines

        CLC         ; Magenta
        LDY zRow2
        LDX zCol1
        JSR Draw3Lines

        CLC         ; Magenta
        LDY zRow2
        LDX zCol2
        JSR Draw3Lines

        INC zCol1
        DEC zCol2

        JSR Delay

        LDA zCol1
        CMP #$28
        BNE DrawTopBotInnerLines


; Draw Title
; ==========
State3
        LDA #$20            ; JSR $abs - delay after drawing every scanline
        STA SpriteDelay

        LDX #>SpriteTitle
        LDY #<SpriteTitle
        JSR DrawSprite      ; draw on page 1

        LDA #$2C            ; bit $abs - no delay drawing
        STA SpriteDelay

        LDA #$40
        STA HGR_PAGE
        LDX #>SpriteTitle
        LDY #<SpriteTitle
        JSR DrawSprite      ; draw on page 2

; Animate blood
; ==========
State4

;        LDX #>blood1a
;        LDY #<blood1a
;        JSR DrawSprite
;
;        LDX #>blood1d
;        LDY #<blood1d
;        JSR DrawSprite
;
;        LDX #>blood1b
;        LDY #<blood1b
;        JSR DrawSprite
;
        LDX #>SpriteLogo
        LDY #<SpriteLogo
        JSR DrawSprite     ; draw on page 2

        LDA #$20
        STA HGR_PAGE
        LDX #>SpriteLogo
        LDY #<SpriteLogo
        JSR DrawSprite     ; draw on page 1


;

;        LDX #>
;        LDY #<


; TODO - Draw Frame 1 Page 1
; TODO - Draw Frame 2 Page 2

State5
        LDA #0
        STA zTimer+0
        STA zTimer+1

State6
; Page 2 - Frame 2
        JSR Delay
        JSR frame2delta
        STA SW_PAGE2
        LDX KEY
        BMI Loop

; Page 1 - Frame 3
        JSR Delay
        JSR frame3delta
        STA SW_PAGE1
        LDX KEY
        BMI Loop

; Page 2 - Frame 4
        JSR Delay
        JSR frame4delta
        STA SW_PAGE1
        LDX KEY
        BMI Loop

; Page 1 - Frame 1
        JSR Delay
        JSR frame1delta
        STA SW_PAGE2
        LDX KEY
        BMI Loop

        INC zTimer+0
        BNE SkipTimer2
        INC zTimer+1
        LDA zTimer+1
        CMP #$20
        BEQ SkipAnim
SkipTimer2
        BNE State6

; ==========
SkipAnim
        STA WRMAINRAM
Loop
        LDA KEY
        BPL Loop
        STA KEYSTROBE

        STA DHGR+1      ; $C05F off
        STA SET40COL    ; $C00C
        STA GR+1        ; $C051 TEXT
        STA SW_PAGE1
        RTS

; ------------------------------------------------------------------------
; Utility
; ------------------------------------------------------------------------
ZeroHGR12
        LDA #$20
        STA HGR_PAGE
        STA GBASH
        LDY #0
        TYA
        STY GBASL
ZeroPage
        STA (GBASL),Y
        INY
        BNE ZeroPage
        INC GBASH
        LDX GBASH
        CPX #$60
        BNE ZeroPage
        RTS


; ==========
Delay
        LDX #13
DelayCustom
        LDX KEY
        BMI _Delay2

_Delay
        JSR DelayVSync
        JSR DelayDraw
        DEX
        BNE _Delay
        JSR DelayVSync
        RTS

DelayVSync
        LDA RDVBL
        BMI DelayVSync
        RTS
DelayDraw
        LDA RDVBL
        BPL DelayVSync
_Delay2
        RTS


; A = 0/1 which colors: magenta/orange
; X = Column
; Y = Row
; ==========
Draw3Lines
        LDA #0
        ROR
        STA zColors     ; 0=Magenta, 1=Orange
        STY zTempRow
        STX zFullCol
        JSR NextLine
        JSR NextLine
;       --- fall into
NextLine
        LDX zFullCol
        LDY zTempRow
        JSR GetHgrY
        TXA
        AND #3
        TAX
        LDA zColors
        BNE AltColor
        LDA Pixels1,X
        BNE PutColor
AltColor
        LDA Pixels2,X
PutColor
        LDY zFullCol
        JSR PutHgrCol       ; Draw border on page 1
        JSR PutHgrColPageX  ; Draw border on page 2
        INC zTempRow
        RTS

; A=Byte
; Y=Column
; ==========
PutHgrCol
        TAX     ; push color
        TYA     ; a = col/2
        LSR
        TAY
        TXA     ; pop color
        BCS PutHgrMain
PutHgrAux
        STA WRMAINRAM+1
        STA (GBASL),Y
        CLC
        RTS
PutHgrMain
        STA WRMAINRAM
        STA (GBASL),Y
        SEC
        RTS

; Poke byte Pages 1 & 2, Main Memory
PutHgrMainPages
        STA WRMAINRAM
        STA (GBASL),Y
        STA (GBAS2),Y
        RTS

; Poke byte Pages 1 & 2, Aux Memory
PutHgrAuxPages
        STA WRMAINRAM+1
        STA (GBASL),Y
        STA (GBAS2),Y
        CLC
        RTS

; PutHgrCol but on opposite page
PutHgrColPageX
        BCS _PutMainPageX
_PutAuxPageX
        STA (GBAS2),Y
        RTS
_PutMainPageX
        STA (GBAS2),Y
        RTS

; Y = Row
; X = Col (0-40 = $00..$27)
; ==========
GetHgrYHalfX
        JSR GetHgrY
        TXA
        LSR
        CLC
        ADC GBASL
        STA GBASL
        RTS

; Y = Row
; ==========
; IN:
;  A=Y
;  HGR_PAGE = $20 or $40
; OUT:
;  $26,27 = HGR1 addr
;  $28,29 = HGR2 addr
GetHgrY
        LDA HgrYHi,Y
        CLC
        ADC HGR_PAGE
        STA GBASH
; 0010_xxxx Page 1 = $20
; 0100_xxxx Page 2 = $40
        EOR #$60
        STA GBAS2+1

        LDA HgrYLo,Y
        STA GBASL
        STA GBAS2+0
        RTS

;========================================================================

; --- Draw Sprite ---
;   X=lo 16-bit address
;   Y=hi 16-bit address
DrawSprite
        STA SW_AUXWROFF     ; Write MAIN
        STX _SpritePtr+2    ; *** SELF-MODIFES vvv
        STY _SpritePtr+1    ; *** SELF-MODIFES vvv

        JSR GetSpriteData   ; DstX
        STX zDstX  

        JSR GetSpriteData   ; DstY
        STX zSpriteY

        JSR GetSpriteData   ; SrcW
        TXA
        CLC
        ADC zDstX
        STA zSpriteW        ; end col

        JSR GetSpriteData   ; SrcH
        STX zSpriteH

LoadRows
        LDY zSpriteY        ; Y -> Dest Address
        JSR GetHgrY         ; Update GBAS

        LDA zDstX
        STA zSpriteX

        TAY                 ; save x-col

        CLC
        ROR
        CLC                 ; EASTER EGG: uncomment for wrong colors
        ADC GBASL
        STA GBASL
        STA GBAS2+0
LoadCols
;        JSR GetSpriteData   ; "push" byte
;
;        LDA zSpriteX
;        CLC
;        ROR                 ; C=is odd column
;        TAY                 ; Y=column
;
;        TXA                 ; "pop" byte
;        BCS _set_main
;        STA SW_AUXWROFF+1   ; Write AUX (even)
;_set_main
;        STA (GBASL),Y       ; Write to AUX or MAIN
;        STA SW_AUXWROFF     ; Write MAIN (odd)
;
;        INC zSpriteX
;        LDA zSpriteX
;        CMP zSpriteW
;        BNE LoadCols

        JSR GetSpriteData   ; EASTER EGG: place after "SW_AUXWROFF+1 OddCol" for psychodelic zoom

        TYA                 ; restore x-col
        CLC
        ROR
        BCS OddCol
        STA SW_AUXWROFF+1   ; Write AUX (even)
OddCol
        TXA
        STA (GBASL)         ; *** 65C02 *** Write to AUX or MAIN
        STA SW_AUXWROFF     ; Write MAIN (odd)

        BCC MemSameColumn
        INC GBASL
MemSameColumn

        INY
        CPY zSpriteW
        BNE LoadCols

SpriteDelay
        JSR Delay           ; *** SELF-MODIFIED via caller!

        INC zSpriteY
        DEC zSpriteH
        LDA zSpriteH
        BNE LoadRows
        RTS

; --- Sprite ---
; OUT: X=Byte
GetSpriteData
_SpritePtr
        LDX $C0DE            ; *** SELF-MODIFIED ^^^
IncSpriteData
        INC _SpritePtr+1
        BNE SamePage
        INC _SpritePtr+2
SamePage
        RTS

;========================================================================

; X = hi addr
; Y = lo addr
UnpackDelta
        STA SW_AUXWROFF     ; Write MAIN
        STX _DeltaSrc+2    ; *** SELF-MODIFES vvv
        STY _DeltaSrc+1    ; *** SELF-MODIFES vvv

; -----
; 1st pass = WR AUX
; 2nd pass = WR MAIN

; #num, #page
_DeltaSrc
         LDA $C0DE
;        BEQ DeltaDone
;        INC _DeltaSrc
;
;        BMI
;; 
;        STA SW_AUXWROFF     ; Write MAIN
;
;        TAX
;
;        STA _DeltaDst
_DeltaDst
        STA $C0DE
;        DEY
;
_DeltaDone
        RTS


;========================================================================
HgrYLo
            ;    0   1   2   3   4   5   6   7  Hex Dec
            db $00,$00,$00,$00,$00,$00,$00,$00 ; 00   0
            db $80,$80,$80,$80,$80,$80,$80,$80 ; 08   8
            db $00,$00,$00,$00,$00,$00,$00,$00 ; 10  16
            db $80,$80,$80,$80,$80,$80,$80,$80 ; 18  24
            db $00,$00,$00,$00,$00,$00,$00,$00 ; 20  32
            db $80,$80,$80,$80,$80,$80,$80,$80 ; 28  40
            db $00,$00,$00,$00,$00,$00,$00,$00 ; 30  48
            db $80,$80,$80,$80,$80,$80,$80,$80 ; 38  56
draw.border4_Output.txt
            db $28,$28,$28,$28,$28,$28,$28,$28 ; 40  64
            db $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8 ; 48  72
            db $28,$28,$28,$28,$28,$28,$28,$28 ; 50  80
            db $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8 ; 58  88
            db $28,$28,$28,$28,$28,$28,$28,$28 ; 60  96
            db $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8 ; 68 104
            db $28,$28,$28,$28,$28,$28,$28,$28 ; 70 112
            db $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8 ; 78 120

            db $50,$50,$50,$50,$50,$50,$50,$50 ; 80 128
            db $D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0 ; 88 136
            db $50,$50,$50,$50,$50,$50,$50,$50 ; 90 144
            db $D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0 ; 98 152
            db $50,$50,$50,$50,$50,$50,$50,$50 ; A0 160
            db $D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0 ; A8 168
            db $50,$50,$50,$50,$50,$50,$50,$50 ; B0 176
            db $D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0 ; B8 184

            DS \,0      ; ALIGN to PAGE to prevent 1 cycle page cross penalty
HgrYHi
            db $00,$04,$08,$0C,$10,$14,$18,$1C
            db $00,$04,$08,$0C,$10,$14,$18,$1C
            db $01,$05,$09,$0D,$11,$15,$19,$1D
            db $01,$05,$09,$0D,$11,$15,$19,$1D
            db $02,$06,$0A,$0E,$12,$16,$1A,$1E
            db $02,$06,$0A,$0E,$12,$16,$1A,$1E
            db $03,$07,$0B,$0F,$13,$17,$1B,$1F
            db $03,$07,$0B,$0F,$13,$17,$1B,$1F

            db $00,$04,$08,$0C,$10,$14,$18,$1C
            db $00,$04,$08,$0C,$10,$14,$18,$1C
            db $01,$05,$09,$0D,$11,$15,$19,$1D
            db $01,$05,$09,$0D,$11,$15,$19,$1D
            db $02,$06,$0A,$0E,$12,$16,$1A,$1E
            db $02,$06,$0A,$0E,$12,$16,$1A,$1E
            db $03,$07,$0B,$0F,$13,$17,$1B,$1F
            db $03,$07,$0B,$0F,$13,$17,$1B,$1F

            db $00,$04,$08,$0C,$10,$14,$18,$1C
            db $00,$04,$08,$0C,$10,$14,$18,$1C
            db $01,$05,$09,$0D,$11,$15,$19,$1D
            db $01,$05,$09,$0D,$11,$15,$19,$1D
            db $02,$06,$0A,$0E,$12,$16,$1A,$1E
            db $02,$06,$0A,$0E,$12,$16,$1A,$1E
            db $03,$07,$0B,$0F,$13,$17,$1B,$1F
            db $03,$07,$0B,$0F,$13,$17,$1B,$1F

;========================================================================

Pixels1 DB $08,$11,$22,$44  ; Magenta
Pixels2 DB $4C,$19,$33,$66  ; Orange

;========================================================================

RELOC = *
; DATA        ORG $6000

SpriteTitle PUTBIN title.sprite
SpriteLogo  PUTBIN logo.sprite

blood1a     PUTBIN blood1a.sprite
blood1b     PUTBIN blood1b.sprite
blood1d     PUTBIN blood1d.sprite

frame1delta use frame_delta/frame1.s
frame2delta use frame_delta/frame2.s
frame3delta use frame_delta/frame3.s
frame4delta use frame_delta/frame4.s

DATA_END    = *
