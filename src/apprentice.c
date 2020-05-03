//
// The Sorcerer’s Apprentice
//
// To use this program, compile it with dynamically linked libmagic, as mirrored
// at https://github.com/threatstack/libmagic. You may install it with apt-get, yum or brew.
// Refer to the Makefile for further reference.
//
// This program is designed to run interactively as a backend daemon to the GenMagic library,
// and follows the command line pattern:
//
//     $ apprentice --database-file <file> --database-default
//
// Where each argument either refers to a compiled or uncompiled magic database, or the default
// database. They will be loaded in the sequence that they were specified. Note that you must
// specify at least one database.
//
// Once the program starts, it will print info statements if run from a terminal, then it will
// print `ok`. From this point onwards, additional commands can be passed:
//  
//     file; <path>
//
// Results will be printed tab-separated, e.g.:
//
//     ok; application/zip	binary	Zip archive data, at least v1.0 to extract

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

#define USAGE "[--database-file <path/to/magic.mgc> | --database-default, ...]"
#define DELIMITER "\t"

#define ERROR_OK 0
#define ERROR_NO_DATABASE 1
#define ERROR_NO_ARGUMENT 2
#define ERROR_MISSING_DATABASE 3

#define ANSI_INFO   "\x1b[37m" // gray
#define ANSI_OK     "\x1b[32m" // green
#define ANSI_ERROR  "\x1b[31m" // red
#define ANSI_IGNORE "\x1b[90m" // red
#define ANSI_RESET  "\x1b[0m"

#define MAGIC_FLAGS_COMMON (MAGIC_CHECK|MAGIC_ERROR)
magic_t magic_setup(int flags);

void setup_environment();
void setup_options(int argc, char **argv);
void setup_options_file(char *optarg);
void setup_options_default();
void setup_system();
void process_line(char *line);
void process_file(char *path);
void print_info(const char *format, ...);
void print_ok(const char *format, ...);
void print_error(const char *format, ...);

struct magic_file {
  struct magic_file *prev;
  struct magic_file *next;
  char *path;
};

static struct magic_file* magic_database;
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
  opterr = 0;
}

void setup_options(int argc, char **argv) {
  const char *option_string = "f:";
  static struct option long_options[] = {
    {"database-file", required_argument, 0, 'f'},
    {"database-default", no_argument, 0, 'd'},
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
      case 'd': {
        setup_options_default();
        break;
      }
      case '?':
      default: {
        print_info("%s %s\n", basename(argv[0]), USAGE);
        exit(ERROR_NO_ARGUMENT);
        break;
      }
    }
  }
}

void setup_options_file(char *optarg) {
  print_info("Requested database %s", optarg);
  if (0 != access(optarg, R_OK)) {
    print_error("Missing Database");
    exit(ERROR_MISSING_DATABASE);
  }

  struct magic_file *next = malloc(sizeof(struct magic_file));
  size_t path_length = strlen(optarg) + 1;
  char *path = malloc(path_length);
  memcpy(path, optarg, path_length);
  next->path = path;
  next->prev = magic_database;
  if (magic_database) {
    magic_database->next = next;
  }
  magic_database = next;
}

void setup_options_default() {
  print_info("requested default database");

  struct magic_file *next = malloc(sizeof(struct magic_file));
  next->path = NULL;
  next->prev = magic_database;
  if (magic_database) {
    magic_database->next = next;
  }
  magic_database = next;
}

void setup_system() {
  magic_mime_encoding = magic_setup(MAGIC_FLAGS_COMMON|MAGIC_MIME_ENCODING);
  magic_mime_type = magic_setup(MAGIC_FLAGS_COMMON|MAGIC_MIME_TYPE);
  magic_type_name = magic_setup(MAGIC_FLAGS_COMMON|MAGIC_NONE);
}

magic_t magic_setup(int flags) {
  print_info("starting libmagic instance for flags %i", flags);

  magic_t magic = magic_open(flags);
  struct magic_file *current_database = magic_database;
  if (!current_database) {
    print_error("no database configured");
    exit(ERROR_NO_DATABASE);
  }

  while (current_database->prev) {
    current_database = current_database->prev;
  }
  while (current_database) {
    if (isatty(STDERR_FILENO)) {
      fprintf(stderr, ANSI_IGNORE);
    }
    if (!current_database->path) {
      print_info("loading default database");
    } else {
      print_info("loading database %s", current_database->path);
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
    exit(ERROR_OK);
  }
  if (1 != sscanf(line, "file; %[^\n]s", path)) {
    print_error("invalid commmand");
    return;
  }

  if (0 != access(path, R_OK)) {
    print_error("unable to access file");
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

  print_ok("%s%s%s%s%s", mime_type_result, DELIMITER, mine_encoding_result, DELIMITER, type_name_result);
}

void print_info(const char *format, ...) {
  if (!isatty(STDOUT_FILENO)) {
    return;
  }

  printf(ANSI_INFO "info; " ANSI_RESET);
  va_list arguments;
  va_start(arguments, format);
  vprintf(format, arguments);
  va_end(arguments);
  printf("\n");
}

void print_ok(const char *format, ...) {
  if (isatty(STDOUT_FILENO)) {
    printf(ANSI_OK "ok; " ANSI_RESET);
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
    fprintf(stderr, ANSI_ERROR "error; " ANSI_RESET);
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
