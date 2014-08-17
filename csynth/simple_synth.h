#ifndef __SIMPLE_SYNTH
#define __SIMPLE_SYNTH

#define INTTIME 

#ifdef INTTIME
#include <limits.h>
typedef long syn_time;
#define TOMORROW LONG_MAX
#else
typedef double syn_time;
#define TOMORROW INFINITY
#endif


typedef double syn_result;

typedef double waveform(double);

typedef struct {
    void *next;
    waveform *wave;
    syn_time start, stop;
    double pitch, vol;
} generator;

typedef struct {
    generator *buf;
    int size, used;
} gen_pool;

typedef struct {
    gen_pool active, queue;
    syn_time time, tick, hertz, next_rehash;
    double vol;
} synth;

double value ( generator *gen, syn_time t );

int pool_alloc ( gen_pool *pool, int size );
int pool_free ( gen_pool *pool );
int add_to_pool ( gen_pool *pool, generator *gen );
int del_from_pool ( gen_pool *pool, int n );
int clear_pool ( gen_pool *pool, syn_time t );
double pool_value ( gen_pool *pool, syn_time t );
int pool_move_ready (gen_pool *dst, gen_pool *src, syn_time t);
syn_time pool_sync_time ( gen_pool *ends, gen_pool *starts );
int synth_setup (synth *S, int size, double hertz, double vol);
int synth_avail ( synth *S);

int synth_add ( synth *S, generator *gen );
int synth_read ( synth *S, double *buf, int len );

int synth_tick (synth *S, double *result);
int synth_run ( synth *S, double *buf, int len );

void debug_generator (FILE *fd, generator *gen);
void debug_pool (FILE *fd, gen_pool *pool);
void debug_synth (FILE *fd, synth *S);

#endif
