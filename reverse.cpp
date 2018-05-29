/*
Compile:
    g++ -Wall -Wextra reverse.cpp -o reverse

Example:
    echo -e -n "abc\ndef\n" > abc.text
    reverse abc.text

    hexdump -C abc.text
    hexdump -C abc.text.reverse
*/

// Includes
    #include <stdio.h>  // printf()
    #include <stdint.h> // uint8_t
    #include <stdlib.h> // atoi()
    #include <string.h> // strcmp()

// Consts
    const int   _K = 1024;
    const int _64K = 64 * _K;

// Globals
    uint8_t aForward[ _64K ];
    uint8_t aReverse[ _64K ];

// Implementation
int main( const int nArg, const char *aArg[] )
{
    if( nArg > 1 )
    {
        const int MAX_FILE_NAME = 1024;

        const char *pExt = ".reverse";
        const char *pSrc = aArg[1];
        /* */ char  pDst[ MAX_FILE_NAME + 1 ];

        size_t nLenName = strlen( pSrc );
        size_t nLenExt  = strlen( pExt );

        if( nLenName + nLenExt >= MAX_FILE_NAME )
            return printf( "ERROR: Filename too long. Can't append: %s\n", pExt );

        strncpy( pDst +        0, pSrc, MAX_FILE_NAME );
        strncpy( pDst + nLenName, pExt, MAX_FILE_NAME );
        pDst[ MAX_FILE_NAME ] = 0;

        FILE *pRead  = fopen( pSrc, "rb"  );
        FILE *pWrite = fopen( pDst, "w+b" );

        if( !pRead )
            return printf( "ERROR: Couldn't open for reading: %s\n", pSrc );

        if( !pWrite )
            return printf( "ERROR: Couldn't open for writing: %s\n", pSrc );

        if( pRead && pWrite )
        {
            fseek( pRead, 0, SEEK_END );
            size_t nSize = ftell( pRead );
            fseek( pRead, 0, SEEK_SET );

            printf( "File Size: %llu\n", (unsigned long long) nSize );

            while( nSize > 0 )
            {
                size_t  nRead  = fread ( aForward, 1, _64K, pRead );

                uint8_t *beg = aForward;
                uint8_t *end = aForward + nRead;
                uint8_t *dst = aReverse + nRead - 1;

                while( beg < end )
                    *dst-- = *beg++;

                size_t nWrote = fwrite( aReverse, 1, nRead, pWrite );

                if( nRead != nWrote )
                    return printf( "ERROR: Wrote bytes (%llu) != Read bytes (%llu)\n", (unsigned long long)nWrote, (unsigned long long)nRead );

                nSize -= nRead;
            }
        }

        fclose( pRead  );
        fclose( pWrite );
    }

    return 0;
}
