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