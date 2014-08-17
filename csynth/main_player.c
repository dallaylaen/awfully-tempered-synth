#include <stdio.h>
#include <math.h>
#include <string.h>
#include <unistd.h>

#include "simple_synth.h"

typedef struct {
    char *name;
    int flags;
    double *value;
} double_opt;
#define DOPT_OPTINAL  0
#define DOPT_REQUIRED 1
#define DOPT_HASARG   2
int double_parse (double_opt *conf, char **argv);

#define INBUF 4096
#define OUTBUF 4096

int main (int argc, char **argv) {
    synth syn;
    double vol = 1;
    double size = 256;
    double hertz = 44100;
    int err = argc;
    int eof = 0;

    char inbuf[INBUF];
    syn_result outbuf[OUTBUF];

    double_opt options[] = {
        { "-s", DOPT_HASARG, &size },
        { "-h", DOPT_HASARG, &hertz },
        { "-v", DOPT_HASARG, &vol },
        { NULL, 0, NULL }
    };

    err = double_parse( options, argv );
    if (err < 0) {
        fprintf( stderr, "Bad options, result=%d\n", err );
        return 1;
    };

    synth_setup( &syn, (int) size, hertz, 2*1000*1000*1000 * vol);
    debug_synth( stderr, &syn );

    
    do {
        while (!eof && synth_avail( &syn ) ) {
            if (fgets (inbuf, INBUF, stdin) == NULL) {
                eof = 1;
                break;
            };
            err = synth_scanf( &syn, inbuf );
            if (err) {
                fprintf( stderr, "Wrong line (%d): %s\n", err, inbuf);
            };
        };

        debug_synth( stderr, &syn );

        err = synth_run( &syn, outbuf, OUTBUF );
        if (err < 0) {
            fprintf( stderr, "Synth fail.\n" );
            return 3;
        };

        write( 1, outbuf, err*sizeof(syn_result) );
        debug_synth( stderr, &syn );
    } while (!eof || !synth_empty( &syn )); /* end main loop */

    return 0;
};


int double_parse (double_opt *conf, char **argv) {
    double_opt *opt;
    int ret = 0;

    while (*argv != NULL) {
        opt = conf;
        while (opt->name != NULL) {
            if (strcmp( opt->name, *argv )) {
                opt++;
                continue;
            };

            /* Found! */
            opt->flags &= ~DOPT_REQUIRED; /* TODO rewrite this r/o */
            if ( opt->flags & DOPT_HASARG ) {
                argv++;
                if (*argv == NULL) {
                    return -1;
                };
                if (1 != sscanf( *argv, "%lf", opt->value )) {
                    return -2;
                }
                ret++;
            } else {
                *(opt->value) = 1;
                ret++;
            };
            break;
        };
        argv++;
    }; /* end while (argv) */
    /* TODO scan for missing required */

    return ret;
}


