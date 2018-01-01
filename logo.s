; Assembler: Merlin32
; https://brutaldeluxe.fr/products/crossdevtools/merlin/index.html
;
; DHGR Screen Difference to Compiled Sprite
; Frame Delta


GBASL       = $26   ; 16-bit pointer to start of D/HGR scanline
GBASH       = $27

GBAS2       = $28   ; pointer to opposite DHGR page

MOV_SRC     = $003C ; A1L
MOV_END     = $003E ; A2L
MOV_DST     = $0042 ; A4L


zMemCopy    = $E0              ; memcpy() at ZP to generate small INC SRC and INC DST pointer code!
MoveSrc     = zMemCopy + 1     ; LDA $abs
MoveDst     = zMemCopy + 1 + 3 ; LDA $abs

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

; Compile Sprite Data -> Code
zSpriteSrc  = $F6 ; Mirror of zSpritePtr for reading key/val pairs
zSpriteDst  = $F8 ;
zSpritePage = $FA ; Dest Page = Screen Address of Sprite, i.e. $20
zSpriteTemp = $FB ; Mirror of zSpritePage for aux/main switch
zSpriteNext = $FC ; Array of Function Pointers, next address to write to

UNPACK_SPRITES = 1
CROWN_EYES     = 1

SpriteLogo_RELOC  = $0100
SpriteTitle_RELOC = $D000
Crown13_RELOC     = $0CBA ; + $F25 = $1BDF

SPRITE_FUNC = $800 ; 2 bytes/entry ; NOTE: Intentional over-write bottom of stack! (Can change to start-of-program if needed)
; DHGR Frames
BLOOD_13 = 2*$00
BLOOD_24 = 2*$01
BLOOD_31 = 2*$02
BLOOD_42 = 2*$03
BLOOD_1  = 2*$04
BLOOD_2  = 2*$05
CROWN_13 = 2*$06
CROWN_24 = 2*$07
CROWN_31 = 2*$08
CROWN_42 = 2*$09
EYES_13  = 2*$0A
EYES_24  = 2*$0B
EYES_31  = 2*$0C
EYES_42  = 2*$0D

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

aHgrYLo     = $200 ; 16-bit pointer start scan line - low byte
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

        ORG $0800

Main
        STA SW_AUXWROFF
        STA SETSTDZP
        JSR MakeHgrTables

; Since the SpriteLogo is $F6 bytes
; we copy the SpriteLogo to the stack page!
; This means we RTS to [$00FE] = $0000 --> $0001
        LDA #$4C                ; JMP $abs
        LDX #>_DoneLogoSprite
        LDY #<_DoneLogoSprite
        STA $01
        STY $02
        STX $03
        LDX #$FF                ; Reset stack
        TXS

_InitLogoSprite
        LDX #>SpriteLogo        ; SrcPage
        LDY #>SpriteLogo_RELOC  ; DstPage
        LDA #>_sprite_logo_len  ; LenPage
        JSR MoveSprite

_DoneLogoSprite

_InitTitleSprite
        LDA LCBANK1             ; $D000 BANK 1
        LDA LCBANK1
        LDX #>SpriteTitle       ; SrcPage
        LDY #>SpriteTitle_RELOC ; DstPage
        LDA #>_sprite_title_len ; LenPage
        JSR MoveSprite

    DO UNPACK_SPRITES

        LDA LCBANK2     ; Use Bank 2 $D000
        LDA LCBANK2
        STA SETALTZP    ; AUX Bank 2 $D000

UnpackSprites

; === Blood ===

        LDX #$D0
        LDY #$00
        JSR InitCompileSpriteDest

        LDA #BLOOD_13       ; @ $D000
        LDX #>blood1delta3
        LDY #<blood1delta3
        JSR CompileSprite

    LDA #"."
    STA $400

        LDA #BLOOD_24       ; @ $D5A2
        LDX #>blood2delta4
        LDY #<blood2delta4
        JSR CompileSprite

    LDA #"."
    STA $401

        LDA #BLOOD_31       ; @ $DB3F
        LDX #>blood3delta1
        LDY #<blood3delta1
        JSR CompileSprite

    LDA #"."
    STA $402

        LDA #BLOOD_42       ; @ $E0E1
        LDX #>blood4delta2
        LDY #<blood4delta2
        JSR CompileSprite

    LDA #"."
    STA $403

        LDA #BLOOD_1        ; @ $E67E
        LDX #>frame1delta0
        LDY #<frame1delta0
        JSR CompileSprite

    LDA #"."
    STA $404

        LDA #BLOOD_2        ; @ $E900
        LDX #>frame2delta0
        LDY #<frame2delta0
        JSR CompileSprite
                            ; @ $EC44 ends

    LDA #"."
    STA $405

; Safe to over-write/re-use packed blood data

        LDX #>Crown13_RELOC
        LDY #<Crown13_RELOC
        JSR InitCompileSpriteDest

        LDA #CROWN_13       ; @ $0E00 (was $EC45)
        LDX #>crown1delta3
        LDY #<crown1delta3
        JSR CompileSprite   ; Size = $101F, (was Next @ $FC64)


    DO CROWN_EYES

; === Crown ===

        STA SETSTDZP    ; MAIN Bank 2 $D000

        LDX #$D0
        LDY #$00
        JSR InitCompileSpriteDest

    LDA #"."
    STA $500

        LDA #CROWN_24       ; @ $D000
        LDX #>crown2delta4
        LDY #<crown2delta4
        JSR CompileSprite

    LDA #"."
    STA $501

        LDA #CROWN_31       ; @ $DF25
        LDX #>crown3delta1
        LDY #<crown3delta1
        JSR CompileSprite

    LDA #"."
    STA $502

        LDA #CROWN_42       ; @ $EF44
        LDX #>crown4delta2
        LDY #<crown4delta2
        JSR CompileSprite   ; Size = $F25, Next @ $FE69

    LDA #"."
    STA $503


; === Eyes ===

        LDA LCBANK1
        LDA LCBANK1
; Now fill main 48K with compiled sprite data
; since LC Banks 1 & 2 don't have any more room
; for another compiled sprites

        LDX #>__code_end
        LDY #<__code_end
        JSR InitCompileSpriteDest

        LDA #EYES_13        ; $7ACE
        LDX #>eye1delta3
        LDY #<eye1delta3
        JSR CompileSprite

    LDA #"."
    STA $600

        LDA #EYES_24        ; $8C69
        LDX #>eye2delta4
        LDY #<eye2delta4
        JSR CompileSprite

    LDA #"."
    STA $601

        LDA #EYES_31        ; $9D14
        LDX #>eye3delta1
        LDY #<eye3delta1
        JSR CompileSprite

    LDA #"."
    STA $602

        LDA #BLOOD_42       ; $AEAF
        LDX #>eye4delta2
        LDY #<eye4delta2
        JSR CompileSprite   ; Len = $, Next @ $BF5A

    LDA #"."
    STA $603

; CROWN_EYES
    FIN 

; UNPACK_SPRITES
    FIN

        LDA RAMIN2

;       JSR InitMemCopy
Init
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

        LDA RAMIN1          ; $D000 Bank 1

        LDX #>SpriteTitle_RELOC
        LDY #<SpriteTitle_RELOC
        JSR DrawSprite      ; draw on page 1

        LDA #$2C            ; bit $abs - no delay drawing
        STA SpriteDelay

        LDA #$40
        STA HGR_PAGE
        LDX #>SpriteTitle_RELOC
        LDY #<SpriteTitle_RELOC
        JSR DrawSprite      ; draw on page 2

        LDA RAMIN2          ; $D000 Bank 2

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

    DO UNPACK_SPRITES
        STA SETALTZP    ; AUX Bank 2 $D000
        LDA #BLOOD_1        ; frame1delta0
        JSR DrawCompiledSprite
    ELSE
        JSR frame1delta0
    FIN
        STA SW_PAGE1

; Draw Frame 2 Page 2
        JSR Delay

    DO UNPACK_SPRITES
        LDA #BLOOD_2        ; frame2delta0
        JSR DrawCompiledSprite
    ELSE
        JSR frame2delta0
    FIN
        STA SW_PAGE2

; Animate blood
; ==========
        LDA #0
        STA zTimer+0

State5

; Page 1 - Frame 3
        JSR Delay

        LDX #BLOOD_31
    DO UNPACK_SPRITES
        JSR DrawCompiledSprite  ; blood3delta1
    ELSE
        JSR blood3delta1
    FIN
        STA SW_PAGE1
        JSR BloodWait
        BCS Loop

; Page 2 - Frame 4
        JSR Delay
        LDX #BLOOD_42
    DO UNPACK_SPRITES
        JSR DrawCompiledSprite   ; blood4delta2
    ELSE
        JSR blood4delta2
    FIN
        STA SW_PAGE2
        JSR BloodWait
        BCS Loop

; Page 1 - Frame 1
        JSR Delay
        LDX #BLOOD_13
    DO UNPACK_SPRITES
        JSR DrawCompiledSprite  ; blood1delta3
    ELSE
        JSR blood1delta3
    FIN
        STA SW_PAGE1
        JSR BloodWait
        BCS Loop

; Page 2 - Frame 2
        JSR Delay
        LDX #BLOOD_24
    DO UNPACK_SPRITES
        JSR DrawCompiledSprite  ; blood2delta4
    ELSE
        JSR blood2delta4
    FIN
        STA SW_PAGE2
        JSR BloodWait
        BCS Loop

        JSR Delay
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
        LDX #>Crown1        ; @ $60BE
        LDY #<Crown1
        JSR DrawSprite      ; draw on page 1
        STA SW_PAGE1

        LDA #$40
        STA HGR_PAGE
        LDX #>Crown2        ; @ $6D82
        LDY #<Crown2
        JSR DrawSprite      ; draw on page 2

; Animate crown
; ==========

        LDA #0
        STA zTimer+0

State7

    DO CROWN_EYES
; Page 1 - Frame 3
        JSR Delay

    DO UNPACK_SPRITES
        LDX #CROWN_31
        LDA LCBANK1
        LDA LCBANK1
        JSR DrawCompiledSprite
    ELSE
        JSR crown3delta1
    FIN
        STA SW_PAGE1
        JSR BloodWait
        BCS Loop

; Page 2 - Frame 4
        JSR Delay
    DO UNPACK_SPRITES
        LDX #CROWN_42           ; @ $EF44 MAIN Bank 2
        JSR DrawCompiledSprite
    ELSE
        JSR crown4delta2
    FIN
        STA SW_PAGE2
        JSR BloodWait
        BCS Loop

; Page 1 - Frame 1
        JSR Delay
    DO UNPACK_SPRITES
        JSR Crown13_RELOC
    ELSE
        JSR crown1delta3
    FIN
        STA SW_PAGE1
        JSR BloodWait
        BCS Loop

; Page 2 - Frame 2
        JSR Delay
    DO  UNPACK_SPRITES
        LDX #CROWN_24
        JSR DrawCompiledSprite
    ELSE
        JSR crown2delta4
    FIN

        STA SW_PAGE2
        JSR BloodWait
        BCS Loop

        JSR Delay
        INC zTimer+0
        LDA zTimer+0
        CMP #3
        BNE State7
    FIN ; CROWN_EYES

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
        LDA #0
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


; Drawm Sprite -- uses data for x,y
; Input:
;   X=ho 16-bit address Source Sprite Data
;   Y=lo 16-bit address Source Sprite Data
;========================================================================
DrawSprite
        STA SW_AUXWROFF     ; Write MAIN
        JSR InitSpritePtr

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

; IN:
;   X=hi 16-bit address Source Sprite Data
;   Y=lo 16-bit address Source Sprite Data
;------------------------------------------------------------------------
InitSpritePtr
        STX _SpritePtr+2    ; *** SELF-MODIFES vvv
        STY _SpritePtr+1    ; *** SELF-MODIFES vvv
        RTS

; OUT: X=Byte
;------------------------------------------------------------------------
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
InitMemCopy
            LDX #_EndCopy - _MemCopy - 1
_InitMemCopy
            LDA _MemCopy,X
            STA zMemCopy,X
            DEX
            BPL _InitMemCopy
            INX                     ; LDX #0 for zMemCopy
            JMP $0000 + zMemCopy    ; Work around Merlin32 BUG: JMP $zp -> JMP $0000 + zMemCopy

; Assumes X=0 on entry!
_MemCopy                        ; Run from ZP! -> zMemCopy

; Copy up "forward"
;_MovSrc     LDA __reloc_src,X   ; 00E0: *** SELF-MODIFIED = 1D7C
;_MovDst     STA __reloc_dst,X   ; 00E3: *** SELF-MODIFIED = 6000
;            INX                 ; 00E6:
;            BNE _MovSrc         ; 00E7:
;           INC MoveSrc+1       ; 00E9:
;           INC MoveDst+1       ; 00EB:
;           LDA MoveSrc+1       ; 00ED:
;           CMP #>__end         ; 00EF: assumes aligned to end of page

; Copy "down" reverse
_MovSrc     LDA __reloc_len,X   ; 00E0: *** SELF-MODIFIED = $9258
_MovDst     STA __end,X         ; 00E3: *** SELF-MODIFIED = 
            INX                 ; 00E6:
            BNE _MovSrc         ; 00E7:
            DEC MoveSrc+1       ; 00E9:
            DEC MoveDst+1       ; 00EB:
            LDA MoveSrc+1       ; 00ED:
            CMP #>__reloc_src   ; 00EF: assumes aligned to end of page

            BNE _MovSrc         ; 00F1:
            RTS                 ; 00F3:
_EndCopy




; IN:
;   X: index in array of function pointers
;========================================================================
DrawCompiledSprite
        LDA SPRITE_FUNC+0,X
        LDY SPRITE_FUNC+1,X
        STA Trampoline+1    ; *** SELF-MODIFYING vvv
        STY Trampoline+2    ; *** SELF-MODIFYING vvv
Trampoline
        JMP $c0de           ; *** SELF-MODIFIED ^^^




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

    DO CROWN_EYES
crown1delta3 use crown13.s
crown2delta4 use crown24.s
crown3delta1 use crown31.s
crown4delta2 use crown42.s

eye1delta3   use eyes13.s
eye2delta4   use eyes24.s
eye3delta1   use eyes31.s
eye4delta2   use eyes42.s
    FIN

;========================================================================
; IN:
;   A=sprite index
;   X=hi 16-bit address Source Sprite Data
;   Y=lo 16-bit address Source Sprite Data
; OUT:
;   SPRITE_FUNC[ A ] = address of dest compiled sprite code
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
;========================================================================
CompileSprite
            JSR InitSpritePtr

; Build Array of Function Pointers
; aFuncs[ nFuncs++ ] = next emit address
            TAX
            LDA EmitByteImm+1
            STA SPRITE_FUNC+0,X
            LDA EmitByteImm+2
            STA SPRITE_FUNC+1,X

; Sprites defaults to writing to aux mem
SpriteAux
            LDA #$05            ; STA $C005 ; AUXWRON
            JSR EmitAuxMain

            JSR GetSpriteData   ; <base>
            STX zSpritePage
            STX zSpriteTemp

_CompileSprite
            JSR GetSpriteData   ; X = <num_delta_bytes_this_page>
            TXA
            TAY
            BEQ _CompileDone
            BPL SpriteSpan
SpriteMain
            AND #$7F            ; delta_bytes_this_page has sign bit set to signal switch writing from aux memory to main memory for sprite data
            TAY

            LDA #$04            ; STA $C004 ; AUXWROFF
            JSR EmitAuxMain

            LDA zSpriteTemp     ; reset to start of page
            STA zSpritePage

; --- y = # of spans ---
SpriteSpan
            JSR EmitByteA9
            JSR GetSpriteData
            JSR EmitByteImm

            JSR EmitByte8D      ; STA $abs
            JSR GetSpriteData
            JSR EmitByteImm
            LDX zSpritePage
            JSR EmitByteImm

            DEY
            BNE SpriteSpan

            INC zSpritePage
            BNE _CompileSprite  ; allways -- sprite never writes to page $00
_CompileDone
            LDX #$60            ; RTS
            BNE EmitByteImm     ; always -- NOTE: *intentional* fall into EmitByteImm

; IN:
;    A=04 -> $C004 ; AUXWROFF
;    A=05 -> $C005 ; AUXWRON
;========================================================================
EmitAuxMain
            JSR EmitByte8D
            TAX                 ; STA $C005 ; AUXWRON
            JSR EmitByteImm     ; STA $C004 ; AUXWROFF
            LDX #$C0
;           JSR EmitByte        ; NOTE: *intentional* fall into EmitByteImm
            DB  $2C             ; bit $abs -- SKIP NEXT instruction!
EmitByteA9  LDX #$A9            ; LDA #imm
            DB  $2C             ; bit $abs -- SKIP NEXT instruction!
EmitByte8D  LDX #$8D            ; STA $abs
EmitByteImm
            STX $c0de           ; *** SELF-MODIFIED ^^^vvv
            INC  EmitByteImm+1  ; *** SELF-MODIFIED    ^^^
            BNE _EmitSamePage
            INC  EmitByteImm+2  ; *** SELF-MODIFIED    ^^^
_EmitSamePage
            RTS

; Set address of generated code for next compiled sprite
; IN:
;   A=sprite index
;   X=hi 16-bit address Dest Sprite Code
;   Y=lo 16-bit address Dest Sprite Code
;========================================================================
InitCompileSpriteDest
            STX EmitByteImm+2   ; *** SELF-MODIFIES vvv
            STY EmitByteImm+1   ; *** SELF-MODIFIES vvv
            RTS

;========================================================================
; Instead of wasting 2 disk sectors for the HGR Y low and high tables
; dynamically build them at run-time.
;
; Size: $60 bytes
;
; Output:
;    aHgrYLo     = $200
;    aHgrYHi     = $300
;========================================================================
MakeHgrTables

MakeHgrLo
            LDX #$0             ; [00]..[3F]
            TXA
            JSR MakeHgrLoTriad
            JSR MakeHgrLoTriad

            LDX #$40            ; [40..7F]
            LDA #$28
            JSR MakeHgrLoTriad
            JSR MakeHgrLoTriad

            LDX #$80            ; [80..BF]
            LDA #$50
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


;========================================================================

            DS \,0
_sprite_logo_beg = *

; Move @ -> $0100 Stack = SpriteLogo_RELOC
SpriteLogo  PUTBIN logo.sprite

; ------------------------------------------------------------------------

            DS \,0
_sprite_logo_end  = *
_sprite_logo_len  = _sprite_logo_end - _sprite_logo_beg
_sprite_title_beg = *

; Move @ -> $D000 LC Bank 1 = SpriteTitle_RELOC
SpriteTitle PUTBIN title.sprite

; ------------------------------------------------------------------------

_sprite_title_end  = *
_sprite_title_len  = _sprite_title_end - _sprite_title_beg

;========================================================================

; Data at $6100
Crown1      PUTBIN crown1.sprite
Crown2      PUTBIN crown2.sprite

__code_end  = *


;------------------------------------------------------------------------
; Can't use MOVE = $FE2C to write to LC Bank 1/2
; IN:
;   X=Src Page
;   Y=Dst Page
;   A=Len Page
;------------------------------------------------------------------------
MoveSprite
            STX _MoveSrc+2  ; *** SELF-MODIFIES vvv     = Src Hi
            STY _MoveDst+2  ; *** SELF-MODIFIES     vvv = Dst Hi
            TAY
_MovePage
            LDX #0
_MoveSrc    LDA $DA00,X     ; *** SELF-MODIFIED ***
_MoveDst    STA $DA00,X     ; *** SELF-MODIFIED     ***
            INX
            BNE _MoveSrc
            INC _MoveSrc+2  ; *** SELF-MODIFIES ^^^
            INC _MoveDst+2  ; *** SELF-MODIFIES     ^^^
            DEY             ; Next Page
            BNE _MovePage
            RTS



__reloc_end = *
__reloc_len = __reloc_end - __reloc_dst
__end       = __reloc_len + __reloc_src
__base      = __reloc_len - __reloc_src

