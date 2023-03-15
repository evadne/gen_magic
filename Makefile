CFLAGS = -std=c99 -g -Wall -Wextra -Werror
LDLIBS = -lm `pkg-config --cflags --libs libmagic 2>/dev/null || echo "-lmagic"`
PRIV = priv/
RM = rm -Rf

priv/apprentice: src/apprentice.c
	mkdir -p priv
	$(CC) $(CFLAGS) $(CPPFLAGS) $^ $(LDFLAGS) $(LDLIBS) -o $@

clean:
	$(RM) priv/apprentice

.PHONY: clean
