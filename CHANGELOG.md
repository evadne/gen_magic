# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][1], and this project adheres to [Semantic Versioning][2].

[1]: https://keepachangelog.com/en/1.0.0/
[2]: https://semver.org/spec/v2.0.0.html

## Unreleased

None

## 1.1.1

### Changed

- Revised `CC` assignment so compilers such as `clang` can be used

## 1.1.0

### Changed

- Added pool implementation
- Fixed deprecation warning for `:erlang.now/0`

## 1.0.5

### Changed

- Added further test support for Alpine and Debian Linux

## 1.0.4

### Changed

- Fixed startup timing issues and message handling
- Due to how the Port is set up, libMagic output may be mixed with the “ok” line

## 1.0.3

### Changed

- Fixed mix.exs inclusion in Hex package

## 1.0.2

### Changed

- Do not compile magic for testing
- Removed magic compilation from Makefile for testing

## 1.0.1

### Added

- Added support for process recycling (evadne).
- Added documentation (evadne).

### Changed

- Replaced GenServer with `:gen_statem` (evadne).
  - Changed API; added support for customisation.

- Refined tests and other aspects of the library (evadne).

## 0.20.83 (Legacy)

### Added

- Soak testing script (devstopfix)

### Changed

- Replaced Erlexec usage with Port (devstopfix)

## 0.0.1 (Legacy)

### Added

- Initial Elixir wrapper with Erlexec (evadne)
- Initial C program (evadne)
