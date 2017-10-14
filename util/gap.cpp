/*
    Remove/Add Apple ][ HGR Screen holes
*/

// Includes
    #include <stdio.h>  // printf()
    #include <string.h> // memcpy()

// Consts
    const char  *EXTENSION    = ".gap";
    const size_t MAX_EXTE_LEN = strlen( EXTENSION );
    const size_t MAX_NAME_LEN = 256 - MAX_EXTE_LEN; // ".gap"
    const int    BUF_SIZE     = 0x2000; // 8K for HGR screen


// Globals
    bool   gbFileNameInvalid = false;
    bool   gbFileNameTooLong = false;
    size_t gnFileNameLength  = 0;

// ========================================================================
const char *GetExtension( const char *filename )
{
    ;;; gbFileNameInvalid = !filename;
    if( gbFileNameInvalid )
        return NULL;

    gnFileNameLength  = strlen( filename );
    const char *pHead = filename;
    const char *pTail = filename + gnFileNameLength;

    ;;; gbFileNameTooLong = (gnFileNameLength > MAX_NAME_LEN);
    if( gbFileNameTooLong )
        return NULL;

    while( pTail --> pHead )
    {
        if (*pTail == '.' )
            return pTail;
    }

    return NULL;
}


// Remove screen holes
// Assumes 8K image
// ========================================================================
void sub( const char *source, char *destination )
{
    const char *src = source;
    /* */ char *dst = destination;
    const char *end = src + BUF_SIZE;
   
    while( src < end )
    {
        memcpy( dst, src, 0x78 );
        src += 0x80;
        dst += 0x78;

        memcpy( dst, src, 0x78 );
        src += 0x80;
        dst += 0x78;
    }
}


// Add screen holes
// ========================================================================
void add( const char *source, char *destination )
{
    const char *src = source;
    /* */ char *dst = destination;
    const char *end = src + BUF_SIZE;

    while( src < end )
    {
        memcpy( dst, src, 0x78 );
        src += 0x78;
        dst += 0x80;

        memcpy( dst, src, 0x78 );
        src += 0x78;
        dst += 0x80;
    }    
}


// ========================================================================
int FileRead( const char *name, int size, char* buffer )
{
    size_t actual = size + 1;

    FILE *pFile = fopen( name, "rb" );
    if( pFile )
    {
        actual = fread( buffer, 1, size, pFile );
        fclose( pFile );
    }
    else
        printf( "ERROR: Couldn't open file: %s\n", name );

    int valid = (actual == size);
    return valid;
}


// ========================================================================
int FileWrite( const char *name, int size, char* buffer )
{
    size_t actual = size+1;

    FILE *pFile = fopen( name, "w+b" );
    if( pFile )
    {
        actual = fwrite( buffer, 1, size, pFile );
        fclose( pFile );
    }
    else
        printf( "ERROR: Couldn't open file: %s\n", name );

    int valid = (actual == size );
    return valid;
}


// ========================================================================
int main( const int nArg, const char *aArg[] )
{
    bool pack = true;
    int  iArg = 1;

    // gap foo
    if( nArg < 1 )
        return printf( "ERROR: Missing input file to remove/add screen holes\n" );

    // gap -d foo.gap
    if( nArg > 2 )
        iArg++;

    if( strcmp( aArg[ 1 ], "-d" ) == 0 )
        pack = false;

    const char *in_name = aArg[ iArg ];
    const char *in_ext  = GetExtension( in_name );
    /* */ char  in_buff[ BUF_SIZE ];

    char  out_name[ MAX_NAME_LEN + MAX_EXTE_LEN + 1 ]; // ".gap" + NULL
    char* out_ext = (char*) EXTENSION;
    char  out_buff[ BUF_SIZE ];

    if( gbFileNameInvalid )
        return printf( "ERROR: Missing filename\n" );

    if( gbFileNameTooLong )
        return printf( "ERROR: Filename too long: > %d\n", MAX_NAME_LEN );

    strncpy( out_name, in_name, MAX_NAME_LEN );

    if( in_ext )
        if( strcmp( in_ext, EXTENSION ) == 0 )
            pack = false;

    if( !in_ext )
    {
        if( pack )
            strncpy( out_name + gnFileNameLength, EXTENSION, MAX_EXTE_LEN );
    }

    printf( "Reading: %s ...\n", in_name );
    if( !FileRead( in_name, BUF_SIZE, in_buff ) )
        return printf( "ERROR: Couldn't read %d bytes from input file\n", BUF_SIZE );

    if( pack )
        sub( in_buff, out_buff );
    else
        add( in_buff, out_buff );

    printf( "Writing: %s ...\n", out_name );
    if( !FileWrite( out_name, BUF_SIZE - 512, out_buff ) )
        return printf( "ERROR:  Couldn't write %d bytes to output file\n", BUF_SIZE-512 );

    printf( "Done!\n" );

    return 0;
}

