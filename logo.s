; Assembler: Merlin32
; https://brutaldeluxe.fr/products/crossdevtools/merlin/index.html
;
; DHGR Screen Difference to Compiled Sprite
; Frame Delta

CONFIG_DEBUG = 1

SpriteLogo_RELOC  = $0200 ; $F6 bytes used
SpriteTitle_RELOC = $D000

; ZP Table of Compiled Delta Frame Function Address
aFrameFunc        = $0000 ; 2 bytes/entry, odd = func resides in AUX mem

; enum DHGR Frames
; NOTE: *MUST* keep in SYNC TableDeltaAuxInit and FRAME_BLOOD_*
FRAME_BLOOD_01  = $00
FRAME_BLOOD_02  = $01
FRAME_BLOOD_13  = $02
FRAME_BLOOD_24  = $03
FRAME_BLOOD_31  = $04
FRAME_BLOOD_42  = $05
FRAME_CROWN_13  = $06
FRAME_CROWN_24  = $07
FRAME_CROWN_31  = $08
FRAME_CROWN_42  = $09
FRAME_EYES_13   = $0A
FRAME_EYES_24   = $0B
FRAME_EYES_31   = $0C
FRAME_EYES_42   = $0D
_NUM_FRAME      = $0E

; ZP variables *must* come after DrawDeltaFrame on ZP !
HGR_PAGE    = $E6
zTimer      = $E8

GBASL       = $EA   ; 16-bit pointer to start of D/HGR scanline
GBASH       = $EB
GBAS2       = $EC   ; pointer to opposite DHGR page

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

aHgrYLo     = $100 ; 16-bit pointer start scan line - low byte, only $C0 bytes used on STACK
aHgrYHi     = $300 ; 16-bit pointer start scan line - high byte

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

SETSTDZP    = $C008 ; Write, will also bank in LC if LCRAM1/2 set
SETALTZP    = $C009 ; Write, will also bank in LC if LCRAM1/2 set

SET40COL    = $C00C
SET80COL    = $C00D

CLRALTCHAR  = $C00E

RDVBL       = $C019

AUXMOVE     = $C311 ; Main<->Aux , C=0 Aux->Main, C=1 Main->Aux
MOVE        = $FE2C ; Main<->Main, *MUST* set Y=0 prior!

GR          = $C050
FULL        = $C052
MIXED       = $C053
SW_PAGE1    = $C054
SW_PAGE2    = $C055
HGR         = $C057
DHGR        = $C05E


;                   ; Read   | Write  | R Twice?
RAMIN2      = $C080 ; Bank 2 | n/a    | no
ROMIN2      = $C081 ; ROM    | Bank 2 | yes
LCBANK2     = $C083 ; Bank 2 | Bank 2 | yes

RAMIN1      = $C088 ; Bank 1 | n/a    | no
ROMIN1      = $C089 ; ROM    | Bank 1 | yes
LCBANK1     = $C08B ; Bank 1 | Bank 1 | yes

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    ; Can't start at $800 since
        ORG $0900   ; $A5 bytes needed for LZ4 unpack

Main
        JSR Init

; Intentional copy common code into ZP!
        LDX #0                     ; Copy $100 bytes
CopyCodeToZP
        LDA __code_zp_src ,X       ;
        STA __reloc_zp_dst,X       ; ZP,X does NOT roll over into STACK Page, but *wraps-around* the ZP
        INX
        BNE CopyCodeToZP

        JSR MakeHgrTables

InitLogoSprite
        LDX #>SpriteLogo            ; SrcPage
        LDY #>SpriteLogo_RELOC      ; DstPage
        LDA #>_sprite_logo_len+256  ; LenPage
        JSR MemMoveLC


; Boot sector reads ProRWTS2 into $D000-D8FF Main LC Bank1
; NOXARCH.MAIN read LOADER.P
; moves ProRWTS2 to Aux LC Bank 1.

InitTitleSprite
        LDA LCBANK2             ; $D000 BANK 2
        LDA LCBANK2
        LDX #>SpriteTitle           ; SrcPage = $5096
        LDY #>SpriteTitle_RELOC     ; DstPage = $D000
        LDA #>_sprite_title_len+256 ; LenPage = $5F54 - $5096 = $0F
        JSR MemMoveLC


; Unpack the sprites or compiled delta frames
; Parse the Table of Compiled Frames that live in AUX mem

        LDA #0
        STA $400        ; DEBUG

; === Blood ===
; === Crown ===
        LDX #>TableDeltaAuxInit
        LDY #<TableDeltaAuxInit
        JSR TableUnpack

; === Eyes ===

        LDX #>TableDeltaMainInit
        LDY #<TableDeltaMainInit
        JSR TableUnpack

        LDA RAMIN2
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
State3a
        LDA #$20            ; JSR $abs - delay after drawing every scanline
        STA SpriteDelay

;       LDA RAMIN1          ; $D000 Bank 1

        LDX #>SpriteTitle_RELOC
        LDY #<SpriteTitle_RELOC
DrawTitle1
        JSR DrawSprite      ; draw on page 1

        LDA #$2C            ; bit $abs - no delay drawing
        STA SpriteDelay

        LDA #$40
        STA HGR_PAGE
        LDX #>SpriteTitle_RELOC
        LDY #<SpriteTitle_RELOC
DrawTitle2
        JSR DrawSprite      ; draw on page 2

;       LDA RAMIN2          ; $D000 Bank 2

; Draw Logo
; ==========
State3b

        LDX #>SpriteLogo_RELOC
        LDY #<SpriteLogo_RELOC
        JSR DrawSprite     ; draw on page 2

        LDA #$20
        STA HGR_PAGE
        LDX #>SpriteLogo_RELOC
        LDY #<SpriteLogo_RELOC
        JSR DrawSprite     ; draw on page 1

; Draw Blood
; ==========
State4

; Switch to Border + Title + Logo on page 2
; While we draw frame 1 on page 1
        STA SW_PAGE2

; Draw Frame 1 Page 1
        JSR Delay

DrawBlood01
        LDA #FRAME_BLOOD_01 ; frame1delta0
        JSR DrawDeltaFrame
        STA SW_PAGE1

; Draw Frame 2 Page 2
        JSR Delay

DrawBlood02
        LDA #FRAME_BLOOD_02 ; frame2delta0
        JSR DrawDeltaFrame
        STA SW_PAGE2

; Animate blood
; ==========
        LDA #0
        STA zTimer+0

State5

; Page 1 - Frame 3
        JSR Delay

        LDA #FRAME_BLOOD_31
        JSR DrawDeltaFrame  ; blood3delta1
        STA SW_PAGE1
        JSR BloodWait
        BCS Loop

; Page 2 - Frame 4
        JSR Delay
        LDA #FRAME_BLOOD_42
        JSR DrawDeltaFrame  ; blood4delta2
        STA SW_PAGE2
        JSR BloodWait
        BCS Loop

; Page 1 - Frame 1
        JSR Delay
        LDA #FRAME_BLOOD_13
        JSR DrawDeltaFrame  ; blood1delta3
        STA SW_PAGE1
        JSR BloodWait
        BCS Loop

; Page 2 - Frame 2
        JSR Delay
        LDA #FRAME_BLOOD_24
        JSR DrawDeltaFrame  ; blood2delta4
        STA SW_PAGE2
        JSR BloodWait
        BCS Loop

;       JSR Delay
        INC zTimer+0
        LDA zTimer+0
        CMP #3
        BNE State5
        BEQ State6      ; always



; ==========
SkipAnim
        LDA ROMIN2
        LDA ROMIN2
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


; Draw crown
; ==========

State6
        LDX #>Crown1        ; @ $6000
        LDY #<Crown1
        JSR DrawSprite      ; draw on page 1
        STA SW_PAGE1

        LDA #$40
        STA HGR_PAGE
        LDX #>Crown2        ; @ $6CC4
        LDY #<Crown2
        JSR DrawSprite      ; draw on page 2

; Animate crown
; =============

        LDA #0
        STA zTimer+0

State7

; Page 1 - Frame 3
        JSR Delay
        LDA #FRAME_CROWN_31
        JSR DrawDeltaFrame  ; crown3delta1
        STA SW_PAGE1
        JSR BloodWait
        BCS Loop

; Page 2 - Frame 4
        JSR Delay
        LDA #FRAME_CROWN_42
        JSR DrawDeltaFrame  ; crown4delta2
        STA SW_PAGE2
        JSR BloodWait
        BCS Loop

; Page 1 - Frame 1
        JSR Delay
        LDA #FRAME_CROWN_13
        JSR DrawDeltaFrame  ; crown1delta3
        STA SW_PAGE1
        JSR BloodWait
        BCS Loop

; Page 2 - Frame 2
        JSR Delay
        LDA #FRAME_CROWN_24
        JSR DrawDeltaFrame  ; crown2delta4
        STA SW_PAGE2
        JSR BloodWait
        BCS Loop

;       JSR Delay
        INC zTimer+0
        LDA zTimer+0
        CMP #3
        BNE State7



; Animate eyes
; ============

        LDA #0
        STA zTimer+0

State8
; Page 1 - Frame 3
        JSR Delay
        LDA #FRAME_EYES_31
        JSR DrawDeltaFrame  ; eyes3delta1
        STA SW_PAGE1
        JSR BloodWait
        BCS HaveKey2

; Page 2 - Frame 4
        JSR Delay
        LDA #FRAME_EYES_42
        JSR DrawDeltaFrame  ; eyes4delta2
        STA SW_PAGE2
        JSR BloodWait
        BCS HaveKey2

; Page 1 - Frame 1
        JSR Delay
        LDA #FRAME_EYES_13
        JSR DrawDeltaFrame  ; eyes1delta3
        STA SW_PAGE1
        JSR BloodWait
        BCS HaveKey2

; Page 2 - Frame 2
        JSR Delay
        LDA #FRAME_EYES_24
        JSR DrawDeltaFrame  ; eyes2delta4
        STA SW_PAGE2
        JSR BloodWait
        BCS HaveKey2

        INC zTimer+0
        LDA zTimer+0
        CMP #$3F
        BNE State8

HaveKey2
        JMP SkipAnim        ; always


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
BloodWait
        LDA #$BB
        STA zTimer+1
_BloodDelay
        LDX KEY
        BMI _BloodKey
        JSR Delay
        INC zTimer+1
        LDA zTimer+1
        BNE _BloodDelay
        CLC
        RTS
_BloodKey
        SEC
        RTS

; ==========
Delay
        LDX #13
DelayCustom
        LDA KEY
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


;------------------------------------------------------------------------
; A = 0/1 which colors: magenta/orange
; X = Column
; Y = Row
;------------------------------------------------------------------------
Draw3Lines
        LDA #0
        ROR
        STA zColors     ; 0=Magenta, 1=Orange
        STY zTempRow
        STX zFullCol
        JSR NextLine
        JSR NextLine
;       --- NOTE: *intentional* fall into
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

;------------------------------------------------------------------------
; A=Byte
; Y=Column
;------------------------------------------------------------------------
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
        LDA aHgrYHi,Y
        CLC
        ADC HGR_PAGE
        STA GBASH
; 0010_xxxx Page 1 = $20
; 0100_xxxx Page 2 = $40
        EOR #$60
        STA GBAS2+1

        LDA aHgrYLo,Y
        STA GBASL
        STA GBAS2+0
        RTS


;------------------------------------------------------------------------
; Draw Sprite -- uses data for x,y
; Input:
;   X=ho 16-bit address Source Sprite Data
;   Y=lo 16-bit address Source Sprite Data
;------------------------------------------------------------------------
DrawSprite
        STA SW_AUXWROFF     ; Write MAIN
        JSR InitSpritePtr

        JSR GetSpriteData   ; DstX
        STA zDstX

        JSR GetSpriteData   ; DstY
        STA zSpriteY

        JSR GetSpriteData   ; SrcW
        CLC
        ADC zDstX
        STA zSpriteW        ; end col

        JSR GetSpriteData   ; SrcH
        STA zSpriteH

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
        JSR GetSpriteData   ; EASTER EGG: place after "SW_AUXWROFF+1 OddCol" for psychodelic zoom
        TAX                 ; push byte

        TYA                 ; restore x-col
        CLC
        ROR
        BCS OddCol
        STA SW_AUXWROFF+1   ; Write AUX (even)
OddCol
        TXA                 ; pop byte
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

;------------------------------------------------------------------------
; --- Compile Array of Delta Frames to Memory ---
;------------------------------------------------------------------------
; IN:
;   X=ho 16-bit address Table of Delta Frames to Compile
;   Y=lo 16-bit address Table of Delta Frames to Compile
; SEE:
;   TableDeltaAuxInit
;   TableDeltaMainInit
; FORMAT:
;       <destination page>
;       <$18> or <$38>  ; 6502 code; C=WriteToAuxMem?
;       <$addr>+        ; source address of packed delta frame
;       <$0000>         ; end of data
;------------------------------------------------------------------------
TableUnpack
        STX TableGetByteX+2  ; SELF-MODIFYING vvv
        STY TableGetByteX+1  ; SELF-MODIFYING vvv

        LDX #0
        JSR TableGetByteX
        TAX
        LDY #$00            ; page aligned
        JSR SetCompiledFrameDeltaAddr   ; X=Hi, Y=Lo

        JSR TableGetByte    ; Get dest addr for compiled delta framec
        STA TableAuxOrMain  ;     SELF-MODIFIED vv

TableNextFrame
        JSR TableGetByte    ;     lo source addr
        TAY                 ; Y=DeltaFrame Source Lo
        JSR TableGetByte    ;     hi source addr
        TAX                 ; X=DeltaFrame Source Hi
        BEQ TableDone       ;     hi byte == 0 --> end of data

TableAuxOrMain
        SEC                 ;     SELF-MODIFIED ^^
        LDA zSpriteNext     ; A=DeltaFrame enum
        JSR CompileDeltaFrame
        STA SW_AUXWROFF     ;

    DO CONFIG_DEBUG

        INC $400            ; DEBUG: Visually tell what frame delta we are compiling
    FIN
        INC zSpriteNext
        BNE TableNextFrame  ; always

TableGetByte
        LDX #0
TableGetByteX
        LDA $da1a,X         ; SELF-MODIFIED ^^^
        INX
        STX TableGetByte+1
TableDone
        RTS


;========================================================================
        DS \,0                  ; wastes bytes -- align $C00
;========================================================================

; Move @ -> $0200 Software Keyboard Buffer = SpriteLogo_RELOC
_sprite_logo_beg = *

SpriteLogo  PUTBIN logo.sprite

_sprite_logo_end  = *
_sprite_logo_len  = _sprite_logo_end - _sprite_logo_beg

;========================================================================
        DS \,0                  ; wastes bytes -- align $D00
;========================================================================

; Move @ -> $D000 LC Bank 2 = SpriteTitle_RELOC
_sprite_title_beg = *

SpriteTitle PUTBIN title.sprite

_sprite_title_end  = *
_sprite_title_len  = _sprite_title_end - _sprite_title_beg

;========================================================================


; Where to compile delta frames to
; Everything that fits into AUX memory
TableDeltaAuxInit
        db $60                  ; DST = $6000
        SEC                     ; AUX memory
        dw frame1delta0         ; NOTE: *MUST* keep in SYNC TableDeltaAuxInit and FRAME_BLOOD_*
        dw frame2delta0
        dw blood1delta3
        dw blood2delta4
        dw blood3delta1
        dw blood4delta2
        dw crown1delta3
        dw crown2delta4
        dw crown3delta1
        dw crown4delta2
        dw 0                    ; end-of-data

; Everything that fits into MAIN memory
TableDeltaMainInit
        db >__code_end+256      ; DST = $7B00
        CLC                     ; MAIN mem
        dw eye1delta3
        dw eye2delta4
        dw eye3delta1
        dw eye4delta2
        dw 0                    ; end-of-data

;========================================================================

Pixels1 DB $08,$11,$22,$44  ; Magenta
Pixels2 DB $4C,$19,$33,$66  ; Orange

;========================================================================

__reloc_src = *
__reloc_dst = *

; Next Frame, Prev Frame
frame1delta0 use frame01.s
frame2delta0 use frame02.s

blood1delta3 use blood13.s
blood2delta4 use blood24.s
blood3delta1 use blood31.s
blood4delta2 use blood42.s

crown1delta3 use crown13.s
crown2delta4 use crown24.s
crown3delta1 use crown31.s
crown4delta2 use crown42.s

eye1delta3   use eyes13.s
eye2delta4   use eyes24.s
eye3delta1   use eyes31.s
eye4delta2   use eyes42.s


; === Data at $6000 ===
;   DO * < $6000
;           DS \,0
;   FIN
Crown1      PUTBIN crown1.sprite
Crown2      PUTBIN crown2.sprite

__code_end  = *

;========================================================================
;=== INIT Segment ===
;========================================================================
; Following initialization code
; is over-written by compiled delta frame code

;------------------------------------------------------------------------
; Instead of wasting 2 disk sectors for the HGR Y low and high tables
; dynamically build them at run-time.
;
; Size: $53 bytes
;
; Output:
;    aHgrYLo     = $200
;    aHgrYHi     = $300
;------------------------------------------------------------------------
MakeHgrTables

MakeHgrLo
            LDX #$0             ; [00]..[3F]
            TXA                 ; src = $2000
            JSR MakeHgrLoTriad
            JSR MakeHgrLoTriad

            LDX #$40            ; [40..7F]
            LDA #$28            ; src = $2028
            JSR MakeHgrLoTriad
            JSR MakeHgrLoTriad

            LDX #$80            ; [80..BF]
            LDA #$50            ; src = $2050
            JSR MakeHgrLoTriad
            JSR MakeHgrLoTriad

MakeHgrHi                       ; A = $D0
            TYA                 ; Y = $00
            LDX #256 - 12       ; X = $90 -> X=256 - 192/16 = -12, write two rows (of 8 bytes) at once
SameRow
            STA aHgrYHi + $00,Y ; aHi[ iHi + 0 ] = val
            STA aHgrYHi + $08,Y ; aHi[ iHi + 8 ] = val
            INY                 ; iHi++

            CLC                 ; val += 4
            ADC #4
            CMP #$20
            BCC SameRow         ; loop 8 times, 16 vals written

            INY                 ; skip second row since already written to
            INY
            INY
            INY
            INY
            INY
            INY
            INY
            ADC #0              ; C=1 since val >= $20
            AND #3              ; Next Triad

            INX
            BNE SameRow
            RTS

MakeHgrLoTriad
            LDY #8              ; for( col = 0; col < 8; col++ )
_LoTriad
            STA aHgrYLo+$00,X   ; aLo[ iLo+ 0 ] = val
            STA aHgrYLo+$10,X   ; aLo[ iLo+16 ] = val
            STA aHgrYLo+$20,X   ; aLo[ iLo+32 ] = val
            STA aHgrYLo+$30,X   ; aLo[ iLo+48 ] = val
            INX                 ; iLo++
            DEY                 ; col--
            BNE _LoTriad
            ORA #$80            ; 
            RTS


;------------------------------------------------------------------------
; Can't use MOVE = $FE2C to write to LC Bank 1/2
; IN:
;   X=Src Page
;   Y=Dst Page
;   A=Len Page
;------------------------------------------------------------------------
MemMoveLC
            STX _MoveSrc+2      ; 0038: *** SELF-MODIFIES vvv     = Src Hi
            STY _MoveDst+2      ; 003A: *** SELF-MODIFIES     vvv = Dst Hi
            TAY                 ; 003C:
_MovePage   LDX #0              ; 003D:
_MoveSrc    LDA $DA00,X         ; 003F: *** SELF-MODIFIED ***
_MoveDst    STA $DA00,X         ; 0042: *** SELF-MODIFIED     ***
            INX                 ; 0045:
            BNE _MoveSrc        ; 0046:
            INC _MoveSrc+2      ; 0048: *** SELF-MODIFIES ^^^
            INC _MoveDst+2      ; 004A: *** SELF-MODIFIES     ^^^
            DEY                 ; 004C: Next Page
            BNE _MovePage       ; 004D:
            RTS                 ; 004F:


Init
            STA SW_AUXWROFF
            STA SETSTDZP

            STA GR+1        ; TEXT
            STA SW_PAGE1    ; Page 1
            STA $C00C       ; 40-col
            RTS

;========================================================================
;=== ZP Segment ===
;========================================================================

__code_zp_src   = *
__reloc_zp_dst  = _NUM_FRAME*2
            ORG __reloc_zp_dst  ; *** Code resides on ZP to minimize address field 1 bytes $ZP instead of 2 bytes $ABS

; IN:
;  A = Which Delta Frame to Draw, FRAME_*
;      SEE: CompileDeltaFrame
;------------------------------------------------------------------------
DrawDeltaFrame
            ASL
            TAX
            LDA aFrameFunc+0,X  ; low byte odd?
            LSR
            BCC _FrameMainMem1
            ORA #$80            ; yes, C=1
_FrameMainMem1
            ASL
;           BCC _FrameMainMem2
;           STA SW_AUXWRON      ; C=1
_FrameMainMem2
            STA CallFrame+1
            LDA aFrameFunc+1,X
            STA CallFrame+2
            BCC _FrameMainMem3  ; C=1, call func in AUX mem
            STA SW_AUXRDON
_FrameMainMem3
CallFrame
            JSR $c0de
            STA SW_AUXRDOFF
            RTS

;------------------------------------------------------------------------
; IN:
;   X=hi 16-bit address Source Sprite Data
;   Y=lo 16-bit address Source Sprite Data
;------------------------------------------------------------------------
InitSpritePtr
            STX _SpritePtr+2    ; 0050: *** SELF-MODIFES vvv
            STY _SpritePtr+1    ; 0052: *** SELF-MODIFES vvv
            RTS                 ; 0054:

;------------------------------------------------------------------------
; OUT:
;   A=Byte
; NOTES:
;   Source Address is auto incremented accounting for page crosses
;------------------------------------------------------------------------
GetSpriteData
_SpritePtr
            LDA $C0DE               ; 0055: *** SELF-MODIFIED ^^^
IncSpriteData                       ; 0058:
            INC _SpritePtr+1        ; 0058:
            BNE SpriteDataSamePage  ; 005A:
            INC _SpritePtr+2        ; 005C:
SpriteDataSamePage                  ; 005E:
            RTS                     ; 005E:

;------------------------------------------------------------------------
; IN:
;   A=frame index, see FRAME_BLOOD_*
;   X=hi 16-bit address Source Sprite Data
;   Y=lo 16-bit address Source Sprite Data
;   C=0 Main memory
;     1 Aux memory
; OUT:
;   aFrameFunc[ A ] = address of compiled delta frame code
;
; DATA:
;   <base>                  ; page $20 or $40
;   [
;       <span>              ; bytes on page base + M
;       [
;           <byte1,addr1>,
;           ...,
;           <byteN,addrN>
;       ]                   ; repeated N times
;   ]                       ; repeated M times
;
; Defaults to AUX $base
;   span = 0 end-of-data
;   span < 0 switch to writing to MAIN
;
;------------------------------------------------------------------------
;
; ***NOTE***
;
; All writes to variables MUST be on ZP
; since we may be writing to AUX memory
; for the compiled delta frame code generated at run-time
;
; ***NOTE***
;
; You _probably_ want to turn of writes to AUX memory
; after calling!
;
;           STA SW_AUXWROFF
;
;------------------------------------------------------------------------
CompileDeltaFrame
            JSR InitSpritePtr       ; free up X & Y asap
            LDY #0                  ; default to writing MAIN mem
            STA SW_AUXWROFF         ;
            BCC CompileFrameMainMem ;
            INY                     ;
            STA SW_AUXWRON          ; switch to writing AUX mem
CompileFrameMainMem                 ;
            STY CompileMemType+1    ;

; Build Array of Function Pointers
; aFuncs[ nFuncs++ ] = next emit address
            ASL                     ; A < 0 -> C=0; OPT: could be removed if enum*2
            TAX                     ;
            LDA EmitByteImm+1       ;
CompileMemType
            ADC #0                  ; SELF-MODIFIED ^ ADC #0 MAIN mem or ADC #1 AUX mem
            STA aFrameFunc +0,X     ;
            LDA EmitByteImm+2       ;
            STA aFrameFunc +1,X     ;

; Sprites defaults to writing to aux mem
SpriteAux
            LDA #$05            ; STA $C005 ; AUXWRON
            JSR EmitAuxMain     ;

            JSR GetSpriteData   ; <base>
            STA FramePage+1     ; SELF-MODIFYING v
            STA zFramePage      ;

CompileSprite
            JSR GetSpriteData   ; A = <num_delta_bytes_this_page>

            LDX _SpritePtr   +1 ; low addr
            STX _SrcFrameAdr1+1 ; SELF-MODIFYING vv
            STX _SrcFrameAdr2+1 ; SELF-MODIFYING vv

            LDX _SpritePtr   +2 ; high addr
            STX _SrcFrameAdr1+2 ; SELF-MODIFYING vvv
            STX _SrcFrameAdr2+2 ; SELF-MODIFYING vvv
            LDX #0              ; spanoffset = 0

            TAY                 ; if pos, save length
            BEQ CompileDone
            BPL SpriteSpan

; Handle case of no changes bytes on this page
            ASL
            BMI UpdateSamePage  ; Force next page
SpriteMain
            TYA
            AND #$7F            ; delta_bytes_this_page has sign bit set to signal switch writing from aux memory to main memory for sprite data
            TAY                 ; made pos, save length

            LDA #$04            ; STA $C004 ; AUXWROFF
            JSR EmitAuxMain

            LDA zFramePage      ; reset to start of page
            STA FramePage+1     ; SELF-MODIFYING vv

; --- y = # of spans ---
SpriteSpan
            JSR EmitByteA9
;           JSR GetSpriteData   ; OPT: Inlined
_SrcFrameAdr1
            LDA $da1a,X         ; SELF-MODIFIED ^^ spanoffset[ x++ ]
            INX
            JSR EmitByteImm

            JSR EmitByte8D      ; STA $abs
;           JSR GetSpriteData   ; OPT: Inline
_SrcFrameAdr2
            LDA $da1a,X         ; 00AF SELF-MODIFIED ^^^ spanoffset[ x++ ]
            INX                 ; 00B2
            JSR EmitByteImm     ; 00B3
FramePage
            LDA #0              ; 00B6 SELF-MODIFIED ^v
            JSR EmitByteImm     ; 00B8
            DEY                 ; 00BB
            BNE SpriteSpan      ; 00BC

; Sync X back to Source Pointer += X
            TXA                 ; 00BE
            CLC
            ADC _SpritePtr+1    ; 00BF
            STA _SpritePtr+1    ; 00C1
            BCC UpdateSamePage  ; 00C3
            INC _SpritePtr+2    ; 00C5
UpdateSamePage                  ; 00C7
            INC FramePage+1     ; 00C7 SELF-MODIFYING ^
            BNE CompileSprite   ; 00C9 allways -- sprite never writes to page $00

; Normally we would check after the 1st RTS
; if we end up on an odd address then
; we would emit an extra RTS to force the next address to be even
;     dst = $BE00: 60
;     dst = $BE01: 60
;           LDA #$60            ; RTS
;           JSR EmitByteImm     ; always -- NOTE: *intentional* fall into EmitByteImm
;           LDA EmitByteImm+1   ; Align to 2 byte boundary
;           AND #1              ; since odd address is a flag that code is in AUX mem
;           BEQ _SpriteAlign2   ;
;           LDA #60             ;
;           BNE EmitByteImm     ;
;_SpriteAlign2                  ;
;           RTS                 ;
; Instead we check if the address is even and thus we know
; that we need to emit two RTS instead of just one

CompileDone
            LDA EmitByteImm+1   ; 00CB low addr
            LSR                 ; 00CD C= isAddrOdd?
            BCS EmitByte60      ; 00CE C=1 after emit next addr will be even thus only need single RTS
            JSR EmitByte60      ; 00D0
EmitByte60  LDA #$60            ; 00D3 RTS
            BNE EmitByteImm     ; 00D5 always

; Compile Delta Frame Data -> Code
zFramePage  db 0                ; 00D7: Which DHGR page the compiled frame writes to $20
zSpriteNext db 0                ; 00D8: Array of Function Pointers, next address to write to

;------------------------------------------------------------------------
; Set address of generated code for next compiled sprite
; IN:
;   A=sprite index
;   X=hi 16-bit address Dest Sprite Code
;   Y=lo 16-bit address Dest Sprite Code
;------------------------------------------------------------------------
SetCompiledFrameDeltaAddr
            STX EmitByteImm+2   ; 00D9: *** SELF-MODIFIES vvv
            STY EmitByteImm+1   ; 00DB: *** SELF-MODIFIES vvv
            RTS                 ; 00DD:

;------------------------------------------------------------------------
; IN:
;    A=04 -> emit STA $C004 ; AUXWROFF
;    A=05 -> emit STA $C005 ; AUXWRON
;------------------------------------------------------------------------
EmitAuxMain
            PHA                 ; 00E5
            JSR EmitByte8D      ; 00E6
            PLA                 ; 00E9
            JSR EmitByteImm     ; 00EA STA $C004 ; AUXWROFF
            LDA #$C0            ; 00ED
;           JSR EmitByte        ;      NOTE: *intentional* fall into EmitByteImm
            DB  $2C             ; 00EF bit $abs -- SKIP NEXT instruction!
EmitByteA9  LDA #$A9            ; 00F0 LDA #imm
            DB  $2C             ; 00F2 bit $abs -- SKIP NEXT instruction!
EmitByte8D  LDA #$8D            ; 00F3 STA $abs -- NOTE: *intentional* fall into EmitByteImm
EmitByteImm STA $c0de           ; 00F5 *** SELF-MODIFIED ^^^vvv
            INC  EmitByteImm+1  ; 00F8 *** SELF-MODIFIED    ^^^
            BNE _EmitSamePage   ; 00FA
            INC  EmitByteImm+2  ; 00FC *** SELF-MODIFIED    ^^^
_EmitSamePage                   ; 00FE
            RTS                 ; 00FE

;========================================================================

__reloc_end = *
__reloc_len = __reloc_end - __reloc_dst
__end       = __reloc_len + __reloc_src
__base      = __reloc_len - __reloc_src

            ORG
__zerppage_end  = *

