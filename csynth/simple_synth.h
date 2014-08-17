#ifndef __SIMPLE_SYNTH
#define __SIMPLE_SYNTH

typedef double waveform(double);
typedef struct {
    void *next;
    waveform *wave;
    double start, stop, pitch, vol;
} generator;

typedef struct {
    generator *buf;
    int size, used;
} gen_pool;

typedef struct {
    gen_pool active, queue;
    double time, tick, next_rehash;
} synth;

double value ( generator *gen, double t );
int pool_alloc ( gen_pool *pool, int size );
int pool_free ( gen_pool *pool );
int add_to_pool ( gen_pool *pool, generator *gen );
int del_from_pool ( gen_pool *pool, int n );
int clear_pool ( gen_pool *pool, double t );
double pool_value ( gen_pool *pool, double t );
int pool_move_ready (gen_pool *dst, gen_pool *src, double t);
double pool_sync_time ( gen_pool *ends, gen_pool *starts );
int synth_setup (synth *S, int size, double tick);
int synth_add ( synth *S, generator *gen );
int synth_tick (synth *S, double *result);

void debug_generator (FILE *fd, generator *gen);
void debug_pool (FILE *fd, gen_pool *pool);
void debug_synth (FILE *fd, synth *S);

#endif
