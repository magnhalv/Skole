#include "vslc.h"

static char *outfile = NULL;


static void
options ( int argc, char **argv )
{
    int32_t opt = 0;
    while ( opt != -1 )
    {
        opt = getopt ( argc, argv, "f:o:p" );
        switch ( opt )
        {
            case -1:    /* No more options */
                break;

            case 'p':
                peephole = true;
                break;

            case 'f':   /* Redirect input stream from file */{
                if ( freopen ( optarg, "r", stdin ) == NULL )
                {
                    fprintf (
                        stderr, "Could not open input file '%s'\n", optarg
                    );
                    exit ( EXIT_FAILURE );
                }
                                                             }
                break;

            case 'o':   /* Save filename, redirect stdout when src is ok */{
                outfile = ( STRDUP ( optarg ));
                                                                           }
                break;

            default:    /* Got some option we don't recognize */
                fprintf ( stderr,
                    "Usage: %s [-p] [-v #] [-f infile] [-o] outfile\n", argv[0]
                );
                exit ( EXIT_FAILURE );
        }

    }
}


int
main ( int argc, char **argv )
{
    options ( argc, argv );

    symtab_init ();
    yyparse();

#ifdef DUMP_TREES
    if ( (DUMP_TREES & 1) != 0 )
        node_print ( stderr, root, 0 );
#endif

    simplify_tree ( root );

#ifdef DUMP_TREES
    if ( (DUMP_TREES & 2) != 0 )
        node_print ( stderr, root, 0 );
#endif

    bind_names ( root );

    /* Parsing and semantics are ok, redirect stdout to file (if requested) */
    if ( outfile != NULL )
    {
        if ( freopen ( outfile, "w", stdout ) == NULL )
        {
            fprintf ( stderr, "Could not open output file '%s'\n", outfile );
            exit ( EXIT_FAILURE );
        }
        free ( outfile );
    }

    generate ( stdout, root );

    destroy_subtree ( root );
    symtab_finalize();

    exit ( EXIT_SUCCESS );
}
