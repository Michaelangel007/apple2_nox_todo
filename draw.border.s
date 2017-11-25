
GBASL       = $26   ; 16-bit pointer to start of D/HGR scanline
GBASH       = $27

HGR_PAGE    = $E2

zKey        = $F0

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
HGR         = $C057
DHGR        = $C05E


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        ORG $800

Main
        STA SW_STORE80  ; Allow to access AUX via WRMAINRAM

        STA SW_AUXWRON
        JSR ZeroHGR12
        STA SW_AUXWROFF
        JSR ZeroHGR12

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
        LDY #0          ; Col A
        LDA #$11        ; pixel: magenta
        JSR PutHgrMain
        LDY #$4E/2      ; Col F
        LDA #$22        ; pixel: magenta
        JSR PutHgrAux

; Border Inside
        LDY zRow1
        CPY #$9
        BCC Scan2a

        LDY #1          ; Col B
        LDA #$66        ; pixel: orange
        JSR PutHgrMain
        LDY #$4B/2      ; Col C
        LDA #$60        ; pixel: orange
        JSR PutHgrMain
        INY             ; Col D
        LDA #$0C        ; pixel: orange
        JSR PutHgrAux

; Scanline Row 2
Scan2a
        LDY zRow2
        JSR GetHgrY

; Border Outside
        LDY #0          ; Col A
        LDA #$11        ; pixel: magenta
        JSR PutHgrMain
        LDY #$4E/2      ; Col F
        LDA #$22        ; pixel: magenta
        JSR PutHgrAux

; Border Inside
        LDY zRow2
        CPY #$B7
        BCS Scan3a

        LDY #1          ; Col B
        LDA #$66        ; pixel: orange
        JSR PutHgrMain

        LDY #$4B/2      ; Col C
        LDA #$60        ; pixel: orange
        JSR PutHgrMain
        INY             ; Col D
        LDA #$0C        ; pixel: orange
        JSR PutHgrAux

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

; ==========
SkipAnim

        STA WRMAINRAM
Loop
        LDA KEY
        BPL Loop
        STA KEYSTROBE

        STA DHGR+1      ; $C05F
        STA SET40COL    ; $C00C
        STA GR+1        ; $C051 TEXT
        RTS

ZeroHGR12
        LDA #$20
        STA HGR_PAGE
        STA GBASH
        LDY #0
        TYA
        STA zKey
;       JSR HaveKey
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
        LDX KEY
        BMI _Delay2

        LDX #13
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
        JSR PutHgrCol
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
        RTS
PutHgrMain
        STA WRMAINRAM
        STA (GBASL),Y
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
GetHgrY
        LDA HgrYHi,Y
        CLC
        ADC HGR_PAGE
        STA GBASH
        LDA HgrYLo,Y
        STA GBASL
        RTS

Pixels1 DB $08,$11,$22,$44  ; Magenta
Pixels2 DB $4C,$19,$33,$66  ; Orange

; ==========
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


