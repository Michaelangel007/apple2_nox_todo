/*
Synopsis:
    Compare two DHGR screens
    Find the bytes that are different per scanline
    Generate a compiled-sprite

Usage:
    frame_delta <pic1.dhgr> <pic2.dhgr> <hgrpage> [-compile]
*/

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

    bool gbCompiledSprite = 0;
    bool gbAppendSentinel = 1;


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
                    if( inSpan )
                    {
                        aSpanLen[ nSpans-1 ]++;
                        aSpanOff[ nSpans-1 ] =         offset + edge  ; // key
                        aSpanVal[ nSpans-1 ] = frame2[ offset + edge ]; // val
                    }
                    else
                    {
//printf( "    Found new span @ $%04X:$%02X\n", offset, edge );
                        aSpanAdr[ nSpans ] = base +  offset + edge;
                        aSpanOff[ nSpans ] =         offset + edge; // key
                        aSpanVal[ nSpans ] = frame2[ offset + edge ]; // val
                        aSpanLen[ nSpans ] = 1;

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
//printf( "    ; Span Src: $%04X, Len: $%02X\n", aSpanAdr[ nSpans-1 ], aSpanLen[ nSpans-1 ] );
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

    // printf( "    Spans: %d\n", nSpans );

    // Do span processing
    if( !gbCompiledSprite && nSpans )
    {
        // Negative = Now SW_AUXWROFF
        // 0 == End-of-Data
        printf( "        db %d, $%02X\n", isMain ? -nSpans : nSpans, (base >> 8) &0xFF );

        printf( "        db " );
        for( int iSpan = 0; iSpan < nSpans; iSpan++ )
            printf( "$%02X,", aSpanAdr[ iSpan ] & 0xFF );
        printf( " ; key\n" );

        printf( "        db " );
        for( int iSpan = 0; iSpan < nSpans; iSpan++ )
            printf( "$%02X,", aSpanVal[ iSpan ] & 0xFF );
        printf( " ; val\n" );

    }



    return nSpans
        ? 2 + nSpans*2 // 2 byte header, <key,val> per span
        : 0
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
    int nBytesA = 0;
    int nBytesM = 0;

    // Aux
    printf( "; === Aux ===\n" );
    if( gbCompiledSprite )
        printf( "        sta $c005          ; AUXWRON\n" );

    for( iAddr = 0; iAddr < _8K; iAddr += 256 )
        nBytesA += find_spans( frame1 + iAddr, frame2 + iAddr, iPage + iAddr, false );

    // Main
    printf( "; === Main ===\n" );
    if( gbCompiledSprite )
        printf( "        sta $c004          ; AUXWROFF\n" );

    for( iAddr = _8K; iAddr < _16K; iAddr += 256 )
        nBytesM += find_spans( frame1 + iAddr, frame2 + iAddr, iPage + iAddr - _8K, (iAddr == _8K) );

    if( gbCompiledSprite )
        printf( "        rts\n" );
    else
    if( nSpans )
        if( gbAppendSentinel )
        printf( "        db 0\n" ); // end of data

    printf( "; Total Bytes Aux.: %d\n", nBytesA );
    printf( "; Total Bytes Main: %d\n", nBytesM );
}


// ========================================================================
int usage()
{
    printf( "USAGE: frame_delta <pic1.dhgr> <pic2.dhgr> <hgrpage>\n" );
    return 1;
}


// ========================================================================
int main( const int nArg, const char *aArg[] )
{
    if( nArg < 4 )
        return usage();

    if( nArg > 4 )
        gbCompiledSprite = strcmp( aArg[4], "-compile" ) == 0;

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

