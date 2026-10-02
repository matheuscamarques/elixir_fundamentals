# Contributing — comment schema and quality bar

This repo is a **dual-purpose corpus**: every test block is simultaneously
human documentation and a fine-tuning row (natural-language prediction +
executable assertion). Follow this schema so new blocks match. All blocks
are English-only.

## File map

- `test/proof_test.exs` — full proofs. Article solution modules are inlined
  here (never in `/lib`). Source of truth for behavior.
- `test/corrections_test.exs` — frozen snapshot of every mistake row
  (errors, gaps, divergences, warts) with self-contained `Ck*` modules.
  When you add or fix a mistake row in `proof_test.exs`, mirror it here.
- `README.md` — project overview, hall of shame, workflow.

## Block template (copy this)

```elixir
# 5W1H | Who: <role(s)>. What: <one behavior>. When/Where: <article §, Elixir/OTP>.
#        How: <assertion strategy>. Why: <misconception killed>.
# STAR | Situation: <claim>. Task: <must prove>. Action: <what runs>. Result: <values>.
# FLOW | <input value>              (only for ≥3-stage pipelines; traces for loops)
#          │ <step>
#          ▼ <intermediate value>   (end on the asserted value)
# Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
test "<claim as a sentence> (<tag if applicable>)" do
  ...
end
```

- **5W1H** describes the artifact; **STAR** describes the execution;
  **FLOW** shows real values at every transformation (verified by running,
  never hand-waved). `Result:` must contain concrete values, not prose.
- **Author line stays on every block.** It makes each block an attributable
  training row. Do not strip it.
- **Keep exercise coverage exhaustive.** Repetition across shapes is
  deliberate training signal here, not duplication to be removed.

## Category tags (in the test name)

| Tag | Meaning |
|---|---|
| `(article error documented)` | published article got this wrong; test proves actual |
| `(article gap documented)` | article never covers it; behavior pinned anyway |
| `(behavioral difference documented)` | "equivalent" solutions diverge |
| none | happy path / correct claim |

The tag makes mistakes greppable: `grep "(article error documented)"`.

## Documented errors: CLAIM / ACTUAL / LESSON

Every mistake row must show both sides — what was claimed AND what is real:

```elixir
assert AddTwoNumbersAcc.add_two_numbers(...) |> to_list() == [8, 0, 7]   # ACTUAL
refute AddTwoNumbersAcc.add_two_numbers(...) |> to_list() == [7, 0, 8]   # CLAIM
```

Always pair `assert` (actual) with `refute` (claim) for errors.

## Techniques that keep the suite warning-free

- **`opaque/1`** (top of `proof_test.exs`) hides literal types from the
  Elixir 1.20 type checker so intentional counterexamples still raise at
  runtime. Say why in the comment when you use it.
- **Verbatim broken sources** go in `@verbatim_*_src` strings +
  `Code.compile_string/1` inside `assert_raise`, with stderr captured.
  Never "fix silently" — paste verbatim, explain the exact defect.
- **`capture_io(:stderr, …)`** wraps anything that warns (decreasing
  ranges, unused vars). Mention the warning in the comment.
- **Private calls** use `apply/3` to avoid private-call warnings.
- **Renamed modules**: article code calling everything `Solution` is
  renamed (`TwoSumRec`, …) with a `# NOTE:` — same bytes otherwise.

## Checklist before committing

- [ ] New test has 5W1H + STAR (+ FLOW if ≥3 stages), all fields meaningful.
- [ ] `Why:` names a specific misconception, not "repetition".
- [ ] `Result:` contains literal expected values.
- [ ] Mistake rows carry the right tag and an assert+refute (or raise) pair.
- [ ] Version-sensitive facts pinned (`since 1.12`, `verified on 1.20.1/OTP29`).
- [ ] `mix test` green **and** warning-free.
- [ ] Mistake rows mirrored into `test/corrections_test.exs`.
- [ ] Author line present.

## Workflow

Generator AI writes the article (concept, examples, counterexamples,
misconceptions, exercises, answer key) → prover (opencode + `mix test`)
proves every snippet → passes become proof, failures become documented
errata with `[v1-fix]`-style comments. See README for the full loop
and reusable prompts.
