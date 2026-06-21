# sml-prng build
#
#   make            build the test binary with MLton (default)
#   make test       build + run tests under MLton
#   make test-poly  run tests under Poly/ML (use-and-run; no link step)
#   make all-tests  run the suite under both compilers
#   make clean      remove build artifacts

MLTON      ?= mlton
POLY       ?= poly
BIN        := bin
LIBDIR     := lib/github.com/sjqtentacles/sml-prng
TEST_MLB   := test/test.mlb
SRCS       := $(wildcard $(LIBDIR)/*.sml $(LIBDIR)/*.sig $(LIBDIR)/*.mlb) \
              $(wildcard test/*.sml) $(TEST_MLB)

.PHONY: all test poly test-poly all-tests clean

all: $(BIN)/test-mlton

$(BIN)/test-mlton: $(SRCS) | $(BIN)
	$(MLTON) -output $@ $(TEST_MLB)

test: $(BIN)/test-mlton
	$(BIN)/test-mlton

# Poly/ML has no native .mlb support; the suite runs at top level and exits
# on its own, so we `use` the sources in dependency order.
poly test-poly:
	printf 'use "$(LIBDIR)/prng.sig";\nuse "$(LIBDIR)/prng.sml";\nuse "test/harness.sml";\nuse "test/support.sml";\nuse "test/test_streams.sml";\nuse "test/test_helpers.sml";\nuse "test/test_edge.sml";\nuse "test/entry.sml";\nuse "test/main.sml";\n' | $(POLY) -q --error-exit

all-tests: test test-poly

$(BIN):
	mkdir -p $(BIN)

clean:
	rm -f $(BIN)/test-mlton
