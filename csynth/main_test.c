#include <stdio.h>
#include <math.h>

#include "simple_synth.h"

#define POINTS 180
#define NOTES  3

int main ( int argc, char *argv[]) {
    synth syn;
    int err;
    double buf[POINTS+1];
    double in_buf[NOTES * 4] = {
        0.5, 1.5, 3, 1,
        1, 2, 12, 0.1,
        2.5, 2.6, 100, 0.5
    };
    int i;

    err = synth_setup( &syn, 256, 60, 1 );
    if (err) {
        fprintf ( stderr, "Failed to initialize synth: %d", err);
        return 1;
    };

    err = synth_read( &syn, in_buf, NOTES*4 );
    debug_synth( stdout, &syn );
    if ( err != NOTES ) {
        fprintf ( stderr, "Failed to read input, %d returned, %d expected\n",
                err, (int)NOTES);
        return 2;
    };

    for (i = 0; i < POINTS; i++) {
        err = synth_tick( &syn, buf+i );
        if (err) { 
            debug_synth( stdout, &syn );
        } else {
            /* printf ( "t: %f\n", syn.time ); */
        };
    };

    for (i = 0; i < POINTS; i++) {
        printf("%0.3f ", buf[i]);
        if (! ((i+1)%12) )
            printf("\n");
    };

    return 0;
};


