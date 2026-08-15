# propulsion-toolkit

MATLAB tools for compressible flow and gas turbine cycle analysis.

Self-directed project, Summer 2026.
Abdelrahman Abdelbaky, Aerospace Engineering, Iowa State University.

## Layout

- `compressible/` - isentropic relations, shock solvers, nozzle flow
- `cycle/` - turbojet and turbofan performance models
- `validation/` - scripts reproducing published table data
- `docs/` - assumptions, function reference, results

## Status

Compressible flow toolkit complete ('v1.0-compressible,) 
- seven validation functions, six validation scripts, full documentation. 
Cycle analysis tool (turbojet, turbofan) in progress; resuming on weekends during the fall semester, God willing. 

**Project 2 — Compressible Flow Toolkit: complete** (tag `v1.0-compressible`)
Seven solvers, six verification scripts, all passing against Anderson's
appendix tables to within 0.05%. See
[`docs/compressible_toolkit.md`](docs/compressible_toolkit.md).

Next: gas turbine cycle analysis.