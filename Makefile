
SHELL=/bin/bash
TESTS=$(shell find . -maxdepth 4 -type f -name "*_test.sh")
TEST_OUT=$(addsuffix .sh-run,$(basename $(TESTS)))


test: $(TEST_OUT)

%.sh-run: %.sh
	@chmod +x $<
	./$<

test-continously:
	@while [ 1 ]; do \
		make test; \
		sleep 2; \
		inotifywait -e modify -r . 2>/dev/null; \
		done;
