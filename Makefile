# Apprentice binary

CC = gcc
CFLAGS = -std=c99 -g -Wall -Wextra -Werror
LDFLAGS = -lm `pkg-config --libs libmagic 2>/dev/null || echo "-lmagic"`
HEADER_FILES = src
C_SOURCE_FILES = src/apprentice.c
OBJECT_FILES = $(C_SOURCE_FILES:.c=.o)
EXECUTABLE_DIRECTORY = priv
EXECUTABLE = $(EXECUTABLE_DIRECTORY)/apprentice

all: $(EXECUTABLE)

$(EXECUTABLE): $(OBJECT_FILES) $(EXECUTABLE_DIRECTORY)
	$(CC) $(OBJECT_FILES) -o $@ $(LDFLAGS)

$(EXECUTABLE_DIRECTORY):
	mkdir -p $(EXECUTABLE_DIRECTORY)

.o:
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -f $(EXECUTABLE) $(OBJECT_FILES) $(BEAM_FILES)
