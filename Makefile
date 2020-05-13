# Apprentice binary

CC = gcc
ERL_EI_INCLUDE:=$(shell  erl -eval 'io:format("~s", [code:lib_dir(erl_interface, include)])' -s init stop -noshell | head -1)
ERL_EI_LIB:=$(shell  erl -eval 'io:format("~s", [code:lib_dir(erl_interface, lib)])' -s init stop -noshell | head -1)
CFLAGS = -std=c99 -g -Wall -Wextra -Werror -I$(ERL_EI_INCLUDE)
LDFLAGS = -L/usr/include/linux/ -L$(ERL_EI_LIB) -lm -lmagic -lei -lpthread
HEADER_FILES = src
C_SOURCE_FILES = src/apprentice.c
OBJECT_FILES = $(C_SOURCE_FILES:.c=.o)
EXECUTABLE_DIRECTORY = priv
EXECUTABLE = $(EXECUTABLE_DIRECTORY)/apprentice

# Unit test custom magic file

MAGIC = file
TEST_DIRECTORY = test
TARGET_MAGIC = $(TEST_DIRECTORY)/elixir.mgc
SOURCE_MAGIC = $(TEST_DIRECTORY)/elixir

# Target

all: $(EXECUTABLE) $(TARGET_MAGIC)

# Compile

$(EXECUTABLE): $(OBJECT_FILES) $(EXECUTABLE_DIRECTORY)
	$(CC) $(OBJECT_FILES) -o $@ $(LDFLAGS)

$(EXECUTABLE_DIRECTORY):
	mkdir -p $(EXECUTABLE_DIRECTORY)

.o:
	$(CC) $(CFLAGS) $< -o $@

# Test case

$(TARGET_MAGIC): $(SOURCE_MAGIC)
	cd $(TEST_DIRECTORY); $(MAGIC) -C -m elixir

clean:
	rm -f $(EXECUTABLE) $(OBJECT_FILES) $(BEAM_FILES)
