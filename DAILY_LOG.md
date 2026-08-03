# Daily Log

**Target:** Build a MATLAB toolkit that predicts jet engine
performance and compressible flow behavior, validated against
published data, so I can say in an interview: "I wrote a turbojet
cycle tool and checked its cruise TSFC against real engine data."

---

## Day 1 - Wed Jul 29

Setup day. Installed Git and MATLAB (full desktop version through
the Iowa State license). Created the propulsion-toolkit repo with
four folders: compressible, cycle, validation, docs. Added a
.gitignore for MATLAB autosave files.

Wrote gasProps.m, the first function in the toolkit. It returns
gamma, R, and cp for either air or combustion products. cp is
computed from gamma and R rather than hardcoded. Tested all four
cases, including a bad gas name, which threw the error correctly.

The point of this function is that every relation I write over the
next three weeks depends on gamma. Keeping it in one place means I
change it once, not in nine files.

Read Farokhi Ch. 2 - perfect gas, first law, entropy. Worked
problems from the chapter.

Confusing / to revisit:
- Entropy still feels like bookkeeping rather than something
  physical. I can compute it but I'm not sure I understand it.
  Want to see how it actually gets used on a shock tomorrow.
## Day 2 - Thu Jul 30

Read Anderson 3.1-3.4. Wrote isentropic.m with forward and inverse
modes. Forward returns T0/T, p0/p, rho0/rho, A/A* for a given Mach.
Inverse solves back for M - algebraic for the three property ratios,
fzero for A/A* since it has no closed form and two roots.

Wrote validation/isentropic_check.m against Appendix A. Max error
0.0295%, and that error is the table's rounding, not the code.
T0/T comes out exact because it needs no rounding. Inverse
round-trips to 1e-15.

Key thing from the reading: T0/T only needs adiabatic flow, but
p0/p and rho0/rho need isentropic. That's why a shock keeps T0
and loses p0.

Confusing / to revisit:
- I can get confused bt the notation at times, for exaple I am not 100% sure what the astrict* mean when it is on a T,P, or any of those values.

## Day 3 - Sat Aug 1

Read Anderson 3.6 (normal shock relations) and 3.7 (Hugoniot).
Derived M2(M1) by hand once.

Built normalShock.m - forward mode returns M2, p2/p1, T2/T1,
rho2/rho1, p02/p01 from M1. Inverse mode recovers M1 from any
of them using fzero. T2/T1 is computed from the perfect gas law
rather than written out separately.

validation/normalShock_check.m against Appendix B: max error
0.0315%, PASS. Added physical checks swept over 400 Mach numbers -
M2 always subsonic, p02/p01 always <= 1 and monotonically
decreasing. Those catch things a 9-row table can't.

The number that matters: p02/p01 = 0.72 at Mach 2, 0.33 at Mach 3.
A single normal shock throws away most of your total pressure by
Mach 3, which is why supersonic inlets use multiple oblique shocks.

Confusing / to revisit:
- Crazy how the higher the mach number before a shockwave, the smaller the mach number behind it becomes, it obviously is similar to how there is such a durastic drop in pressure, very hard to wrap my head around it at the moment. 

## Day 4 - Sun Aug 2

Read Anderson 3.8 (Rayleigh, heat addition), 3.9 (Fanno, friction),
and the 3.11 summary. Chapter 3 done.

Main idea: thermal choking. Adding heat to a subsonic flow drives M
toward 1, and at M = 1 the flow physically cannot accept more heat at
that mass flow. That's a hard ceiling on combustor heat release,
independent of how much fuel you're willing to burn. Same story for
friction in Fanno flow.

Built figures/fig_normalShock.m - first publication-quality figure.
M2 and p02/p01 vs M1, annotated at Mach 2, exported at 300 DPI.
The curves cross near M = 2.5: M2 flattens toward an asymptote
around 0.38 while p02/p01 keeps collapsing. That gap is the
argument for oblique-shock inlets.

Block 1 complete. Three solvers, two validation scripts, one figure.

Confusing / to revisit:
- This was a massive chapter with a lot of derivations and new concepts, will definitly to to revist those to understand them better, the method of solving for conditions after the shockwave when accounting for heat addition and/or friction is also a pretty difficult algorithm, so will need to revist the solution method for that also. 

## Day 5 - Mon Aug 3

Read Anderson 4.1-4.4. Oblique shocks are how supersonic flow
executes a turn: the wave tilts to angle beta so that the normal
velocity component is compressed while the tangential component
passes through unchanged, and the vector sum comes out rotated
by theta.

Built obliqueShock.m. Solves the theta-beta-M relation backwards
with fzero - theta(beta) is closed form, beta(theta) is not. The
bracket selects the branch: below the peak of theta(beta) gives the
weak root, above it gives the strong root. Once beta is known the
function calls normalShock.m on M1*sin(beta). No shock algebra
repeated.

Detachment: above theta_max no attached solution exists and the
function returns NaN with attached = false, rather than a wrong
number.

validation/obliqueShock_check.m - no appendix table exists for
oblique shocks, so this verifies against invariants instead:
reduction to the normal shock case at beta = 90 (exact, 0.00e+00),
both roots honouring the requested theta, weak root always lower
loss, strong root always subsonic behind, and theta_max against
published values to 0.03%.

At M = 2, theta = 20: weak gives beta = 53.4 and keeps 89% of p0,
staying supersonic at M2 = 1.21. Strong gives beta = 74.3, keeps
76%, goes subsonic. The strong solution is nearly a normal shock,
which is why its loss is close to the 72% normal shock value.

Confusing / to revisit:
- The method of solving in Anderson is a little new to me, its more like thermo where you need to know what table to look and when you can actually use table values and when you cannot, definitely need to get used to that and become more familiar with solving these type of problems, normal and oblique shock waves.