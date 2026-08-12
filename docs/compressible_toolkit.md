# Compressible Flow Toolkit

MATLAB solvers for one-dimensional and quasi-one-dimensional compressible
flow, verified against published tables.

Abdelrahman Abdelbaky — Aerospace Engineering, Iowa State University
Independent project, Summer 2026

---

## Scope

Seven functions covering isentropic flow, normal and oblique shocks,
Prandtl-Meyer expansion, the area–Mach relation, and converging-diverging
nozzle operation across all operating regimes. Every solver has a matching
verification script in `validation/`.

The toolkit is built to compose. `obliqueShock` calls `normalShock` on the
velocity component normal to the wave rather than reimplementing the shock
algebra. `nozzleFlow` calls `areaMach`, `isentropic`, and `normalShock` in
sequence. Nothing is duplicated, so a correction propagates everywhere.

---

## Assumptions

These hold throughout unless a function's help text says otherwise.

**Calorically perfect gas.** `cp` and `gamma` are constant with temperature.
Real air departs from this above roughly 1000 K, and combustion products
depart sooner. This is the limitation that matters most for the companion
cycle analysis work, where turbine inlet temperatures reach 1600 K and
beyond.

**Steady flow.** No unsteady wave motion, no starting transients.

**Adiabatic.** No heat transfer through walls. Stagnation temperature is
conserved except where heat is added deliberately.

**Inviscid.** No boundary layers, no skin friction, no separation. This is
why the inlet study computes recoveries above published design standards —
see below.

**Quasi-one-dimensional.** Properties are uniform across any cross-section.
Valid where area changes gradually; degrades in sharply contoured nozzles
and near the throat of a rapid contraction.

**Straight, thin waves.** Shocks are discontinuities of zero thickness.
Oblique shocks are straight and attached, with detachment flagged rather
than approximated.

---

## Functions

| Function | Purpose |
|---|---|
| `gasProps` | γ, R, cp for air or combustion products |
| `isentropic` | M ↔ T0/T, p0/p, ρ0/ρ, A/A*, forward and inverse |
| `normalShock` | M1 → M2, p2/p1, T2/T1, ρ2/ρ1, p02/p01, plus inverse |
| `obliqueShock` | θ–β–M relation, weak and strong roots, detachment |
| `prandtlMeyer` | ν(M), inverse, and expansion through a turn angle |
| `areaMach` | A/A* ↔ M on both branches, adaptive brackets |
| `nozzleFlow` | Full CD nozzle solution, all six operating regimes |

### Notes on individual solvers

**`isentropic`** — the A/A* inverse has two roots. The caller selects
`'sub'` or `'sup'`; the function does not guess.

**`normalShock`** — `T2_T1` is computed from the perfect gas law as
`(p2/p1)/(ρ2/ρ1)` rather than stored separately, so the three ratios
cannot drift out of consistency.

**`obliqueShock`** — θ(β) is closed form; β(θ) is not. The function
locates the peak of θ(β) first, then brackets below it for the weak root
and above it for the strong root. Above θ_max no attached solution exists;
the function returns `attached = false` with NaN fields rather than a
plausible wrong number.

**`prandtlMeyer`** — `p02_p01` is hardcoded to 1. An expansion fan is
isentropic by construction, so there is no loss to compute. ν has a
ceiling of 130.45° for γ = 1.4; over-turns are rejected with the available
angle reported.

**`areaMach`** — the sonic point is a minimum where the curve is flat, so
root-finding there is ill-conditioned. Three defences: an exact
short-circuit at A/A* = 1, brackets anchored at exactly M = 1 so neither
branch can cross into the other, and outer brackets that grow adaptively.
Verified to A/A* = 5×10⁴.

**`nozzleFlow`** — classification comes from three boundary pressure
ratios derived from the exit area ratio. In the shock-in-nozzle regime the
shock position is not given; it is found by root-finding on the condition
p_exit = p_back. After the shock both the stagnation pressure and the
sonic reference area A* must be recomputed, or mass flow stops balancing.

---

## Verification results

All checks run against Anderson's appendix tables where a table exists.

| Script | Reference | Max error | Result |
|---|---|---|---|
| `isentropic_check` | Appendix A | 0.0295 % | PASS |
| `normalShock_check` | Appendix B | 0.0315 % | PASS |
| `obliqueShock_check` | invariants | — | PASS |
| `prandtlMeyer_check` | P-M table | 0.0005 % | PASS |
| `areaMach_check` | Appendix A | 0.0033 % | PASS |
| `nozzleFlow_check` | invariants | — | PASS |

Tolerance for all table comparisons is 0.05 %.

**The errors are the tables', not the code's.** Anderson prints four
significant figures. Where a relation produces exact decimals — T0/T,
which is linear in M², and p2/p1 across a normal shock — the error is
identically zero. Where fractional powers are involved, the error is the
size of the book's rounding. The Prandtl-Meyer function scores best
because ν(M) is a combination of arctangents with no fractional powers at
all.

**Inverse solvers round-trip to machine precision:** 10⁻¹⁴ to 10⁻¹⁶
across every branch tested.

### Verification where no table exists

Oblique shocks and nozzle flow are not tabulated, so those scripts assert
physics instead of matching numbers.

`obliqueShock_check` confirms the general case reduces exactly to the
already-verified special case: at β = 90° it reproduces `normalShock` to
0.00×10⁰, bit for bit, which also confirms the two functions share one
implementation. It further checks that both roots return the deflection
requested, that the weak root always retains more stagnation pressure,
that the strong root is always subsonic behind, and that θ_max matches
published values to 0.03 %.

`nozzleFlow_check` confirms mass flow is conserved along the nozzle to
1.8×10⁻¹⁵ in every regime including across an internal shock — the check
that would expose a bad A* recomputation. It also confirms the shock
position solve reproduces the requested back pressure to 6×10⁻¹⁶ over 25
cases, that the shock moves monotonically downstream as back pressure
falls, that stagnation pressure drops exactly once and never rises, and
that regime classification is correct on both sides of every boundary.

### What this does and does not establish

These tables are generated from the same equations the code implements.
Agreement therefore **verifies the implementation** — it confirms the
algebra was transcribed correctly and the numerics are sound. It does not
**validate the model** against reality, because the assumptions above are
baked into both sides equally.

Validation against reality is a separate exercise, carried out in the
companion cycle analysis project by comparing predicted cruise TSFC
against published engine data.

---

## Figures

**`figures/normalShock_properties.png`** — downstream Mach number and
stagnation pressure ratio versus upstream Mach number. The two curves
cross near M = 2.5: M2 flattens toward an asymptote of about 0.378 while
p02/p01 continues to collapse. That divergence is the argument for
oblique-shock inlets.

**`figures/inlet_recovery.png`** — recovery versus flight Mach number for
pitot, one-ramp, two-ramp, and three-ramp external compression inlets,
against the MIL-E-5008B standard. Each fixed-geometry curve terminates
where its shocks detach, which is the variable-geometry requirement shown
rather than asserted.

**`figures/nozzle_regimes.png`** — nozzle contour above, pressure
distributions below for six back pressures through one fixed geometry.
The shock discontinuity is visible marching downstream as back pressure
falls.

---

## Selected result: inlet recovery

`studies/inletRecovery.m` chains the shock solvers to compute total
pressure recovery at M0 = 2.0.

| Configuration | π_d | vs pitot |
|---|---|---|
| Normal shock (pitot) | 0.7209 | — |
| 1 ramp, 10° | 0.8662 | +20.2 % |
| 2 ramps, 10° each | 0.9549 | +32.5 % |
| 3 ramps, 8° each | 0.9765 | +35.5 % |

The gain does not come from the oblique shocks themselves — each costs
under 1 % in the three-ramp case. It comes from what they set up. The
terminal normal shock sits at M = 1.13 instead of M = 2.0, where it costs
0.2 % instead of 28 %.

Returns diminish sharply: +20, then +12, then +3. That is why real inlets
stop at two or three ramps rather than pursuing the asymptote.

**The computed 0.9765 exceeds the MIL-E-5008B standard of 0.9250.** This
is not a better inlet. It is an inviscid model that omits ramp friction,
boundary-layer bleed, subsonic diffuser loss, and cowl-lip loss. The gap
between the two numbers is approximately the size of what the model leaves
out, and is the clearest illustration of the assumptions section above.

---

## Usage

```matlab
addpath(genpath(pwd)); savepath

S = isentropic(2.0);                    % all ratios at Mach 2
M = isentropic('p0_p', 7.8244);         % inverse

S = normalShock(3.0);                   % jump conditions
S = obliqueShock(2.0, 20);              % weak root, 20 deg wedge
S = obliqueShock(2.0, 20, 'strong');    % strong root
S = prandtlMeyer(2.0, 20);              % 20 deg expansion

x = linspace(0,1,401)';
A = 1 + (x-0.3).^2/0.49;
S = nozzleFlow(A, x, 100, 80);          % shock in nozzle
```

Run any verification script by name, e.g. `nozzleFlow_check`.

---

## Limitations and future work

The calorically perfect gas assumption is the binding one. Adding
temperature-dependent specific heats would extend validity to the
temperatures that matter in a real engine hot section.

The inviscid assumption means recoveries are optimistic. A boundary-layer
correction, or an empirical loss coefficient calibrated against the MIL
standard, would close most of that gap.

`nozzleFlow` treats the overexpanded case as internally identical to the
design case. That is correct for the flow inside the nozzle but ignores
the external shock structure and any separation inside the divergent
section, which occurs in real nozzles at high overexpansion.

Shock-expansion theory is implemented in neither function, but both
required pieces exist. Chaining `obliqueShock` and `prandtlMeyer` around a
diamond airfoil would yield lift and drag directly, including wave drag at
zero lift.