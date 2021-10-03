# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.4.1] - 2021-10-03

### Changed

- [#26](https://github.com/sascha-wolf/knigge/issues/26): Fix upgrade building by tagging `bunt` as `runtime: false`

## [1.4.0] - 2021-03-26

### Added

- [#18](https://github.com/sascha-wolf/knigge/pull/18): Add `default` option to `use Knigge` ([@NickNeck][])
- [#22](https://github.com/sascha-wolf/knigge/pull/22): Ease contributing by adding a CONTRIBUTING guide and a PULL_REQUEST_TEMPLATE ([@sascha-wolf])

### Changed

- [#19](https://github.com/sascha-wolf/knigge/pull/19): Fix handling of callbacks without brackets ([@NickNeck])

## [1.3.0] - 2020-11-27

### Added

- [#15](https://github.com/sascha-wolf/knigge/pull/15): Add `--app` switch to `mix knigge.verify` ([@polvalente])

### Changed

- [#16](https://github.com/sascha-wolf/knigge/pull/16): Migrate CI from CircleCI to GitHub actions ([@sascha-wolf])


## [1.2.0] - 2020-09-07

### Changed

- Replaced the existence check with `mix knigge.verify`, see [here for details on why](https://hexdocs.pm/knigge/the-existence-check.html) ([@sascha-wolf])

## [1.1.1] - 2019-10-13

### Changed

- [#9](https://github.com/sascha-wolf/knigge/pull/9): Avoid warning when callback is defined several times ([@alexcastano])

## [1.1.0] - 2019-10-13

### Changed

- Renamed `delegate_at` to `delegate_at_runtime?` and changed it to accept a list of environment names instead of only a boolean;
  the default has been changed to `only: :test` ([@sascha-wolf])

[Unreleased]: https://github.com/sascha-wolf/knigge/compare/v1.4.1...main
[1.4.1]: https://github.com/sascha-wolf/knigge/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/sascha-wolf/knigge/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/sascha-wolf/knigge/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/sascha-wolf/knigge/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/sascha-wolf/knigge/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/sascha-wolf/knigge/compare/v1.0.4...v1.1.0

[@alexcastano]: https://github.com/alexcastano
[@NickNeck]: https://github.com/NickNeck
[@polvalente]: https://github.com/polvalente
[@sascha-wolf]: https://github.com/sascha-wolf
