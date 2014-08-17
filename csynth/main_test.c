#include <stdio.h>
#include <math.h>

#include "simple_synth.h"

#define POINTS 150
#define NOTES  3

int main (void) {
    synth syn;
    int err;
    syn_result buf[POINTS+1];
    double in_buf[NOTES * 4] = {
        0.5, 1, 3, 0.9,
        1, 1, 12, 0.1,
        2.5, 0.1, 10, 0.5
    };
    int i;

    buf[POINTS] = 1000*1000*1000; 
        /* This big value guards buf (so there's no overrun) */

    err = synth_setup( &syn, 256, 50, 1E5 );
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

    for (i = 0; i < POINTS+1; i++) {
        printf("%6ld ", (long) buf[i]);
        if (! ((i+1)%10) )
            printf("\n");
    };
    printf("\n");

    return 0;
};


