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

## Day 6 - Tue Aug 4

Read Anderson 4.14 (Prandtl-Meyer expansion) and 4.15 (shock-expansion
theory).

The contrast with Day 5 is the whole point. Flow turning into itself
compresses through a single shock and loses total pressure. Flow
turning away from itself expands through a fan of infinitely many
infinitesimal Mach waves, each generating zero entropy, so p0 is
conserved exactly. Compression can concentrate into a discontinuity;
expansion cannot.

Built prandtlMeyer.m with three modes: forward M -> nu and mu,
inverse nu -> M via fzero, and expansion mode taking M1 plus a turn
angle and returning the full downstream state. p02_p01 is hardcoded
to 1 because there is no loss to compute. Property ratios go through
the stagnation values, since p0 and T0 are both constant across the
fan.

nu has a hard ceiling of 130.45 deg for gamma = 1.4 as M -> Inf, so
a flow at M1 can only turn nu_max - nu(M1). The function errors with
all three numbers rather than returning garbage.

validation/prandtlMeyer_check.m: max error 0.0005% against the table,
the best of any solver so far since nu(M) is pure arctangents with no
fractional powers. Round-trip 6.75e-14 over 1900 points. Additivity
test passes at exactly 0.00e+00 - turning 10 then 20 gives the same
M2 as turning 30 in one step, confirming nu is a state function.

At M = 2 turning 20 deg: M2 = 2.83, p2/p1 = 0.275, p02/p01 = 1.
Static pressure falls to 27% and nothing is lost - that drop is
conversion to kinetic energy, not loss.

Confusing / to revisit:
- There was a lot of geomtry involved in expansion wave theory which can be overwhelming while trying to also understand a lot of new concepts, so I will definitely need to revisit a lot of the different geometric solutions and also the way of identifying specific angles.
 
## Day 7 - Thu Aug 6

Read Anderson 4.6, 4.7, 4.12 and Farokhi 6.10-6.12, 6.14, 6.16.

Built studies/inletRecovery.m - first script that is an argument
rather than a solver. Chains obliqueShock and normalShock to compute
total pressure recovery for external compression inlets at Mach 2.

Results: pitot 0.7209, one 10 deg ramp 0.8662, two ramps 0.9549,
three 8 deg ramps 0.9765.

The insight is where the gain comes from. The oblique shocks
themselves cost almost nothing - 0.8% each in the 3-ramp case. What
they buy is a cheap terminal normal shock: at M = 1.13 it costs
0.2%, versus 28% at M = 2.0. The ramps exist to set up the normal
shock, not to do the compression.

Diminishing returns are sharp: +20%, +12%, +3%. That is why real
inlets stop at two or three ramps.

My 0.9765 beats the MIL-E-5008B standard of 0.9250, which is not a
better inlet - it is an inviscid model missing ramp friction,
boundary layer bleed, subsonic diffuser loss, and cowl lip loss.
The gap is roughly the size of what I left out.

Figure: figures/inlet_recovery.png, recovery vs M0 for all four
configs against the MIL standard. Each fixed-geometry curve ends
where its shocks detach, which shows the variable geometry
requirement visually.

Chapter 4 complete.

Confusing / to revisit:
- Here's that as a log entry:

Confusing / to revisit:
- I can compute recovery for a ramp system but I do not have a clear
  physical picture of the hardware. The code treats a "ramp" as an
  abstract deflection angle. What is the actual geometry? On the SR-71
  it is a translating conical spike; on Concorde it is hinged flat
  plates in a rectangular duct. How does a 10 degree deflection map to
  a physical surface, and where does the cowl lip sit relative to the
  shocks?
- Related: what is actually different between external, mixed, and
  internal compression as built objects, not as shock diagrams? I
  understand mixed compression puts some shocks inside the cowl, but
  not what that looks like or why it makes unstart a risk.
- Look at cutaway drawings of the SR-71 and Concorde inlets and trace
  the shock structure onto the real geometry.

## Day 8 - Mon Aug 10

Read Anderson 5.1-5.3, quasi-1D flow and the area-Mach relation.

Built areaMach.m. Forward gives A/A* from M; inverse solves back with
a 'sub', 'sup', or 'both' branch. The relation has a minimum of 1 at
M = 1 and rises on both sides, so every ratio above 1 has two roots.

The hard part is the sonic point. At M = 1 the curve is flat, so the
derivative vanishes and root-finding is ill-conditioned. Three
defences: short-circuit to an exact answer at ratio = 1, anchor both
brackets at exactly 1 so neither search can cross into the other
branch, and grow the outer brackets adaptively so extreme area ratios
still bracket properly. Verified to A/A* = 5e4.

The physical point: geometry gives you A/A* but not which root you
are on. Same nozzle, exit ratio 1.6875, could be running at M = 0.372
or M = 2.000. Back pressure decides, not the hardware. Resolving that
is tomorrow's job.

validation/areaMach_check.m: max 0.0033% vs Appendix A, round-trips
at 1e-14 on both branches, and exact 0.000e+00 agreement with the
A_Astar field in isentropic.m over 199 points - two independent
implementations of the same relation matching bit for bit.

Confusing / to revisit:
- The area-velocity relation still surprises me. Subsonic flow speeds up
  in a converging duct, which matches intuition - squeeze a hose, water
  goes faster. But supersonic flow speeds up in a DIVERGING duct, and
  the same duct that accelerates one decelerates the other. The sign
  flips at M = 1.
- I can see it in the algebra: dA/A = (M^2 - 1) dV/V, so the sign of
  (M^2 - 1) controls everything. What I want is the physical picture.
  The answer is in the mass flow, rho*A*V = constant. When you
  accelerate a flow, density drops. Below M = 1 density drops slower
  than velocity rises, so area must shrink. Above M = 1 density drops
  FASTER than velocity rises, so area must grow just to keep mass flow
  constant. M = 1 is exactly the crossover where the two effects
  balance.
- So the diverging section of a nozzle is not pushing the flow. It is
  giving the expanding gas room. That still does not feel intuitive and
  I want to sit with it.
- To revisit: work out d(rho)/rho = -M^2 dV/V by hand and confirm that
  is where the M^2 comes from.

## Day 9 - Tue Aug 11

Read Anderson 5.4 and Farokhi 6.21, 6.23, 6.28, 6.29.

Built nozzleFlow.m - the biggest function in the toolkit. Takes an
area distribution, p0, and back pressure, and returns the operating
regime plus the full pressure, Mach, and stagnation pressure
distribution along the nozzle.

Six regimes: subsonic (not choked), choked-subsonic, shock-in-nozzle,
overexpanded, design, underexpanded. The classification comes from
three boundary pressure ratios the function computes from the area
ratio alone. For A_e/A_t = 2.0 those are 0.9372, 0.5134, 0.0939.

The hard part is shock-in-nozzle. The shock position is not given -
it has to be found by root-finding on the condition p_exit = p_b.
After the shock the flow has a new stagnation pressure AND a new
sonic reference area A*, and both have to be recomputed or the mass
flow stops balancing.

Three things I did not expect:
- The choking band is narrow (6% of pressure ratio) while the
  shock-in-nozzle band is wide (43%). That is why nozzle behaviour
  looks abrupt near choking and gradual after.
- Overexpanded, design, and underexpanded have IDENTICAL internal
  solutions. The difference is entirely outside the exit plane.
- Lowering back pressure marches the shock downstream continuously.
  It is one regime with a moving feature, not a set of discrete cases.

validation/nozzleFlow_check.m verifies against physics, not tables,
since no appendix tabulates this. Mass flow conserved to 1.84e-15 in
every regime including across the shock - that is the check that
would catch a bad A* recomputation. Shock solve reproduces pb to
6e-16 over 25 cases. Regime classification correct on both sides of
every boundary.

Figure: figures/nozzle_regimes.png - nozzle contour above, six
pressure distributions below, showing the shock marching downstream.

Confusing / to revisit:
- The A* recomputation after the shock is the part I understand least.
  Before the shock A* is the physical throat area. After the shock the
  flow is subsonic and never goes sonic again, so the new A* is a
  reference area that does not correspond to any real station in the
  nozzle. I coded it as As/areaMach(M2) and the mass flow check passes,
  so it is right, but I want the physical reasoning to be as solid as
  the arithmetic.
- Related: why does A* have to change at all? T0 is unchanged across
  the shock and the mass flow is unchanged, so what exactly is it that
  makes the downstream flow need a bigger sonic reference area? I think
  the answer is the p0 loss, but I want to see it fall out of the mass
  flow equation rather than take it on faith.
- The shock-in-nozzle regime being one continuous band rather than a
  set of cases still surprises me. I had been picturing discrete
  operating points, not a shock sliding down the nozzle as I turn a
  knob.
- To revisit: write out mdot in terms of p0, A*, and T0, and confirm
  that holding mdot and T0 fixed while dropping p0 forces A* up by
  exactly the factor 1/(p02/p01).

## Day 10 - Wed Aug 12

Project 2 wrap. Ran all six validation scripts, collected results.
Max errors: isentropic 0.0295%, normal shock 0.0315%, Prandtl-Meyer
0.0005%, area-Mach 0.0033%. Oblique shock and nozzle flow pass on
invariants since neither is tabulated.

Wrote docs/compressible_toolkit.md - scope, assumptions, function
reference, verification results, figures, and limitations. The
section I care most about is the distinction between verifying the
implementation and validating the model. The tables come from the
same equations I coded, so agreement proves the algebra is right,
not that the physics matches reality. Day 16's engine comparison is
the one that tests the model.

Tagged v1.0-compressible.

## Pause — Aug 15

Days 1–10 complete, Project 2 tagged v1.0-compressible. Traveling for Umrah
Aug 16–24; Day 11 not started.

Picking up at Day 11 (thrust and performance parameters, Farokhi Ch. 3) on
weekends starting September. Days 11–16 target one 3-hr session per weekend,
Project 1 wrap by mid-October.

Where I left off: nothing broken. All seven compressible functions pass their
validation scripts. Next action is reading Farokhi Ch. 3 and deriving the
uninstalled thrust equation from a control volume by hand.

Confusing / to revisit:
- Nothing outstanding from Block 2. Re-skim docs/compressible_toolkit.md before
  starting Day 11 to reload station numbering conventions.