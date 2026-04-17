# octave-rf

S-parameter network utilities for GNU Octave, built so that IEEE P370 de-embedding
code can run independently in Octave while remaining compatible with MATLAB RF
Toolbox syntax.

## Status

🚧 **Work in progress.** Not yet released. APIs, file layout, and tests may change.

Do not depend on this package for production work yet. No installable tarball
exists; there is no `pkg install` URL to point at.

## MATLAB Compatibility

Designed for compatibility with MATLAB RF Toolbox syntax.  See the
[MATLAB Compatibility Guide](doc/MATLAB_COMPATIBILITY_GUIDE.md) for a
function-by-function comparison and portable-code examples.

## Validation

Cross-validated against MATLAB R2025b RF Toolbox — 36/36 tests pass to
floating-point precision. See the [validation report](doc/VALIDATION_REPORT_MATLAB_R2025b.md).

## License

BSD-3-Clause — see [COPYING](COPYING).
