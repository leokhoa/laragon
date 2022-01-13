
[![Build status](https://ci.appveyor.com/api/projects/status/h401gvqery4wwa6p/branch/master?svg=true)](https://ci.appveyor.com/project/vladimir-kotikov/clink-completions/branch/master)
[![codecov](https://codecov.io/gh/vladimir-kotikov/clink-completions/branch/master/graph/badge.svg)](https://codecov.io/gh/vladimir-kotikov/clink-completions)

clink-completions
=================

Completion files to [clink](https://github.com/mridgers/clink) util

Notes
=====

Master branch of this repo contains all available completions. If you lack some functionality, post a feature request.

Some of completion generators in this bundle uses features from latest clink distribuition. If you get an error messages in console while using these completions, consider upgrading clink to latest version.

If this doesn't help, feel free to submit an issue.

Development and contribution
============================

The new flow is single `master` branch for all more or less valuable changes. The `master` should be clean and show nice history of project. The bugfixes are made and land directly into `master`.

The `dev` branch is intended to be used as a staging branch for current or incompleted work. The `dev` branch is unstable and contributors and users should never rely on it since its history can overwritten at the moment, some commits may be squashed, etc.

The feature development should be done in separate branch per feature. The completed features then should be merged into master as a single commit with meaningful description.

The PRs should be submitted from corresponding feature branches directly to `master`.

Requirements
============

These completions requires clink@0.4.3 or higher version

# Test

You will need `busted` package to be installed locally (to `lua_modules` directory). To install it
using Luarocks call `luarocks install --tree=lua_modules busted`. You might also want to install
`luacov` to get the coverage information.

After installing call `test.bat` from repo root and watch tests passing. That's it.
