#include <stdio.h>
#include <math.h>
#include <string.h>

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


int main (int argc, char **argv) {
    synth syn;
    double vol = 1;
    double size = 256;
    double hertz = 44100;
    int err = argc;

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
    debug_synth( stdout, &syn );

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


