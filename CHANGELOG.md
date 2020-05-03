# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][1], and this project adheres to [Semantic Versioning][2].

[1]: https://keepachangelog.com/en/1.0.0/
[2]: https://semver.org/spec/v2.0.0.html

## [Unreleased]

### Added

- Added support for process recycling (evadne).
- Added documentation (evadne).

### Changed

- Replaced GenServer with `:gen_statem` (evadne).
  - Changed API; added support for customisation.

- Refined tests and other aspects of the library (evadne).

## [0.20.83]

### Added

- Soak testing script (devstopfix)

### Changed

- Replaced Erlexec usage with Port (devstopfix)

## 0.0.1

### Added

- Initial Elixir wrapper with Erlexec (evadne)
- Intiial C program (evadne)

[unreleased]: https://github.com/evadne/gen_magic/compare/develop
[0.20.83]: https://github.com/devstopfix/gen_magic/commit/7e27fd094cb462d26ba54fde0205a5be313d12da
