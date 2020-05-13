# Apprentice binary

ERL_EI_INCLUDE:=$(shell  erl -eval 'io:format("~s", [code:lib_dir(erl_interface, include)])' -s init stop -noshell | head -1)
ERL_EI_LIB:=$(shell  erl -eval 'io:format("~s", [code:lib_dir(erl_interface, lib)])' -s init stop -noshell | head -1)
CFLAGS = -std=c99 -g -Wall -Werror
CPPFLAGS = -I$(ERL_EI_INCLUDE)
LDFLAGS = -L$(ERL_EI_LIB)
LDLIBS = -lpthread -lei -lm -lmagic
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
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $^ $(LDLIBS) -o $@

# Test case

$(TARGET_MAGIC): $(SOURCE_MAGIC)
	cd $(TEST_DIRECTORY); $(MAGIC) -C -m elixir

clean:
	$(RM) $(PRIV) $(BEAM_FILES)

.PHONY: clean
