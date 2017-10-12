; Show DHGR Logo
;
; References:
;   Apple IIe #3
;   Double High-Resolution Graphics
;   * http://www.1000bit.it/support/manuali/apple/technotes/aiie/tn.aiie.03.html

MOV_SRC     = $003C ; A1L
MOV_END     = $003E ; A2L
MOV_DST     = $0042 ; A4L

KEY         = $C000
KEYSTROBE   = $C010

STORE80     = $C000
RDMAINRAM   = $C002 ; 2=OFF, 3=ON
WRMAINRAM   = $C004

SET80COL    = $C00D
CLR80VID    = $C00C

CLRALTCHAR  = $C00E

AUXMOVE     = $C311 ; Main<->Aux
MOVE        = $FE2C ; Main<->Main

GR          = $C050
FULL        = $C052
MIXED       = $C053
HGR         = $C057
AN3         = $C05E


; ========================================
        ORG $1F80

; Main
        STA STORE80
        STA RDMAINRAM
        STA WRMAINRAM

        STA CLR80VID
        STA CLRALTCHAR

; Copy MAIN $2000..$3FFF to AUX $2000
        SEC             ; C=1 Main to Aux

        LDA #$20        ;
        STA MOV_SRC+1   ; Src Hi
        STA MOV_DST+1   ; Dst Hi
        LDA #$40
        STA MOV_END+1   ; End Hi

        LDA #$00        ;
        STA MOV_SRC+0   ; Src Lo
        STA MOV_DST+0   ; Dst Hi
        STA MOV_END+0   ; End Lo

        JSR AUXMOVE

; Copy MAIN $4000..$5FFF to MAIN $2000
        LDA #$40
        STA MOV_SRC+1   ; Src Hi
        LDA #$20
        STA MOV_DST+1   ; Dst Hi
        LDA #$60
        STA MOV_END+1   ; End Hi

        LDA #$00    ;
        STA MOV_SRC+0   ; Src Lo
        STA MOV_DST+0   ; Dst Hi
        STA MOV_END+0   ; End Lo

        JSR MOVE

; Showtime!
        STA HGR         ; $C057
        STA GR          ; $C050
        STA AN3         ; $C05E
        STA FULL        ; $C052
        STA SET80COL    ; $C00D

WaitForKey
        LDA KEY
        BPL WaitForKey
        STA KEYSTROBE

        STA GR+1        ; Switch back to TEXT
        STA CLR80VID    ; 40-col
        RTS

        DS \,$00

; ========================================

        PUTBIN logo.dhgr

