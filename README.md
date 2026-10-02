# Elixir Fundamentals — for Humans and AIs

Intensive training on the Elixir fundamentals used to build an inverted index.
Every claim is validated by tests — including claims that look silly but that
AIs (and humans) get wrong over and over again.

## Why this exists

AI assistants generate plausible-but-wrong Elixir with remarkable consistency.
The same mistakes appear across models, sessions, and prompts:

- code that contradicts itself two lines apart,
- outdated APIs presented as current,
- "it raises" claims about code that actually works (and vice versa),
- subtle semantics (`trim: true`, term ordering, `flat_map` strictness)
  confidently stated backwards.

These tests look silly. That is the point: if a model cannot get
`1 + 2 |> IO.puts()` or `Enum.sort([1, "a", :ok])` right, it cannot be
trusted with the inverted-index pipeline built on top of them.

Humans benefit the same way: type every snippet in IEx, watch it fail,
fix it, repeat until it is muscle memory.

## What is validated

- **100 exercises** (`#1`–`#100`): pipe, `String.*`, `~w`, `~r/u`,
  `Enum.map/flat_map/filter/reject/uniq/sort/sort_by/group_by/reduce/with_index`,
  `Map.new/get/update`, `&` capture, pattern matching, guards, multi-clause
  functions, `in`, `:math.log/1`, `@` attributes, `def/defp`.
- **5 mini-challenges** (`D1`–`D5`): tokenize pipeline, word count,
  group-into-postings, per-doc counts, list intersection via `reduce/3`.
- **10 documented AI/human errors** (the interesting part — see below),
  each with a test asserting actual behavior on Elixir 1.20.1 / OTP 29.

## Quick start

```bash
mix test
# Result: 157 passed, zero warnings
```

- Proof suite: [`test/proof_test.exs`](test/proof_test.exs) — the full
  tuning file: every exercise plus a regression test per documented
  error, article modules inlined (this repo never uses `/lib`). Each test
  carries 5W1H + STAR comments plus a FLOW block showing real values
  at every transformation step.
- Corrections split: [`test/corrections_test.exs`](test/corrections_test.exs)
  — frozen snapshot of every mistake row (claims articles got wrong +
  proofs), self-contained for tuning. Source of truth stays in `proof_test.exs`.
- Each documented error is marked `[v1-fix]` in its test comment and grouped
  in the hall of shame below.

For agents: run `mix test` first, read the failing assertion message,
then read the corresponding test comment. Do not guess — reproduce.

## Validated AI mistakes (hall of shame)

| # | Claim AIs repeat | Actual behavior (tested) |
|---|---|---|
| 1 | `"hello world" \|> String.replace("world", "elixir")` raises `ArgumentError` | Returns `"hello elixir"` — pipe puts the value in 1st-arg position, which is exactly where `target` goes |
| 2 | `1 + 2 \|> IO.puts()` parses as `1 + (2 \|> puts)` and raises | Prints `3`, returns `:ok` — `+` binds tighter than `\|>` (AST-proven in tests) |
| 3 | `trim: true` strips edge empties only | Removes **all** empties: `split("a,b,,c", ",", trim: true) == ["a", "b", "c"]` |
| 4 | `"é" =~ ~r/\p{L}/` (no `/u`) raises `Regex.CompileError` | Returns `true` on OTP 29 — still always use `/u` with `\p`, but the error type was wrong |
| 5 | `Enum.flat_map([1, 2], fn x -> x * 2 end)` returns `[2, 4]` | Raises `Protocol.UndefinedError` — fun must return an enumerable; use `Enum.map/2` for plain values |
| 6 | `Enum.sort([1, "a", :ok])` raises `ArgumentError` | Returns `[1, :ok, "a"]` via Erlang term ordering — normalize first if you need a domain order |
| 7 | `Enum.reduce([1, 2, 3], fun)` raises `FunctionClauseError` | Returns `6` — `reduce/2` exists (first element as acc); prefer explicit `reduce/3` |
| 8 | `Enum.with_index(list, 1)` raises `UndefinedFunctionError` | Returns indexed-from-1 tuples — offset form exists since Elixir 1.12 |
| 9 | `:math.log(-1)` returns `nan` | Raises `ArithmeticError` (same for `log(0)`) |
| 10 | D4 answer with `Enum.flat_map(fn {id, txt} -> {id, count} end)` works | Raises `Protocol.UndefinedError` (tuple is not enumerable) — fixed with `Enum.map/2` |

## Repo layout

```text
test/proof_test.exs           # full proofs: 5W1H + STAR + FLOW, warning-clean
test/corrections_test.exs     # frozen mistake-rows split for tuning
scripts/derive.exs            # .exs → dataset/*.jsonl (mix run scripts/derive.exs)
scripts/lint.exs              # schema linter (mix run scripts/lint.exs)
dataset/*.jsonl               # derived tuning rows: explain/detect/fix/generate
lib/elixir_fundamentals.ex    # unused placeholder (repo keeps code in test files)
```

## Derived artifacts (never edit by hand)

`mix run scripts/derive.exs` parses both suites and emits versioned rows —
re-run after editing tests. `mix run scripts/lint.exs` enforces the
CONTRIBUTING.md schema (errors fail, vague-`Why` warns).

## Adding a newly spotted AI mistake

1. Reproduce it in IEx first.
2. Add a test in `test/proof_test.exs` asserting **actual** behavior,
   with a comment quoting the wrong claim.
3. If the suite emits a type warning for the intentional counterexample,
   hide the literal via the existing `opaque/1` helper instead of
   weakening the test.
4. Mark the fix `[v1-fix]`-style in the test comment.
5. `mix test` must stay green and warning-free.

## How to add tests: the generator → prover loop

This repo runs on a loop you can reuse for any fundamental concept:

1. **Generator AI** (Gemini, DeepSeek, …) → writes an article in the fixed
   shape: concept, examples, counterexamples, misconceptions, numbered
   exercises, answer key.
2. **Prover (opencode + `mix test`)** → proves every snippet with ExUnit.
   What passes becomes proof; what fails becomes documented errata.
3. The pair `article + green tests` is the artifact worth keeping — and the
   format most likely to ever close a misconception for good, including in
   future model training: the test is machine-checkable ground truth, not
   opinion.

Everything lives in `test/proof_test.exs`:

```elixir
describe "section N: name" do
  test "examples" do
    assert Enum.frequencies(~w(a b a)) == %{"a" => 2, "b" => 1}
  end

  test "counterexample raises" do
    assert_raise Protocol.UndefinedError, fn ->
      Enum.flat_map([1, 2], fn x -> x * 2 end)
    end
  end
end
```

Then run `mix test` — it must stay green **and warning-free**.
Three tricks keep it that way:

**1. Wrong-type counterexample → `opaque/1`.**
Elixir 1.20 emits a type warning if you write the mistake literally:

```elixir
# ❌ warns:
assert_raise FunctionClauseError, fn -> String.downcase(42) end
# ✅ clean, same runtime behavior:
assert_raise FunctionClauseError, fn -> String.downcase(opaque(42)) end
```

`opaque/1` (defined at the top of the test file) round-trips the value
through `:erlang.term_to_binary/binary_to_term`, so the compiler only sees
`term()`. Use it for: wrong arg types, missing `Map.get` keys,
`Map.new([1, 2, 3])`.

**2. Must-fail-to-compile test → capture stderr.**
Negative compile tests (`&1`, `&String.upcase` without arity, guards calling
`String.length/1`) print diagnostics to stderr. Wrap them:

```elixir
ExUnit.CaptureIO.capture_io(:stderr, fn ->
  assert_raise CompileError, fn -> Code.compile_string("&1") end
end)
```

**3. `~w` with commas → evaluate at runtime.**
`~w(a, the, of)` warns at compile time — which is itself the behavior under
test (commas stick to tokens). Evaluate via string with stderr captured:

```elixir
comma_words =
  ExUnit.CaptureIO.capture_io(:stderr, fn ->
    send(self(), {:w, Code.eval_string("~w(a, the, of)") |> elem(0)})
  end)
  |> then(fn _ -> receive do {:w, v} -> v end end)

assert comma_words == ["a,", "the,", "of"]
```

Private-function checks use `apply/3` instead of a direct call
(`apply(NProof, :b, [5])`) to avoid the private-call warning.

**4. FLOW blocks show real values, not types.**
Above any test whose action is a pipeline of ≥3 stages, and inside any
module function composing more than two `|>` steps, add the value at every
arrow (verified by running, never hand-waved). Loops/recursion get a trace
table instead of arrows:

```elixir
# FLOW | "  THE CAT CLIMBED!  "
#          │ String.trim()
#          ▼ "THE CAT CLIMBED!"
#          │ String.downcase()
#          ▼ "the cat climbed!"
#          ...
#          ▼ ["cat", "climbed"]
```

Rules: one arrow = one transformation; use the real function names;
terminate on the asserted value; for documented errors annotate the wrong
step (`▼ [8, 0, 7]  ← article claims [7, 0, 8]`). Skip FLOW on one-liners.
Two shapes: **spine** (arrow chain, ≥3 stages) and **inline**
(`120 → abs → 120 → "120" → reverse → "021" → 21`, one `→` chain for short
flows). Stateful loops get trace tables instead of arrows.

**5. Corrections split stays frozen.**
`test/corrections_test.exs` holds copies of every mistake row (errors, gaps,
divergences, warts) with self-contained `Ck*` modules. When you fix or add
a mistake row in `test/proof_test.exs`, mirror it there. Source of truth for
behavior is always `proof_test.exs`; the split is a tuning convenience.

### Prompts to reuse

**Generator prompt (paste into Gemini/DeepSeek):**

> Write about [CONCEPT] in Elixir 1.20. Mandatory shape per section:
> Concept (one sentence), Examples (valid IEx code), Counterexamples
> (code that breaks + the exact error), Misconceptions (3 bullets),
> numbered Exercises, Answer key. Do not invent error messages —
> if unsure, write UNSURE.

**Prover prompt (paste into opencode with the article):**

> Prove every snippet of the article below with ExUnit in
> `test/proof_test.exs`. Each exercise becomes an assert; each
> "raises X" becomes an `assert_raise` with the REAL error verified via
> `mix test`. Where the article is wrong, mark `[v1-fix]` in the test
> comment. `mix test` must stay green and
> warning-free (reuse the `opaque/1` and `capture_io` patterns already in
> the file).

Errors are learning — document them, don't hide them.

---

## Author

Matheus de Camargo Marques <matheuscamarques@gmail.com>
