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
#define DOPT_OPTIONAL  0
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
    double debug = 0;
    double play = 0;
    FILE *output = stdout;
    char cmdbuf[1024];

    char inbuf[INBUF];
    syn_result outbuf[OUTBUF];

    double_opt options[] = {
        { "-s", DOPT_HASARG, &size },
        { "-h", DOPT_HASARG, &hertz },
        { "-v", DOPT_HASARG, &vol },
        { "-d", DOPT_OPTIONAL, &debug },
        { "-p", DOPT_OPTIONAL, &play },
        { NULL, 0, NULL }
    };

    err = double_parse( options, argv );
    if (err < 0) {
        fprintf( stderr, "Bad options, result=%d\n", err );
        return 1;
    };

    synth_setup( &syn, (int) size, hertz, 2*1000*1000*1000 * vol);
    if (debug) debug_synth( stderr, &syn );

    if (play) {
        snprintf( cmdbuf, 1024, "play -t raw -e signed -b 32 -c 1 -r %0.0f -", 
            (double) syn.hertz);
        output = popen ( cmdbuf, "w" );
        if (output == NULL) {
            fprintf( stderr, "Failed to open play(1)\n" );
            return 5;
        };
    };
    
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

        err = synth_run( &syn, outbuf, OUTBUF );
        if (err < 0) {
            fprintf( stderr, "Synth fail.\n" );
            return 3;
        };

        if (debug) debug_synth( stderr, &syn );

        if (fwrite( outbuf, sizeof(syn_result), err, output ) != (unsigned) err) {
            fprintf( stderr, "Error writing to file\n" );
            return -6;
        };
    } while (!eof || !synth_empty( &syn )); /* end main loop */

    pclose( output );

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


