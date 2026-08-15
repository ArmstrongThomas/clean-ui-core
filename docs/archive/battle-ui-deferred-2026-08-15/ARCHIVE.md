# Deferred Clean UI Core battle architecture

Archived on 2026-08-15 after the Gen2 battle UI was removed from the active
product and deferred for a future rewrite.

This archive records the Core-side architecture that was tested during the
failed live battle attempt. It is design history only. It is not an active V3
contract, renderer, ownership policy, or implementation recipe.

The deferred attempt added or expanded:

- source-authored battle scene-frame and animation-object reconstruction;
- palette/background-effect handling and detached trainer/battler art;
- persistent battle ownership latching across transient state rebuilds;
- phase fallback labels and fixed upper-field/lower-dock sizing;
- 16:9, 9:16, and 10:9 battle presets and related layout invariants;
- battle-specific runtime and renderer regression fixtures.

The live result was not reliable beyond the battle intro. In particular, a
source refresh could rebuild or invalidate the battle state while the Clean
candidate was being prepared, allowing native UI to reappear or preventing
progression. Deterministic model, layout, and ownership tests did not prove
the official launcher path.

The active Core tree therefore returns to its committed baseline. The next
battle design pass must begin from the official host V3 seams and a new
ownership/composition model. It must not restore this renderer, latch, or
frame-extraction architecture piecemeal. Preserve the design goals only:
detached composition, explicit ownership, fixed field/dock envelopes, and
safe documented behavior when V3 data is missing.

Gen2 remains native/deferred for battle. Core continues to provide only the
shared committed presentation surface required by non-battle products; no
Core change here claims live battle support.

No host repository files, launcher files, screenshots, release archives, or
interactive test artifacts are included.
