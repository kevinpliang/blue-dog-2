# Remove Trail and Preserve Duck Roll Plan

1. Add regressions for no speed trail, a four-node particle budget, removed trail tuning, and continuous roll through ducking.
2. Run the affected tests and confirm they fail for the missing behavior.
3. Remove trail code and tuning, then replace incremental mesh rotation with explicit roll-angle state.
4. Run the complete automated suite and a portrait render check.
5. Commit and push the verified change.

