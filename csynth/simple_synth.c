#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdio.h>

#include "simple_synth.h"

double value ( generator *gen, syn_time t ) {
    return gen->vol * gen->wave( 2*M_PI*gen->pitch * ( t - gen->start ) );
};

int pool_alloc ( gen_pool *pool, int size ) {
    pool->buf = (generator *) malloc( size * sizeof(generator) );
    if (pool->buf == NULL) {
        return -1;
    };
    pool->size = size;
    pool->used = 0;
    return 0;
};

int pool_free ( gen_pool *pool ) {
    if (pool->size == 0)
        return -1;
    free( pool->buf );
    pool->size = 0;
    return 0;
};

int add_to_pool ( gen_pool *pool, generator *gen ) {
    if (pool->used >= pool->size) {
        return -1;
    };

    memcpy(pool->buf + pool->used, gen, sizeof(generator));
    pool->used++;
    return 0;
};

int del_from_pool ( gen_pool *pool, int n ) {
    if (n >= pool->used)
        return -1;

    pool->used--;
    if (n == pool->used)
        return 0;
    memcpy( pool->buf + n, pool->buf + pool->used, sizeof(generator));
    return 0;
};

int clear_pool ( gen_pool *pool, syn_time t ) {
    int res;
    int i;

    for (i = 0; i < pool->used; i++ ) {
        if (pool->buf[i].stop <= t) {
            del_from_pool( pool, i );
            res++;
            i--; /* go back - topo was copied here */
        };
    };
    return res;
};

double pool_value ( gen_pool *pool, syn_time t ){
    double val = 0;
    int i;

    for (i = 0; i < pool->used; i++ ) {
        val += value( pool->buf + i, t );
    };
    return val;
};

int pool_move_ready (gen_pool *dst, gen_pool *src, syn_time t) {
    int res = 0;
    int err = 0;
    int i;

    /* TODO handle error!!! */
    for (i = 0; i < src->used; i++ ) {
        if (src->buf[i].start <= t) {
            if (add_to_pool(dst, src->buf+i)) {
                err--;
            } else {
                del_from_pool(src, i);
                res ++;
                i--; /* go back - top was copied here */
            };
        };
    };

    return err ? err : res;
};

syn_time pool_sync_time ( gen_pool *ends, gen_pool *starts ) {
    syn_time val = TOMORROW;
    int i;

    for (i = 0; i < ends->used; i++) {
        if (ends->buf[i].stop < val)
            val = ends->buf[i].stop;
    };
    for (i = 0; i < starts->used; i++) {
        if (starts->buf[i].start < val)
            val = starts->buf[i].start;
    };

    return val;
};

int synth_setup (synth *S, int size, double hertz, double vol) {
    if (pool_alloc( &(S->active), size ))
        return -1;
    if (pool_alloc( &(S->queue), 2*size))
        return -2;

    S->hertz = hertz;
    S->vol  = vol;
    S->tick = 1;
    S->time = 0;
    S->next_rehash = TOMORROW;
    return 0;
};

int synth_add ( synth *S, generator *gen ) {
    if ( gen->stop <= S->time )
        return -1; /* too late */
    if ( gen->start <= S->time ) {
        if (add_to_pool( &(S->active), gen ) )
            return -2;
    } else {
        /* normally we end up here - adding generator for future */
        if (add_to_pool( &(S->queue), gen ) )
            return -3;
    };
    
    if (S->next_rehash > gen->start)
        S->next_rehash = gen->start;
    return 0;
};

int synth_avail ( synth *S) {
    return S->queue.size - S->queue.used;
};

int synth_empty ( synth *S) {
    return !(S->queue.used + S->active.used);
};

int synth_tick (synth *S, syn_result *result) {
    int done = 0;

    *result = (syn_result) pool_value( &(S->active), S->time );
    
    S->time += S->tick;

    if (S->time < S->next_rehash)
        return 0;

    done += clear_pool( &(S->active), S->time );
    done += pool_move_ready ( &(S->active), &(S->queue), S->time );
    S->next_rehash = pool_sync_time( &(S->active), &(S->queue) );
    if (S->next_rehash < S->time)
        printf ("Oh bad\n");

    return done;
};

int synth_run ( synth *S, syn_result *buf, int len ) {
    int ret = 0;
    while (len) {
        ret++;
        if (synth_tick( S, buf ))
            break;
        buf++;
        len--;
    };
   
    return ret; 
};

int synth_read ( synth *S, double *buf, int len ) {
    generator gen;
    int ret = 0;
   
    gen.wave = sin;
    while (len >= 4) {
        if (!synth_avail(S))
            break;

        gen.start = (syn_time) (buf[0] * S->hertz);
        gen.stop  = (syn_time) (buf[1] * S->hertz);
        gen.pitch = buf[2] / S->hertz;
        gen.vol   = buf[3] * S->vol;

        if (synth_add( S, &gen )) {
            ret = -ret;
            break;
        };

        len -= 4;
        buf += 4;
        ret++;
    };

    return ret;
};

int synth_scanf ( synth *S, const char *spec ) {
    double buf[4];

    if (4!=sscanf(spec, "%lf%lf%lf%lf", buf, buf+1, buf+2, buf+3)) {
        return -1;
    };

    if (buf[0] >= buf[1])
        return -2;

    return synth_read( S, buf, 4 ) == 1 ? 0 : -4;
};

void debug_generator (FILE *fd, generator *gen) {
    fprintf (fd, "\t\tgen:0x%X(%0.3f[%0.3f,%0.3f])*%0.3f\n", 
        (unsigned) 0x8048470, gen->pitch, 
        (double) gen->start, (double) gen->stop, gen->vol);
};

void debug_pool (FILE *fd, gen_pool *pool) {
    int i;

    fprintf (fd, "\tpool: %u/%u:\n", pool->used, pool->size);
    for (i=0; i<pool->used; i++) {
        debug_generator(fd, pool->buf+i);
    };
};

void debug_synth (FILE *fd, synth *S) {
    double rehash = S->next_rehash == TOMORROW 
            ? INFINITY 
            : (double) S->next_rehash;
    fprintf (fd, "synth: %0.3fHz at %0.3f=%0.3fs, rehash at %0.3f=%0.3fs:\n", 
            (double) S->hertz, (double) S->time, (double) S->time / S->hertz, 
            rehash, rehash / S->hertz );
    debug_pool (fd, &( S->active ));
    debug_pool (fd, &( S->queue ));
};


