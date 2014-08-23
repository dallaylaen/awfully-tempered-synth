test: csynth test_perl
	echo OK

test_perl:
	prove -Ilib -r t/

csynth: csynth_unit
	gcc -Wall -Wextra -o bin/csynth csynth/simple_synth.c csynth/main_player.c -lm

csynth_unit: csynth_unit_run
	diff csynth/test.out.expected csynth/test.out
	rm csynth/test.out

csynth_unit_run:
	gcc -Wall -Wextra -o bin/csynth_test csynth/simple_synth.c csynth/main_test.c -lm
	bin/csynth_test >csynth/test.out

csynth_unit_update: csynth_unit_run
	echo REPLACING CSYNTH TEST OUTPUT
	mv csynth/test.out csynth/test.out.expected
