# Apprentice binary

CC = gcc
CFLAGS = -std=c99 -g -Wall -Werror
LDFLAGS = -lm -lmagic
HEADER_FILES = src
C_SOURCE_FILES = src/apprentice.c
OBJECT_FILES = $(C_SOURCE_FILES:.c=.o)
EXECUTABLE_DIRECTORY = priv
EXECUTABLE = $(EXECUTABLE_DIRECTORY)/apprentice

# Unit test custom magic file

MAGIC = file
PRIV_DIRECTORY = priv
TARGET_MAGIC = $(PRIV_DIRECTORY)/elixir.mgc
SOURCE_MAGIC = $(PRIV_DIRECTORY)/elixir

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
	cd $(PRIV_DIRECTORY); $(MAGIC) -C -m elixir; rm magic.mgc

clean:
	rm -f $(EXECUTABLE) $(OBJECT_FILES) $(BEAM_FILES)
	rm -f $(PRIV_DIRECTORY)/*mgc
