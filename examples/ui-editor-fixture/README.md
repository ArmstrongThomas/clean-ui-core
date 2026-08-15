# UI Editor Fixture

Registers a small, deterministic Clean UI API V3 playground for standalone UI
editor work. It exercises a panel descriptor, a label, a controlled dropdown,
direct V3 dialogue, choice, battle, and animation models, named actions, a modal response,
a Gallery fixture, and the editor-safe
contract catalog exposed by `cleanUiHost.listContracts`.

The example is intentionally cross-generation and uses the V3
`all_generations = true` contract flag. It contains no compatibility aliases.
Build it locally with `.\build_release.ps1`, install the resulting
ZIP beside either Clean UI product, and open `MOD MENUS > UI EDITOR FIXTURE`.
The standalone editor can use the same contract source or inspect the live
registration through the V3 `contract_catalog` capability.
