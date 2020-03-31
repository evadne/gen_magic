//
// (c) Evadne Wu, Faria Education Group / International Baccalaureate 2019
//
#include <errno.h>
#include <getopt.h>
#include <libgen.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <magic.h>

#define USAGE "--file <path/to/magic.mgc> [--file <path/to/custom.mgc> ...]"
#define DELIMINTER "\t"

#define ANSI_INFO  "\x1b[37m" // gray
#define ANSI_OK    "\x1b[32m" // green
#define ANSI_ERROR "\x1b[31m" // red
#define ANSI_IGNORE "\x1b[90m" // red
#define ANSI_RESET "\x1b[0m"

#define MAGIC_FLAGS_COMMON (MAGIC_CHECK|MAGIC_ERROR)
magic_t magic_setup(int flags);

void setup_environment();
void setup_options(int argc, char **argv);
void setup_options_file(char *optarg);
void setup_system();
void process_line(char *line);
void process_file(char *path);
void print_info(const char *format, ...);
void print_ok(const char *format, ...);
void print_error(const char *format, ...);

struct file {
  char *path;
  struct file *next;
};

static struct file* magic_database;
static magic_t magic_mime_type; // MAGIC_MIME_TYPE
static magic_t magic_mime_encoding; // MAGIC_MIME_ENCODING
static magic_t magic_type_name; // MAGIC_NONE

int main (int argc, char **argv) {
  setup_environment();
  setup_options(argc, argv);
  setup_system();
  printf("ok\n");
  fflush(stdout);

  char line[4096];
  while (fgets(line, 4096, stdin)) {
    process_line(line);
  }

  return 0;
}

void setup_environment() {
  // setbuf(stdout, NULL);
  opterr = 0;
}

void setup_options(int argc, char **argv) {
  const char *option_string = "f:";
  static struct option long_options[] = {
    {"file", required_argument, 0, 'f'},
    {0, 0, 0, 0}
  };

  int option_character;
  while (1) {
    int option_index = 0;
    option_character = getopt_long(argc, argv, option_string, long_options, &option_index);
    if (-1 == option_character) {
      break;
    }
    switch (option_character) {
      case 'f': {
        setup_options_file(optarg);
        break;
      }
      case '?':
      default: {
        print_info("%s %s\n", basename(argv[0]), USAGE);
        exit(1);
        break;
      }
    }
  }
}

void setup_options_file(char *optarg) {
  print_info("Magic Database: %s", optarg);
  if (0 != access(optarg, R_OK)) {
    print_error("no_database");
    exit(1);
  }
  struct file *next = malloc(sizeof(struct file));
  size_t path_length = strlen(optarg) + 1;
  char *path = malloc(path_length);
  memcpy(path, optarg, path_length);
  next->path = path;
  next->next = magic_database;
  magic_database = next;
}

void setup_system() {
  print_info("Starting System");
  magic_mime_encoding = magic_setup(MAGIC_FLAGS_COMMON|MAGIC_MIME_ENCODING);
  magic_mime_type = magic_setup(MAGIC_FLAGS_COMMON|MAGIC_MIME_TYPE);
  magic_type_name = magic_setup(MAGIC_FLAGS_COMMON|MAGIC_NONE);
}

magic_t magic_setup(int flags) {
  magic_t magic = magic_open(flags);
  struct file *current_database = magic_database;
  while (current_database) {
    if (isatty(STDERR_FILENO)) {
      fprintf(stderr, ANSI_IGNORE);
    }
    magic_load(magic, current_database->path);
    if (isatty(STDERR_FILENO)) {
      fprintf(stderr, ANSI_RESET);
    }
    current_database = current_database->next;
  }
  return magic;
}

void process_line(char *line) {
  char path[4096];

  if (0 == strcmp(line, "exit\n")) {
    exit(0);
  }

  if (1 != sscanf(line, "file; %[^\n]s", path)) {
    print_error("bad_path");
    return;
  }

  if (0 != access(path, R_OK)) {
    print_error("no_file");
    return;
  }

  process_file(path);
}

void process_file(char *path) {
  const char *mime_type_result = magic_file(magic_mime_type, path);
  const char *mime_type_error = magic_error(magic_mime_type);
  const char *mine_encoding_result = magic_file(magic_mime_encoding, path);
  const char *mine_encoding_error = magic_error(magic_mime_encoding);
  const char *type_name_result = magic_file(magic_type_name, path);
  const char *type_name_error = magic_error(magic_type_name);

  if (mime_type_error) {
    print_error(mime_type_error);
    return;
  }

  if (mine_encoding_error) {
    print_error(mine_encoding_error);
    return;
  }

  if (type_name_error) {
    print_error(type_name_error);
    return;
  }

  print_ok("%s%s%s%s%s", mime_type_result, DELIMINTER, mine_encoding_result, DELIMINTER, type_name_result);
}

void print_info(const char *format, ...) {
  if (!isatty(STDOUT_FILENO)) {
    return;
  }

  printf(ANSI_INFO "[INFO] " ANSI_RESET);
  va_list arguments;
  va_start(arguments, format);
  vprintf(format, arguments);
  va_end(arguments);
  printf("\n");
}

void print_ok(const char *format, ...) {
  if (isatty(STDOUT_FILENO)) {
    printf(ANSI_OK "[OK] " ANSI_RESET);
  } else {
    printf("ok; ");
  }

  va_list arguments;
  va_start(arguments, format);
  vprintf(format, arguments);
  va_end(arguments);
  printf("\n");
  fflush(stdout);
}

void print_error(const char *format, ...) {
  if (isatty(STDERR_FILENO)) {
    fprintf(stderr, ANSI_ERROR "[ERROR] " ANSI_RESET);
  } else {
    fprintf(stderr, "error; ");
  }

  va_list arguments;
  va_start(arguments, format);
  vfprintf(stderr, format, arguments);
  va_end(arguments);
  fprintf(stderr, "\n");
  fflush(stderr);
}
