; Authors:     Peter Ferrie and Michaelangel007
; Assembler:   merlin32
; Direction:   Unpack from high mem to low memory
; Compression: lz4 -1 (Fast)
; NOTE:
;   A single 16K DHGR image has been split into 2x 8K, no-gap, lz4 files

CONFIG_HGR  = 0         ; 0 = DHGR, 1 = HGR

;unpacker variables, no need to change these
src         = $0
dst         = $2
end         = $4
count       = $6
delta       = $8

ADDR_HGR1   = $2000
ADDR_HGR2   = $4000

KEY         = $C000
KEYSTROBE   = $C010

; I/O Soft Switches

STORE80     = $C000 ; alias: 80STORE
RDMAINRAM   = $C002 ; 2=OFF, 3=ON
WRMAINRAM   = $C004

SET80COL    = $C00D ; alias: 80COL
CLR80COL    = $C00C

CLRALTCHAR  = $C00E

GR          = $C050 ; GR+1 = Text
FULL        = $C052
MIXED       = $C053
HIRES       = $C057 ; Lo-Res = $56, Hi-Res = $57
AN3         = $C05E

        org $6000           ; Note: Could start @ $6000-$18 = $5FE8

; === Stages ===
; 1. Un-lz4 from $61xx --> $4000
; 2. Un-gap from $4000 --> $2000
; 4. Un-lz4 from $75xx --> $4000
; 5. Un-gap from $4000 --> $2000
; 6. Display DHGR
; ========================================
main

    DO !1-CONFIG_HGR
    ; 1. Un-lz4 from $61xx --> $4000
        ldx #<_pack_1_src
        ldy #>_pack_1_src
        jsr SetSrcLZ4

        ldx #<_pack_1_end
        ldy #>_pack_1_end
        jsr SetEndLZ4

        jsr SetDstLZ4

    ; 2. Un-gap from $4000 --> $2000
    ; 3. Copy from Main $2000 --> AUX $2000
        lda #dst        ; unpack
        ldx #>ADDR_HGR2 ; src
        ldy #>ADDR_HGR1 ; dst
        sec             ; Write to AUX
        jsr UnpackGAP
        sta WRMAINRAM   ; Write Main
    FIN

    ; 4. Un-lz4 from $75xx --> $4000
        ldx #<_pack_2_src
        ldy #>_pack_2_src
        jsr SetSrcLZ4

        ldx #<_pack_2_end
        ldy #>_pack_2_end
        jsr SetEndLZ4

        jsr SetDstLZ4

    ; 5. Un-gap from $4000 --> $2000
        lda #dst        ; unpack
        ldx #>ADDR_HGR2 ; src
        ldy #>ADDR_HGR1 ; dst
        clc             ; Write to MAIN
        jsr UnpackGAP

; 6. Display DHGR

        sta STORE80
;       sta RDMAINRAM
;       sta CLR80COL
        sta CLRALTCHAR

; Showtime!
        sta HIRES       ; $C057
        sta GR          ; $C050
    DO 1-CONFIG_HGR
        sta AN3         ; $C05E Turn DHGR on
    FIN
        sta FULL        ; $C052
        sta SET80COL    ; $C00D

WaitForKey
        lda KEY
        bpl WaitForKey
        sta KEYSTROBE

    DO 1-CONFIG_HGR
        sta AN3+1       ; $C05F Turn DHGR off
    FIN
        sta GR+1        ; Switch back to TEXT
        sta CLR80COL    ; 40-col
        rts

; ========================================================================
; After
; A = zero-page address of src (Pack)
; A = zero-page address of dst (Unpack)
; X = Src Page
; Y = Dst Page
; C = 0 Write to MAIN
; C = 1 Write to AUX
; ========================================================================
UnpackGAP
        stx src+1
        sty dst+1
                        ; Note: If WRAUXRAM need to turn on after this setup
        sta _Delta1+1   ; *** SELF-MODIFYING
        ;MAIN $2000
        sta _Delta2+1   ; *** SELF-MODIFYING
        tax             ; Note: Must not be on Page $FF
        inx             ; Carry not affected
        stx _Delta3+1   ; *** SELF-MODIFYING

        ldy #$00        ; low of src, low of dst
        sty src+0
        sty dst+0

        sta WRMAINRAM
        bcc WriteMain
        sta WRMAINRAM+1 ; Write AUX
WriteMain

        lda #$20        ; 32 pages * 6 scanlines/page = 192 scanlines
        sta count       ; See Alt. Optimization note below ...

; -------- process 3 scan lines
HalfPage
        ldx #$78        ; Pack 3 (non-linear) scan lines [$2000..$2027, $2028..$2057, $2058..$2077]
CopyHalf
        lda (src),y
        sta (dst),y

        inc src+0       ; src++
        bne SrcPage
        inc src+1       ; 16-bit pointer
SrcPage
        inc dst+0       ; dst++
        bne DstPage
        inc dst+1       ; 16-bit pointer
DstPage
        dex
        bne CopyHalf

; -------- processed 6 scanlines?
        clc             ; src += 8
_Delta1 lda src+0       ; *** SELF-MODIFIED
        adc #8          ; src = $xx78 + 8 -> $xx80
_Delta2 sta src+0       ; *** SELF-MODIFIED
        bne HalfPage    ; src = $xxF8 + 8 -> $yy00
_Delta3 inc src+1       ; *** SELF-MODIFIED
                        ; Alt. Optimization:
        dec count       ; Alternative not any smaller -- also need: sta _Delta4+1
        bne HalfPage    ; _Delta4 LDA SRC+1, AND #$1F
        rts

; Utility
; ________________________________________________________________________
SetSrcLZ4
        stx src
        sty src+1
        rts

SetEndLZ4
        stx end
        sty end+1
        rts

SetDstLZ4
        ldx #<ADDR_HGR2
        ldy #>ADDR_HGR2
        stx dst
        sty dst+1
; !!! INTENTIONAL FALL INTO UnpackLZ4 !!!

; ========================================================================
; ENTRY:
;   src Start of compressed data
;   end End   of compressed data
;   dst Where to write uncompressed data
; USES:
;   count
;   delta 
; Reference:
; https://github.com/lz4/lz4/wiki/lz4_Frame_format.md
; ========================================================================
UnpackLZ4

parsetoken
        jsr getsrc
        pha             ; $xy
        lsr
        lsr
        lsr
        lsr
        beq copymatches ; $0y <16-bit -delta>
        jsr buildcount  ; $x?
        tax
        jsr docopy

        lda src
        cmp end
        lda src+1
        sbc end+1
        bcs done

copymatches
        jsr getsrc
        sta delta
        jsr getsrc
        sta delta+1
        pla
        and #$0f
        jsr buildcount
        clc
        adc #4
        tax
        bcc :skipcount
        iny
:skipcount
        lda src+1
        pha
        lda src
        pha
        sec

        lda dst
        sbc delta
        sta src

        lda dst+1
        sbc delta+1
        sta src+1

        jsr docopy
        pla
        sta src
        pla
        sta src+1
        bne parsetoken  ; OPTIMIZATION: always since SRC is never on ZP
;        jmp parsetoken

done
        pla
        rts

docopy
        jsr getsrc
putdst
        sta (dst)       ; *** 65C02 ***
        inc dst
        bne :dstsamepage
        inc dst+1
:dstsamepage

        dex
        bne docopy
        dey
        bne docopy
        rts

buildcount
;   DO hiunp
;   ELSE
        ldy #1
;   FIN
        cmp #$0f
        bne :nocount
:nextcount
        sta count
        jsr getsrc
        tax
        clc
        adc count
        bcc :donecount
        iny
:donecount
        inx
        beq :nextcount
:nocount
        rts

getsrc
        lda (src)       ; *** 65C02 ***
        inc src
        bne :srcsamepage
        inc src+1
:srcsamepage
        rts


; ========================================

; Default to packed data at end of code
; LZ4 files have an 11 byte header that we ignore
; If you strip this header replace with *+0
;     +4 Magic Number: 0x184D2204
;     +2 Frame Descriptor: $64 $40
;        FLG byte
;            Bits: 1100_0000  0010_0000  0001_0000   0000_1000  0000_0100   0000_0011
;            Mask: $C0        $20        $10         $08        $04         $03
;            Desc: Version    B.Indep    B.Checksum  C.Size     C.Checksum  Reserved
;
;              vv---Version = 01
;                v--Block Independent = yes
;                 v-Block Checksum = no
;        $64 = 0110_0100
;                     ^^_Reserved
;                    ^___C.Checksum = 1
;                   ^____Size = 0
;            Checksum: yes
;        BD byte
;            Bits: 1000_0000 0111_0000      0000_1111
;            Mask: $80       $70            $0F
;            Desc: Reserved  Block MaxSize  Reserved
;        $40 -> Block MaxSize 4 = 64KB
;     +4 End Mark
;     +1 Checksum

; -> AUX $2000
_pack_1_src = *+4+3+4

    DO !1-CONFIG_HGR

        ;split -a 1 -b 8192 logo.dhgr temp/logo_split_
        ;  gap                        temp/logo_split_a
        ;  lz4                        temp/logo_split_a.gap
        PUTBIN                        temp/logo_split_a.gap.lz4
    FIN

_pack_1_end = *
_pack_1_len = _pack_1_end - _pack_1_src

; -> MAIN $2000
_pack_2_src = *+4+3+4

        ;  lz4 temp/logo_split_b.gap
        PUTBIN temp/logo_split_b.gap.lz4

_pack_2_end = *
_pack_2_len = _pack_2_end - _pack_2_src

