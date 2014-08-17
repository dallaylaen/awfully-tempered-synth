#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdio.h>

#include "simple_synth.h"

double value ( generator *gen, double t ) {
    return gen->vol * gen->wave( gen->pitch * ( t - gen->start ) );
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

int clear_pool ( gen_pool *pool, double t ) {
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

double pool_value ( gen_pool *pool, double t ){
    double val = 0;
    int i;

    for (i = 0; i < pool->used; i++ ) {
        val += value( pool->buf + i, t );
    };
    return val;
};

int pool_move_ready (gen_pool *dst, gen_pool *src, double t) {
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

double pool_sync_time ( gen_pool *ends, gen_pool *starts ) {
    double val = INFINITY;
    int i;

    for (i = 0; i < ends->used; i++) {
        if (ends->buf[i].stop < val)
            val = ends->buf[i].stop;
    };
    for (i = 0; i < starts->used; i++) {
        if (starts->buf[i].start < val)
            val = ends->buf[i].start;
    };

    return val;
};

int synth_setup (synth *S, int size, double tick) {
    if (pool_alloc( &(S->active), size ))
        return -1;
    if (pool_alloc( &(S->queue), 2*size))
        return -2;

    S->tick = tick;
    S->time = 0;
    S->next_rehash = INFINITY;
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

int synth_tick (synth *S, double *result) {
    int done = 0;

    *result = pool_value( &(S->active), S->time );
    
    S->time += S->tick;

    if (S->time < S->next_rehash)
        return 0;

    done += clear_pool( &(S->active), S->time );
    done += pool_move_ready ( &(S->active), &(S->queue), S->time );
    S->next_rehash = pool_sync_time( &(S->active), &(S->queue) );

    return done;
};

void debug_generator (FILE *fd, generator *gen) {
    fprintf (fd, "\t\tgen:0x%X(%0.3f[%0.3f,%0.3f])*%0.3f\n", 
        (unsigned) gen->wave, gen->pitch, gen->start, gen->stop, gen->vol);
};

void debug_pool (FILE *fd, gen_pool *pool) {
    int i;

    fprintf (fd, "\tpool: %u/%u:\n", pool->used, pool->size);
    for (i=0; i<pool->used; i++) {
        debug_generator(fd, pool->buf+i);
    };
};

void debug_synth (FILE *fd, synth *S) {
    fprintf (fd, "synth: %0.3f+=%0.3f (rehash at %0.3f):\n", 
            S->time, S->tick, S->next_rehash);
    debug_pool (fd, &( S->active ));
    debug_pool (fd, &( S->queue ));
};


