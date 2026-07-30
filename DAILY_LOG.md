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
