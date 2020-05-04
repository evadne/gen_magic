# Apprentice binary

CC = gcc
CFLAGS = -std=c99 -g -Wall -Werror
LDLIBS = -lm -lmagic
BEAM_FILES = _build/
PRIV = priv/
RM = rm -Rf

# Unit test custom magic file

MAGIC = file
TEST_DIRECTORY = test
TARGET_MAGIC = $(TEST_DIRECTORY)/elixir.mgc
SOURCE_MAGIC = $(TEST_DIRECTORY)/elixir

priv/apprentice: src/apprentice.c
	mkdir -p priv
	$(CC) $(CFLAGS) $(LDLIBS) $^ -o $@

# Test case

$(TARGET_MAGIC): $(SOURCE_MAGIC)
	cd $(TEST_DIRECTORY); $(MAGIC) -C -m elixir

clean:
	$(RM) $(PRIV) $(BEAM_FILES)

.PHONY: clean
