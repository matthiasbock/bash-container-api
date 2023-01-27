
SHELL=bash
TESTS=$(wildcard *_test.sh)
TEST_OUT=$(addsuffix .run,$(basename $(notdir $(TESTS))))


test: $(TEST_OUT)

%.run: %.sh
	@chmod +x $<
	./$<

test-continously:
	@while [ 1 ]; do \
		make test; \
		sleep 2; \
		inotifywait -e modify Makefile *.sh expendables/*; \
		done;
