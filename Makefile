# Apprentice binary

ERL_EI_INCLUDE:=$(shell  erl -eval 'io:format("~s", [code:lib_dir(erl_interface, include)])' -s init stop -noshell | head -1)
ERL_EI_LIB:=$(shell  erl -eval 'io:format("~s", [code:lib_dir(erl_interface, lib)])' -s init stop -noshell | head -1)
CFLAGS = -std=c99 -g -Wall -Werror
CPPFLAGS = -I$(ERL_EI_INCLUDE)
LDFLAGS = -L$(ERL_EI_LIB)
LDLIBS = -lpthread -lei -lm -lmagic
PRIV = priv/
RM = rm -Rf

all: priv/apprentice

priv/apprentice: src/apprentice.c
	mkdir -p priv
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $^ $(LDLIBS) -o $@

clean:
	$(RM) $(PRIV)

.PHONY: clean
