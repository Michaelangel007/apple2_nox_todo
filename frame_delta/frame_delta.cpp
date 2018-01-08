/*
Synopsis:
    Compare two DHGR screens
    Find the bytes that are different per scanline
    Generate raw delta bytes or compiled-sprite

Usage:
    frame_delta <pic1.dhgr> <pic2.dhgr> <hgrpage> [-code | -data]

    Default is: -data
*/
#define DEBUG 0

// Includes
    #include <stdio.h>  // printf()
    #include <stdint.h> // uint8_t
    #include <stdlib.h> // atoi()
    #include <string.h> // strcmp()

// Consts
    const int   _K = 1024;
    const int  _8K =  8 * _K;
    const int _16K = 16 * _K;

// Globals
    uint8_t aFrame1[ _16K ];
    uint8_t aFrame2[ _16K ];

    int nSpans;
    int aSpanAdr[ 0x28 * 3 ]; // abs address
    int aSpanLen[ 0x28 * 3 ]; // width of span

    int aSpanOff[ 0x28 * 3 ]; // key: offset from base address scanline
    int aSpanVal[ 0x28 * 3 ]; // val: new byte value

    bool gbCompiledSprite = 0; // DEFAULT: -data
    bool gbAppendSentinel = 1;

    const char *gpFileName1 = NULL;
    const char *gpFileName2 = NULL;


// ========================================================================
int find_spans( const uint8_t *frame1, const uint8_t *frame2, int base, bool isMain )
{
    int  offset  = 0; // relative base address of start of DHGR scanline
    int  changes = 0;

        nSpans = 0;

    // $2000 .. $2077 = 3 scan lines
    // $2080 .. $20F7 = 3 scan lines
    for( int halfpage = 0; halfpage < 2; halfpage++ )
    {

        //   $2000 .. $2027 = 1st scanline
        //   $2028 .. $204F = 2nd scanline
        //   $2050 .. $2077 = 3rd scanline

        //   $2080 .. $20A7 = 1st scanline
        //   $20A8 .. $20CF = 2nd scanline
        //   $20D0 .. $20F7 = 3rd scanline
        for( int triad = 0; triad < 3; triad++ )
        {
            bool inSpan = false;
            int  edge; // left edge

            for( edge = 0; edge < 0x28; edge++ )
            {
                if( frame1[ offset + edge ]
                !=  frame2[ offset + edge ] )
                {
                    // New span or continuation of last one?
                    if( !inSpan )
                    {
#if DEBUG
    printf( "    Found new span @ $%04X:$%02X\n", offset, edge );
#endif
                        aSpanAdr[ nSpans ] = base +  offset + edge;
                        aSpanOff[ nSpans ] =         offset + edge; // key
                        aSpanVal[ nSpans ] = frame2[ offset + edge ]; // val
                        aSpanLen[ nSpans ] = 1;

#if DEBUG
    printf( "; nSpan = %d, Val = %02X, Addr = %04X\n", nSpans, aSpanVal[ nSpans ], aSpanAdr[ nSpans ] );
#endif
                        if( gbCompiledSprite )
                        {
                            printf( "        LDA #$%02X\n", aSpanVal[ nSpans ] );
                            printf( "        STA $%04X\n" , aSpanAdr[ nSpans ] );
                        }

                        nSpans++;
                        inSpan = true;
                    }
                }
                else
                {
                    if( inSpan )
                    {
#if DEBUG
    printf( "    ; Span Src: $%04X, Len: $%02X\n", aSpanAdr[ nSpans-1 ], aSpanLen[ nSpans-1 ] );
#endif
                        inSpan = false;
                    }
                }
            }

            // Close span if was open on last col
            if( inSpan )
            {
printf( "; *** INFO.*** Closing span on last column\n" );
                aSpanLen[ nSpans-1 ]++;
            }

            offset += 0x28;
        } // triad

        // $2000 .. $2077 = 3 scan lines
        // $2080 .. $20F7 = 3 scan lines
        offset += 8;
    } // halfpage

#if DEBUG
    printf( "    Spans: %d\n", nSpans );
#endif

    // Do span processing
    if( !gbCompiledSprite && nSpans )
    {
        // 0   Zero     = End-of-Data
        // <0  Negative = Tell sprite compiler that we need to switch from writing AUX memory to MAIN memory via emitting SW_AUXWROFF
        //     Sign bit set to avoid N+1 2's complement on 6502 Sprite Compiler/Parser
        //     Instead we can use a simple AND #$7F via:
        //
        //              JSR FetchByte
        //              TAY              ; Loop Counter
        //              BEQ Done
        //              BPL UnpackSpans
        //              AND #$7F
        //              TAY
        //          UnpackSpans
        //              :
        //          Done
        printf( "        db %3d %s        ; Spans @ $%02Xxx\n"
            , nSpans
            , isMain
            ? "+ $80"
            : "     "
            , (base >> 8) &0xFF
        );

        // Interleave byte,addr so that sprite compiler can emit code in sequential order
        //    JSR EmitByteA9
        //    JSR FetchByte    <--
        //    JSR EmitByteImm
        //    JSR EmitByte8D
        //    JSR FetchByte    <--
        //    JSR EmitByteImm
        //    JSR EmitBytePage
        for( int iSpan = 0; iSpan < nSpans; iSpan++ )
        {
            printf( "            db " );
            printf( "$%02X, ", aSpanVal[ iSpan ] & 0xFF );
            printf( "$%02X\n", aSpanAdr[ iSpan ] & 0xFF );
        }
    }

    int nBytes = nSpans
        ? 1 + nSpans*2  // 1 byte header, <key,val> per span
        : 0
        ;

    return gbCompiledSprite
        ? nSpans*5      // 5 bytes = LDA #id (2) + STA $abs (3)
        : nBytes
        ;
}


// File    Apple Memory
// $0000 = $2000 .. $3FFF aux
// $2000 = $2000 .. $3FFF main
// ========================================================================
void delta( const uint8_t *frame1, const uint8_t *frame2, int page )
{
    int iAddr;
    int iPage   = page*0x2000;
    int nBytesA = 0; // Aux
    int nBytesM = 0; // Main
    int nBytesZ = 0; // Misc

    printf( "; --- NOTE ---\n" );
    printf( "; This %s sprite file was AUTO GENERATED by frame_delta\n"
        , gbCompiledSprite
        ? "(code)"
        : "(data)"
    );
    printf( "; %s %s %d %s\n"
        , gpFileName1
        , gpFileName2
        , page
        , gbCompiledSprite
        ? "-code"
        : "-data"
    );
    printf( ";\n" );

    // Aux
    printf( "; === Aux ===\n" );
    if( gbCompiledSprite )
    {
        printf( "        sta $C005           ; AUXWRON\n" );
        nBytesZ += 3;
    }
    else
    {
        printf( "        db $%02X              ; Base Address\n", (iPage >> 8) & 0xFF );
        nBytesZ += 1;
    }

    for( iAddr = 0; iAddr < _8K; iAddr += 256 )
        nBytesA += find_spans( frame1 + iAddr, frame2 + iAddr, iPage + iAddr, false );

    // Main
    printf( "; === Main ===\n" );
    if( gbCompiledSprite )
    {
        printf( "        sta $C004           ; AUXWROFF\n" );
        nBytesZ += 3;
    }

    for( iAddr = _8K; iAddr < _16K; iAddr += 256 )
        nBytesM += find_spans( frame1 + iAddr, frame2 + iAddr, iPage + iAddr - _8K, (iAddr == _8K) );

    if( gbCompiledSprite )
    {
        printf( "        rts\n" );
        nBytesZ += 1;
    }
    else
    if( nSpans )
        if( gbAppendSentinel )
        {
            printf( "        db 0\n" ); // end of data
            nBytesZ++;
        }

    int nTotal = nBytesA + nBytesM + nBytesZ;
    printf( "; Total Bytes Aux.: $%04X (%d)\n", nBytesA, nBytesA );
    printf( "; Total Bytes Main: $%04X (%d)\n", nBytesM, nBytesM );
    printf( "; Total Bytes Misc: $%04X (%d)\n", nBytesZ, nBytesZ );
    printf( ";================== $%04X (%d)\n", nTotal , nTotal  );
}


// ========================================================================
int usage()
{
    printf(
"SYNOPSIS: Compare two DHGR images and produce a minimal byte difference.\n"
"\n"
"USAGE: frame_delta <pic1.dhgr> <pic2.dhgr> <hgrpage> [-code | -data | -compile]\n"
"\n"
"OPTIONS:\n"
"    -code      Generate 6502 .asm output\n"
"    -compile   alias for -code\n"
"    -data      Generate data table\n"
"\n"
"By default, '-data', delta bytes are generated in the following format:\n"
"\n"
" * single prefix byte which designates the DHGR memory page\n"
"   i.e. $20 or $40\n"
" * array of changed aux byte for pages $20xx - $3Fxx\n"
" * array of changed main bytes for pages $20xx - $3Fxx\n"
"\n"
"The array format for aux/main bytes changed is:\n"
"    <size_of_next_array>\n"
"     [ byte1, addr1, ... byteN, addrN ]\n"
"\n"
"The <size_of_next_array> has two special meaning: "
"    0    Sentinel for end-of-data\n"
"    < 0  Switch from writing AUX memory to writing MAIN memory\n"
"\n"
"Use '-code' to instead output 6502 assembly code (.s)\n"
"to draw the sprite at a fixed location.\n"
"This is a compiled sprite.\n"
"\n"
"EXAMPLE:\n"
"\n"
" Data:\n"
"\n"
"; === Aux ===\n"
"        db $20              ; Base Address\n"
"        db   2              ; Spans @ $20xx\n"
"            db $20, $6F\n"
"            db $20, $EF\n"
"        db   1              ; Spans @ $21xx\n"
"            db $08, $58\n"
"        db   2              ; Spans @ $22xx\n"
"            db $60, $2F\n"
"            db $20, $D7\n"
"\n"
"; === Main ===\n"
"        db   2 + $80        ; Spans @ $20xx\n"
"            db $4C, $6F\n"
"            db $44, $EF\n"
"        db   2              ; Spans @ $21xx\n"
"            db $7E, $57\n"
"            db $44, $AF\n"
"        db   2              ; Spans @ $22xx\n"
"            db $44, $2F\n"
"            db $44, $D7\n"
"\n"
" Code:\n"
"; === Aux ===\n"
"        sta $C005           ; AUXWRON\n"
"        LDA #$20\n"
"        STA $206F\n"
"        LDA #$20\n"
"        STA $20EF\n"
"        LDA #$08\n"
"        STA $2158\n"
"        LDA #$60\n"
"        STA $222F\n"
"        LDA #$20\n"
"        STA $22D7\n"
"; === Main ===\n"
"        sta $C004           ; AUXWROFF\n"
"        LDA #$4C\n"
"        STA $206F\n"
"        LDA #$44\n"
"        STA $20EF\n"
"        LDA #$7E\n"
"        STA $2157\n"
"        LDA #$44\n"
"        STA $21AF\n"
"        LDA #$44\n"
"        STA $222F\n"
"        LDA #$44\n"
"        STA $22D7\n"
"\n"

    );
    return 1;
}


// ========================================================================
int main( const int nArg, const char *aArg[] )
{
    if( nArg > 1 )
    {
        if( strcmp( aArg[ 1 ], "-h"     ) == 0) return usage();
        if( strcmp( aArg[ 1 ], "-help"  ) == 0) return usage();
        if( strcmp( aArg[ 1 ], "--help" ) == 0) return usage();
        if( strcmp( aArg[ 1 ], "-?"     ) == 0) return usage();

    }

    if( nArg < 4 )
        return usage();

    if( nArg > 4 )
    {
        if( strcmp( aArg[4], "-compile" ) == 0 ) gbCompiledSprite = true;
        if( strcmp( aArg[4], "-code"    ) == 0 ) gbCompiledSprite = true;
        if( strcmp( aArg[4], "-data"    ) == 0 ) gbCompiledSprite = false;
    }

    gpFileName1 = aArg[1];
    gpFileName2 = aArg[2];

    FILE *pSrc1 = fopen( aArg[1], "rb" );
    FILE *pSrc2 = fopen( aArg[2], "rb" );
    int   nPage = atoi ( aArg[3] );

    if( !pSrc1 )                   printf( "ERROR: Couldn't open file 1: %s\n", aArg[1] );
    if( !pSrc2 )                   printf( "ERROR: Couldn't open file 1: %s\n", aArg[2] );
    if((nPage < 1) || (nPage > 2)) printf( "ERROR: DHGR Page must be 1 or 2\n" );

    if( pSrc1 && pSrc2 && (nPage >= 1) && (nPage <= 2) )
    {
        fread( aFrame1, 1, _16K, pSrc1 );
        fread( aFrame2, 1, _16K, pSrc2 );
        delta( aFrame1, aFrame2, nPage );
    }

    fclose( pSrc2 );
    fclose( pSrc1 );

    return 0;
}

