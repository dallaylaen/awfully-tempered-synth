#include <stdio.h>
#include <math.h>

#include "simple_synth.h"

int main ( int argc, char *argv[]) {
    generator gen;
    synth syn;
    int err;
    double buf[64000];
    int i;

    err = synth_setup( &syn, 256, 1.0/12 );
    if (err) {
        fprintf ( stderr, "Failed to initialize synth: %d", err);
        return 1;
    };

    gen.wave   = sin;
    gen.vol    = 10.0;
    gen.start  = 1.0;
    gen.stop   = 8.0;
    gen.pitch  = 440;

    synth_add( &syn, &gen );

    gen.start = 4.0;
    gen.stop = 6.0;
    gen.pitch = 1760;
    gen.vol = 100;

    synth_add( &syn, &gen );

    debug_synth( stdout, &syn );

    for (i = 0; i < 200; i++) {
        err = synth_tick( &syn, buf+i );
        if (err) { 
            debug_synth( stdout, &syn );
        } else {
            /* printf ( "t: %f\n", syn.time ); */
        };
    };

    for (i = 0; i < 200; i++) {
        printf("%0.3f ", buf[i]);
    };
    printf("\n");

    return 0;
};


