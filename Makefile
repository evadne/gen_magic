# Apprentice binary

CC = gcc
CFLAGS = -std=c99 -g -Wall -Wextra -Werror `pkg-config --cflags libmagic`
LDFLAGS = -lm `pkg-config --libs libmagic`
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
