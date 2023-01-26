
SHELL=bash
TESTS=$(wildcard *_test.sh)
TEST_OUT=$(addsuffix .tmp,$(basename $(notdir $(TESTS))))


test: $(TEST_OUT)

%.tmp: %.sh
	./$<

test-continously:
	@while [ 1 ]; do make test; sleep 2; inotifywait -e modify Makefile *.sh expendables/*; done;
