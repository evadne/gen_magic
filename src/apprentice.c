//
// The Sorcerer’s Apprentice
//
// To use this program, compile it with dynamically linked libmagic, as mirrored
// at https://github.com/file/file. You may install it with apt-get,
// yum or brew. Refer to the Makefile for further reference.
//
// This program is designed to run interactively as a backend daemon to the
// GenMagic library, and follows the command line pattern:
//
//     $ apprentice --database-file <file> --database-default
//
// Where each argument either refers to a compiled or uncompiled magic database,
// or the default database. They will be loaded in the sequence that they were
// specified. Note that you must specify at least one database.
//
// Communication is done over STDIN/STDOUT as binary packets of 2 bytes length
// plus X bytes payload, where the payload is an erlang term encoded with
// :erlang.term_to_binary/1 and decoded with :erlang.binary_to_term/1.
//
// Once the program is ready, it sends the `:ready` atom. The startup can fail
// for multiples reasons, and the program will exit accordingly:
// - 1: No database
// - 2: Missing/Bad argument
// - 3: Missing database
//
// Commands are sent to the program STDIN as an erlang term of `{Operation,
// Argument}`, and response of `{:ok | :error, Response}`.
//
// Invalid packets will cause the program to exit (exit code 4). This will
// happen if your Erlang Term format doesn't match the version the program has
// been compiled with, or if you send a command too huge.
//
// The program may exit with error codes 5 or 255 if something went wrong (such
// as error allocating terms, or if stdin is lost).
//
// Commands:
// {:file, path :: String.t()} :: {:ok, {type, encoding, name}} | {:error,
// :badarg} | {:error, {errno :: integer(), String.t()}}
// {:bytes, binary()} :: same as :file
// {:stop, reason :: atom()} :: exit 0

#include <arpa/inet.h>
#include <ei.h>
#include <errno.h>
#include <getopt.h>
#include <libgen.h>
#include <magic.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#define ERROR_OK 0
#define ERROR_NO_DATABASE 1
#define ERROR_NO_ARGUMENT 2
#define ERROR_MISSING_DATABASE 3
#define ERROR_BAD_TERM 4
#define ERROR_EI 5

// We use a bigger than possible valid command length (around 4111 bytes) to
// allow more precise errors when using too long paths.
#define COMMAND_LEN 8000
#define COMMAND_BUFFER_SIZE COMMAND_LEN + 1

#define MAGIC_FLAGS_COMMON (MAGIC_CHECK | MAGIC_ERROR)
magic_t magic_setup(int flags);

typedef char byte;

void setup_environment();
void setup_options(int argc, char **argv);
void setup_options_file(char *optarg);
void setup_options_default();
void setup_system();
int process_command(uint16_t len, byte *buf);
void process_file(char *path, ei_x_buff *result);
void process_bytes(char *bytes, int size, ei_x_buff *result);
size_t read_cmd(byte *buf);
size_t write_cmd(byte *buf, size_t len);
void error(ei_x_buff *result, const char *error);
void handle_magic_error(magic_t handle, int errn, ei_x_buff *result);
void fdseek(uint16_t count);

struct magic_file {
  struct magic_file *prev;
  struct magic_file *next;
  char *path;
};

static struct magic_file *magic_database;
static magic_t magic_mime_type;     // MAGIC_MIME_TYPE
static magic_t magic_mime_encoding; // MAGIC_MIME_ENCODING
static magic_t magic_type_name;     // MAGIC_NONE

int main(int argc, char **argv) {
  ei_init();
  setup_environment();
  setup_options(argc, argv);
  setup_system();

  ei_x_buff ok_buf;
  if (ei_x_new_with_version(&ok_buf) || ei_x_encode_atom(&ok_buf, "ready"))
    exit(ERROR_EI);
  write_cmd(ok_buf.buff, ok_buf.index);
  if (ei_x_free(&ok_buf) != 0)
    exit(ERROR_EI);

  byte buf[COMMAND_BUFFER_SIZE];
  uint16_t len;
  while ((len = read_cmd(buf)) > 0) {
    process_command(len, buf);
  }

  return 255;
}

int process_command(uint16_t len, byte *buf) {
  ei_x_buff result;
  char atom[128];
  int index, version, arity, termtype, termsize;
  index = 0;

  // Initialize result
  if (ei_x_new_with_version(&result) || ei_x_encode_tuple_header(&result, 2)) {
    exit(ERROR_EI);
  }

  if (len >= COMMAND_LEN) {
    error(&result, "badarg");
    return 1;
  }

  if (ei_decode_version(buf, &index, &version) != 0) {
    exit(ERROR_BAD_TERM);
  }

  if (ei_decode_tuple_header(buf, &index, &arity) != 0) {
    error(&result, "badarg");
    return 1;
  }

  if (arity != 2) {
    error(&result, "badarg");
    return 1;
  }

  if (ei_decode_atom(buf, &index, atom) != 0) {
    error(&result, "badarg");
    return 1;
  }

  if (strlen(atom) == 4 && strncmp(atom, "file", 4) == 0) {
    char path[4097];
    ei_get_type(buf, &index, &termtype, &termsize);

    if (termtype == ERL_BINARY_EXT) {
      if (termsize < 4096) {
        long bin_length;
        ei_decode_binary(buf, &index, path, &bin_length);
        path[termsize] = '\0';
        process_file(path, &result);
      } else {
        error(&result, "enametoolong");
        return 1;
      }
    } else {
      error(&result, "badarg");
      return 1;
    }
  } else if (strlen(atom) == 5 && strncmp(atom, "bytes", 5) == 0) {
    int termtype;
    int termsize;
    char bytes[51];
    ei_get_type(buf, &index, &termtype, &termsize);

    if (termtype == ERL_BINARY_EXT && termsize < 50) {
      long bin_length;
      ei_decode_binary(buf, &index, bytes, &bin_length);
      bytes[termsize] = '\0';
      process_bytes(bytes, termsize, &result);
    } else {
      error(&result, "badarg");
      return 1;
    }
  } else if (strlen(atom) == 4 && strncmp(atom, "stop", 4) == 0) {
    exit(ERROR_OK);
  } else {
    error(&result, "badarg");
    return 1;
  }

  write_cmd(result.buff, result.index);

  if (ei_x_free(&result) != 0) {
    exit(ERROR_EI);
  }
  return 0;
}

void setup_environment() { opterr = 0; }

void setup_options(int argc, char **argv) {
  const char *option_string = "f:";
  static struct option long_options[] = {
      {"database-file", required_argument, 0, 'f'},
      {"database-default", no_argument, 0, 'd'},
      {0, 0, 0, 0}};

  int option_character;
  while (1) {
    int option_index = 0;
    option_character =
        getopt_long(argc, argv, option_string, long_options, &option_index);
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
      exit(ERROR_NO_ARGUMENT);
      break;
    }
    }
  }
}

void setup_options_file(char *optarg) {
  if (0 != access(optarg, R_OK)) {
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

  struct magic_file *next = malloc(sizeof(struct magic_file));
  next->path = NULL;
  next->prev = magic_database;
  if (magic_database) {
    magic_database->next = next;
  }
  magic_database = next;
}

void setup_system() {
  magic_mime_encoding = magic_setup(MAGIC_FLAGS_COMMON | MAGIC_MIME_ENCODING);
  magic_mime_type = magic_setup(MAGIC_FLAGS_COMMON | MAGIC_MIME_TYPE);
  magic_type_name = magic_setup(MAGIC_FLAGS_COMMON | MAGIC_NONE);
}

magic_t magic_setup(int flags) {

  magic_t magic = magic_open(flags);
  struct magic_file *current_database = magic_database;
  if (!current_database) {
    exit(ERROR_NO_DATABASE);
  }

  while (current_database->prev) {
    current_database = current_database->prev;
  }
  while (current_database) {
    magic_load(magic, current_database->path);
    current_database = current_database->next;
  }
  return magic;
}

void process_bytes(char *path, int size, ei_x_buff *result) {
  const char *mime_type_result = magic_buffer(magic_mime_type, path, size);
  const int mime_type_errno = magic_errno(magic_mime_type);

  if (mime_type_errno > 0) {
    handle_magic_error(magic_mime_type, mime_type_errno, result);
    return;
  }

  const char *mime_encoding_result =
      magic_buffer(magic_mime_encoding, path, size);
  int mime_encoding_errno = magic_errno(magic_mime_encoding);

  if (mime_encoding_errno > 0) {
    handle_magic_error(magic_mime_encoding, mime_encoding_errno, result);
    return;
  }

  const char *type_name_result = magic_buffer(magic_type_name, path, size);
  int type_name_errno = magic_errno(magic_type_name);

  if (type_name_errno > 0) {
    handle_magic_error(magic_type_name, type_name_errno, result);
    return;
  }

  ei_x_encode_atom(result, "ok");
  ei_x_encode_tuple_header(result, 3);
  ei_x_encode_binary(result, mime_type_result, strlen(mime_type_result));
  ei_x_encode_binary(result, mime_encoding_result,
                     strlen(mime_encoding_result));
  ei_x_encode_binary(result, type_name_result, strlen(type_name_result));
  return;
}

void handle_magic_error(magic_t handle, int errn, ei_x_buff *result) {
  const char *error = magic_error(handle);
  ei_x_encode_atom(result, "error");
  ei_x_encode_tuple_header(result, 2);
  long errlon = (long)errn;
  ei_x_encode_long(result, errlon);
  ei_x_encode_binary(result, error, strlen(error));
  return;
}

void process_file(char *path, ei_x_buff *result) {
  const char *mime_type_result = magic_file(magic_mime_type, path);
  const int mime_type_errno = magic_errno(magic_mime_type);

  if (mime_type_errno > 0) {
    handle_magic_error(magic_mime_type, mime_type_errno, result);
    return;
  }

  const char *mime_encoding_result = magic_file(magic_mime_encoding, path);
  int mime_encoding_errno = magic_errno(magic_mime_encoding);

  if (mime_encoding_errno > 0) {
    handle_magic_error(magic_mime_encoding, mime_encoding_errno, result);
    return;
  }

  const char *type_name_result = magic_file(magic_type_name, path);
  int type_name_errno = magic_errno(magic_type_name);

  if (type_name_errno > 0) {
    handle_magic_error(magic_type_name, type_name_errno, result);
    return;
  }

  ei_x_encode_atom(result, "ok");
  ei_x_encode_tuple_header(result, 3);
  ei_x_encode_binary(result, mime_type_result, strlen(mime_type_result));
  ei_x_encode_binary(result, mime_encoding_result,
                     strlen(mime_encoding_result));
  ei_x_encode_binary(result, type_name_result, strlen(type_name_result));
  return;
}

// Adapted from https://erlang.org/doc/tutorial/erl_interface.html
// Changed `read_cmd`, the original one was buggy given some length (due to
// endinaness).
// TODO: Check if `write_cmd` exhibits the same issue.
size_t read_exact(byte *buf, size_t len) {
  int i, got = 0;

  do {
    if ((i = read(0, buf + got, len - got)) <= 0) {
      return (i);
    }
    got += i;
  } while (got < len);

  return (len);
}

size_t write_exact(byte *buf, size_t len) {
  int i, wrote = 0;

  do {
    if ((i = write(1, buf + wrote, len - wrote)) <= 0)
      return (i);
    wrote += i;
  } while (wrote < len);

  return (len);
}

size_t read_cmd(byte *buf) {
  int i;
  if ((i = read(0, buf, sizeof(uint16_t))) <= 0) {
    return (i);
  }
  uint16_t len16 = *(uint16_t *)buf;
  len16 = ntohs(len16);

  // Buffer isn't large enough: just return possible len, without reading.
  // Up to the caller of verifying the size again and return an error.
  // buf left unchanged, stdin emptied of X bytes.
  if (len16 > COMMAND_LEN) {
    fdseek(len16);
    return len16;
  }

  return read_exact(buf, len16);
}

size_t write_cmd(byte *buf, size_t len) {
  byte li;

  li = (len >> 8) & 0xff;
  write_exact(&li, 1);

  li = len & 0xff;
  write_exact(&li, 1);

  return write_exact(buf, len);
}

void error(ei_x_buff *result, const char *error) {
  ei_x_encode_atom(result, "error");
  ei_x_encode_atom(result, error);
  write_cmd(result->buff, result->index);

  if (ei_x_free(result) != 0)
    exit(ERROR_EI);
}

void fdseek(uint16_t count) {
  int i = 0;
  while (i < count) {
    getchar();
    i += 1;
  }
}
