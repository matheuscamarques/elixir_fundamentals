---
title: "Elixir Fundamentals for Inverted Index: exercises, counterexamples and misconceptions"
published: true
description: "Intensive training on the Elixir fundamentals you'll use to build an inverted index. Examples, counterexamples, common misconceptions and exercises with answers."
tags: elixir, beginners, tutorial, programming
---

This article is **not passive reading**. It's training.

Before tackling the tutorial "Building an Inverted Index in Elixir", you need **muscle memory** on a specific set of functions and concepts. Reading once isn't enough — you need to **repeat**, fail, see the failure, fix it, and repeat again.

Every section follows the same structure:

1. **Concept** — short explanation.
2. **Examples** — what works.
3. **Counterexamples** — what breaks and why.
4. **Common misconceptions** — what almost everyone gets wrong.
5. **Exercises** — repeat until it becomes automatic.
6. **Answer key** — check and move on.

Open IEx (`iex`) and **type everything**. Seriously. Typing is part of the training.

All snippets below were verified with `mix test` on Elixir 1.20.1 / OTP 29 (see `test/article_proof_test.exs` in the companion repo). Where v1 of this article was wrong, the fix is marked with **[v1-fix]** — errors are learning, so they are documented, not hidden. See "Errata from v1" at the end.

---

## 1. The pipe operator `|>`

### Concept

`|>` passes the result from the left as the **first argument** to the function on the right.

### Examples

```elixir
iex> "hello" |> String.upcase()
"HELLO"

iex> "hello" |> String.upcase() |> String.reverse()
"OLLEH"
```

### Counterexamples

The pipe only passes the value as the **first** argument. If the function needs the value elsewhere, the pipe alone won't help:

```elixir
# ❌ Silent logic bug — piped value becomes the SUBJECT (1st arg), not the pattern
iex> "world" |> String.replace("hello world", "elixir")
"world"
# = String.replace("world", "hello world", "elixir") — no match, no error, wrong result

# ✅ Correct — String.replace(target, pattern, replacement)
iex> String.replace("hello world", "world", "elixir")
"hello elixir"

# ✅ Same, via pipe (target piped as 1st arg)
iex> "hello world" |> String.replace("world", "elixir")
"hello elixir"
```

A case that **does** raise — first arg must be enumerable:

```elixir
# ❌ 2 is not enumerable; |> puts it where the list should go
iex> 2 |> Enum.member?([1, 2, 3])
** (Protocol.UndefinedError) ...

# ✅ List first
iex> [1, 2, 3] |> Enum.member?(2)
true
```

**[v1-fix]** v1 showed `"hello world" |> String.replace("world", "elixir")` as both ❌ (`ArgumentError`) and ✅. That was self-contradictory. It never raises — it returns `"hello elixir"`.

### Common misconceptions

- **"The pipe does something magical."** It doesn't. It's just rewriting. `a |> f(b)` is literally `f(a, b)`.
- **"I need parens to make `1 + 2 |> IO.puts()` work."** You don't — on current Elixir it already works. `|>` has **lower** precedence than `+`/`<>`, so the arithmetic runs first:

```elixir
iex> 1 + 2 |> IO.puts()
3
:ok

iex> "a" <> "b" |> String.upcase()
"AB"
```

**[v1-fix]** v1 claimed `1 + 2 |> IO.puts()` parses as `1 + (2 |> IO.puts())`, prints `2`, then raises `ArithmeticError`. Verified AST on Elixir 1.20: the left side of `|>` is `(1 + 2)`. It prints `3` and returns `:ok`. Rule of thumb: `+`, `<>` bind tighter than `|>`. Use explicit parens anyway when it helps readability — e.g. `(1 + 2) |> IO.puts()`.

### Exercises

Without running in IEx, **predict** the result. Then check.

```elixir
# 1
"abc" |> String.upcase() |> String.length()

# 2
"abc" |> String.length() |> String.upcase()

# 3
String.upcase("abc") |> String.reverse()

# 4
"abc" |> String.reverse() |> String.upcase() |> String.slice(0, 2)
```

**Answer key:**
1. `3`
2. Error (`FunctionClauseError` — `String.upcase/1` expects a string, but `String.length/1` returns a number).
3. `"CBA"`
4. `"CB"`

---

## 2. `String.downcase/1`

### Concept

Converts the whole string to lowercase. Handles Unicode (accents) by default.

### Examples

```elixir
iex> String.downcase("CAT")
"cat"

iex> String.downcase("The Cat Climbed The Roof")
"the cat climbed the roof"

iex> String.downcase("AÇÃO")
"ação"
```

### Counterexamples

```elixir
# ❌ Doesn't work with numbers
iex> String.downcase(42)
** (FunctionClauseError) ...

# ❌ Doesn't work with nil
iex> String.downcase(nil)
** (FunctionClauseError) ...
```

### Common misconceptions

- **"Downcase doesn't touch accents."** It does, and correctly. `"AÇÃO"` becomes `"ação"`, not something weird.
- **"Downcase changes the string length."** Usually not, but some special Unicode characters can. In 99% of cases, the length stays the same.

### Exercises

Predict, then confirm:

```elixir
# 5
String.downcase("HELLO World")

# 6
String.downcase("") == ""

# 7
String.downcase("Ç") == "ç"

# 8
String.length(String.downcase("ÉÀÇ"))
```

**Answer key:**
5. `"hello world"`
6. `true`
7. `true`
8. `3`

---

## 3. `String.replace/3`

### Concept

Replaces all occurrences of a pattern (string or regex) with a replacement.

### Examples

```elixir
iex> String.replace("good morning", "morning", "night")
"good night"

iex> String.replace("a-a-a", "a", "b")
"b-b-b"

iex> String.replace("a1b2c3", ~r/\d/, "*")
"a*b*c*"
```

### Counterexamples

```elixir
# ❌ Replacing with an empty string, without thinking
iex> String.replace("end.start", ".", "")
"endstart"
```

This is the classic example from the tutorial. We'll **repeat** it because this is where most people get it wrong.

```elixir
# ✅ Replacing with a space
iex> String.replace("end.start", ".", " ")
"end start"

# ❌ Now with multiple separators
iex> String.replace("a,b;c.d", ~r/[,;.]/, "")
"abcd"

# ✅ With a space it separates correctly
iex> String.replace("a,b;c.d", ~r/[,;.]/, " ")
"a b c d"
```

### Common misconceptions

- **"Replacing with `""` is the same as replacing with `" "`."** It isn't. `""` erases; `" "` separates.
- **"replace only changes one occurrence."** It changes **all** of them, always.
- **"replace ignores case."** It doesn't. `"A"` and `"a"` are different to it.

### Exercises

```elixir
# 9
String.replace("banana", "a", "o")

# 10
String.replace("a b c", " ", "")

# 11
String.replace("a b c", " ", "_")

# 12
String.replace("ssn: 123.456.789-00", ~r/\D/, "")

# 13
String.replace("pineapple", "a", "")
```

**Answer key:**
9. `"bonono"`
10. `"abc"`
11. `"a_b_c"`
12. `"12345678900"`
13. `"pinepple"`

---

## 4. `String.split/2` and `String.split/3`

### Concept

Splits a string into a list, using a separator (string or regex). The third argument accepts options — the most used is `trim: true`, which discards empty strings from the result.

**[v1-fix]** v1 said `trim: true` discards empties "at the edges" only. Verified: it discards **all** empty strings.

### Examples

```elixir
iex> String.split("cat dog")
["cat", "dog"]

iex> String.split("a,b,c", ",")
["a", "b", "c"]

iex> String.split("cat   dog", ~r/\s+/)
["cat", "dog"]
```

### Counterexamples

```elixir
# ❌ split with a single space doesn't handle multiple spaces
iex> String.split("cat   dog", " ")
["cat", "", "", "dog"]

# ✅ regex with + treats them as a single separator
iex> String.split("cat   dog", ~r/\s+/)
["cat", "dog"]
```

### Common misconceptions

- **"`trim: true` removes empties from the edges only."** It doesn't. It removes **all** of them. **[v1-fix]**
- **"Without trim, split removes empties automatically."** It removes nothing.

```elixir
iex> String.split("  a  b  ", " ")
["", "", "a", "", "b", "", ""]

iex> String.split("  a  b  ", " ", trim: true)
["a", "b"]
# [v1-fix] v1 claimed ["a", "", "b"] here. Actual is ["a", "b"].

iex> String.split("a,b,,c", ",", trim: true)
["a", "b", "c"]
# [v1-fix] v1 claimed ["a", "b", "", "c"] here. Actual is ["a", "b", "c"].
```

To keep middle empties, omit `trim`. To collapse multiple separators, use a regex with `+` or `Enum.reject/2`.

### Exercises

```elixir
# 14
String.split("a b c")

# 15
String.split("a,b,,c", ",")

# 16
String.split("a,b,,c", ",", trim: true)

# 17
String.split("a   b   c", ~r/\s+/)

# 18
String.split("a   b   c", " ")
```

**Answer key:**
14. `["a", "b", "c"]`
15. `["a", "b", "", "c"]`
16. `["a", "b", "c"]` — **[v1-fix]** trim removes all empties, not only edges
17. `["a", "b", "c"]`
18. `["a", "", "", "b", "", "", "c"]`

---

## 5. Sigil `~w` (word list)

### Concept

Creates a list of strings from words separated by spaces.

```elixir
iex> ~w(a the of for)
["a", "the", "of", "for"]
```

### Counterexamples

`~w` splits by **space**, not comma:

```elixir
# ❌ Commas become part of the token
iex> ~w(a, the, of)
["a,", "the,", "of"]

# ✅ No commas
iex> ~w(a the of)
["a", "the", "of"]
```

### Common misconceptions

- **"I can use commas."** You can't. Only spaces.
- **"~w creates words, not strings."** It creates strings. For atoms, use `~w(...)a`.
- **"~w always creates a list of strings."** Yes, by default.

```elixir
iex> ~w(a b c)
["a", "b", "c"]

iex> ~w(a b c)a
[:a, :b, :c]

iex> ~w(1 2 3)
["1", "2", "3"]

iex> ~w(1 2 3)a
[:"1", :"2", :"3"]
```

### Exercises

```elixir
# 19
~w(cat dog fish) == ["cat", "dog", "fish"]

# 20
~w(a b c) == ~w(c b a)

# 21
length(~w(a a a a))

# 22
"cat" in ~w(cat dog)
```

**Answer key:**
19. `true`
20. `false` — order matters
21. `4` — repetitions count
22. `true`

---

## 6. Essential regex and the `/u` flag

### Concept

Regex in Elixir uses the `~r` sigil. The `/u` flag enables Unicode mode — **always use it** with `\p{L}` and `\p{N}`.

### Examples

```elixir
iex> "cat123" =~ ~r/\d/
true

iex> "cat123" =~ ~r/\p{L}+/u
true

iex> "123" =~ ~r/\p{L}/u
false

iex> "é" =~ ~r/\p{L}/u
true
```

### Counterexamples

What happens without `/u` is version-dependent — do not rely on it:

```elixir
iex> "cat" =~ ~r/\p{L}/
true  # ASCII happens to match

iex> "é" =~ ~r/\p{L}/
true  # on Elixir 1.20 / OTP 29 this does NOT raise; on older stacks it could raise Regex.CompileError
```

**Rule:** whenever you use `\p{...}`, add `/u`. The flag guarantees Unicode semantics; without it you get "works by accident in ASCII, surprises with accents".

**[v1-fix]** v1 claimed `"é" =~ ~r/\p{L}/` raises `Regex.CompileError`. Verified on Elixir 1.20.1/OTP 29: it returns `true`. Kept the rule, fixed the claimed error type.

### The negated class `[^...]`

```elixir
iex> "hello" =~ ~r/[^\p{L}\p{N}\s]/u
false  # only letters

iex> "hello!" =~ ~r/[^\p{L}\p{N}\s]/u
true  # has exclamation mark

iex> "a b" =~ ~r/[^\p{L}\p{N}\s]/u
false  # space is allowed

iex> "a-b" =~ ~r/[^\p{L}\p{N}\s]/u
true  # hyphen is not a letter, number, or space
```

### Common misconceptions

- **"`\p{L}` and `[a-z]` are the same thing."** They aren't. `\p{L}` covers all Unicode alphabets.
- **"Without `/u` it works the same."** In plain ASCII it sometimes works; with accents it breaks or behaves inconsistently across versions.
- **"`^` inside `[^...]` means start of string."** It doesn't. Inside `[...]`, `^` **negates** the class.

### Exercises

Predict `true` or `false`:

```elixir
# 23
"abc" =~ ~r/[^\p{L}\p{N}\s]/u

# 24
"abc!" =~ ~r/[^\p{L}\p{N}\s]/u

# 25
"123" =~ ~r/[^\p{L}\p{N}\s]/u

# 26
"a b" =~ ~r/[^\p{L}\p{N}\s]/u

# 27
"a.b" =~ ~r/[^\p{L}\p{N}\s]/u

# 28
"" =~ ~r/[^\p{L}\p{N}\s]/u

# 29
"a  b" =~ ~r/[^\p{L}\p{N}\s]/u
```

**Answer key:**
23. `false` — letters only
24. `true` — exclamation mark
25. `false` — digits only
26. `false` — space is allowed by `\s`
27. `true` — dot
28. `false` — empty matches nothing
29. `false` — two spaces are still `\s`

---

## 7. `Enum.map/2`

### Concept

Transforms every element of the list with a function. **The list size is preserved**.

```elixir
iex> Enum.map([1, 2, 3], fn x -> x * 2 end)
[2, 4, 6]

iex> Enum.map(["a", "b"], fn s -> String.upcase(s) end)
["A", "B"]
```

### Counterexamples

```elixir
# ❌ map doesn't flatten
iex> Enum.map([[1, 2], [3, 4]], fn l -> l end)
[[1, 2], [3, 4]]

# ❌ map doesn't filter
iex> Enum.map([1, 2, 3, 4], fn x -> x > 2 end)
[false, false, true, true]
```

### Common misconceptions

- **"map removes elements."** It doesn't. One becomes one.
- **"map flattens nested lists."** It doesn't. That's `flat_map`'s job.

### Exercises

```elixir
# 30
Enum.map([1, 2, 3], fn x -> x + 1 end)

# 31
Enum.map(["a", "b"], fn s -> s <> s end)

# 32
Enum.map([1, 2, 3], fn x -> x > 1 end)

# 33
Enum.map([[1], [2, 3]], fn l -> length(l) end)

# 34
Enum.map([], fn x -> x end)
```

**Answer key:**
30. `[2, 3, 4]`
31. `["aa", "bb"]`
32. `[false, true, true]`
33. `[1, 2]`
34. `[]`

---

## 8. `Enum.flat_map/2`

### Concept

Like `map`, but **flattens** one level. If your function returns lists, the final result is a single list. The function **must** return an enumerable.

```elixir
iex> Enum.flat_map([[1, 2], [3, 4]], fn l -> l end)
[1, 2, 3, 4]

iex> Enum.flat_map(["a b", "c d"], fn s -> String.split(s) end)
["a", "b", "c", "d"]
```

### Counterexamples

```elixir
# ❌ flat_map doesn't flatten everything, only one level
iex> Enum.flat_map([[[1]], [[2]]], fn l -> l end)
[[1], [2]]

# ❌ flat_map with a function returning a non-enumerable RAISES
iex> Enum.flat_map([1, 2], fn x -> x * 2 end)
** (Protocol.UndefinedError) protocol Enumerable not implemented for Integer ...
```

**[v1-fix]** v1 claimed the last line returns `[2, 4]` ("works because map accepts it too"). Verified: it raises. Use `Enum.map/2` when the function returns plain values.

### Common misconceptions

- **"flat_map flattens recursively."** It doesn't. One level only.
- **"flat_map is always better than map."** No. Use it when your function produces lists and you want them unified.

### Exercises

```elixir
# 35
Enum.flat_map([1, 2, 3], fn x -> [x, x] end)

# 36
Enum.flat_map(["ab", "cd"], fn s -> String.graphemes(s) end)

# 37
Enum.flat_map([1, 2], fn x -> [] end)

# 38
Enum.flat_map([1, 2], fn x -> [[x]] end)
```

**Answer key:**
35. `[1, 1, 2, 2, 3, 3]`
36. `["a", "b", "c", "d"]`
37. `[]`
38. `[[1], [2]]` — only one level of flattening

---

## 9. `Enum.filter/2` and `Enum.reject/2`

### Concept

`filter` keeps the elements that pass the condition. `reject` discards them. They are **opposites**.

```elixir
iex> Enum.filter([1, 2, 3, 4], fn x -> x > 2 end)
[3, 4]

iex> Enum.reject([1, 2, 3, 4], fn x -> x > 2 end)
[1, 2]
```

### Counterexamples

```elixir
# ❌ filter doesn't transform — map afterwards if you want to transform
iex> Enum.filter([1, 2, 3, 4], fn x -> x > 2 end) |> Enum.map(fn x -> x * 10 end)
[30, 40]

# reject with the inverted condition gives the same result as filter
iex> Enum.reject([1, 2, 3, 4], fn x -> x <= 2 end)
[3, 4]
```

### Common misconceptions

- **"filter and reject are the same with a negated condition."** They are — but writing `reject(&(&1 in stopwords))` is more direct than `filter(fn x -> x not in stopwords end)`.
- **"filter preserves order."** It does.
- **"filter can duplicate."** It can't.

### Exercises

```elixir
# 39
Enum.filter([1, 2, 3], fn x -> x > 1 end)

# 40
Enum.reject([1, 2, 3], fn x -> x > 1 end)

# 41
Enum.filter(~w(a the cat of), fn t -> t in ~w(a the of) end)

# 42
Enum.reject(~w(a the cat of), fn t -> t in ~w(a the of) end)

# 43
Enum.filter([1, 2, 3], fn _ -> true end)

# 44
Enum.reject([1, 2, 3], fn _ -> false end)
```

**Answer key:**
39. `[2, 3]`
40. `[1]`
41. `["a", "the", "of"]`
42. `["cat"]`
43. `[1, 2, 3]`
44. `[1, 2, 3]`

---

## 10. `Enum.uniq/1`

### Concept

Removes duplicates keeping the **first** occurrence. Comparison is strict (`===`): `1` and `1.0` are different.

```elixir
iex> Enum.uniq([1, 2, 2, 3, 1, 4])
[1, 2, 3, 4]

iex> Enum.uniq(["a", "b", "a"])
["a", "b"]

iex> Enum.uniq([1, 1.0])
[1, 1.0]
```

### Counterexamples

```elixir
# ❌ uniq doesn't sort
iex> Enum.uniq([3, 1, 2, 1, 3])
[3, 1, 2]

# ✅ To sort, you need to combine
iex> [3, 1, 2, 1, 3] |> Enum.uniq() |> Enum.sort()
[1, 2, 3]
```

### Common misconceptions

- **"uniq sorts."** It doesn't. Only removes duplicates.
- **"uniq preserves the last one."** It preserves the **first**.
- **"uniq compares with `==`."** It compares with `===` (stricter) — hence `[1, 1.0]` keeps both.

### Exercises

```elixir
# 45
Enum.uniq([1, 1, 1])

# 46
Enum.uniq([3, 1, 3, 2, 1])

# 47
Enum.uniq(["a", "A", "a"])

# 48
[1, 2, 2, 3] |> Enum.uniq() |> Enum.sort()
```

**Answer key:**
45. `[1]`
46. `[3, 1, 2]`
47. `["a", "A"]` — Elixir differentiates uppercase and lowercase
48. `[1, 2, 3]`

---

## 11. `Enum.sort/1` and `Enum.sort_by/2`

### Concept

`sort/1` orders values. `sort_by/2` orders by a criterion extracted by a function.

```elixir
iex> Enum.sort([3, 1, 2])
[1, 2, 3]

iex> Enum.sort_by([{1, "b"}, {2, "a"}], fn {n, _} -> n end)
[{1, "b"}, {2, "a"}]

iex> Enum.sort_by([{1, "b"}, {2, "a"}], fn {_, l} -> l end)
[{2, "a"}, {1, "b"}]
```

### Counterexamples

`sort/1` on mixed types does **not** raise — Erlang term ordering applies (`number < atom < reference < fun < port < pid < tuple < map < list < binary`):

```elixir
iex> Enum.sort([1, "a", :ok])
[1, :ok, "a"]
```

**[v1-fix]** v1 claimed `** (ArgumentError)`. Verified: no error. If you need a meaningful order across types, normalize first.

And `sort/1` on strings is **lexicographic** — uppercase before lowercase:

```elixir
iex> Enum.sort(["banana", "Apple", "grape"])
["Apple", "banana", "grape"]
```

If you want to ignore case, normalize first.

### Common misconceptions

- **"sort orders by any criterion."** It only orders comparable values. For a criterion, use `sort_by`.
- **"sort_by accepts only `&1`."** It accepts any function, capture included.
- **"To reverse, I use reverse afterwards."** Works, but `sort_by(fn x -> -x end)` or `sort_by(fn x -> x end, :desc)` is more direct.

### Exercises

```elixir
# 49
Enum.sort([3, 1, 2])

# 50
Enum.sort(["c", "a", "b"])

# 51
Enum.sort_by([3, 1, 2], fn x -> -x end)

# 52
Enum.sort_by(["banana", "grape", "apple"], fn s -> String.length(s) end)

# 53
Enum.sort_by([{2, "a"}, {1, "b"}], fn {n, _} -> n end)
```

**Answer key:**
49. `[1, 2, 3]`
50. `["a", "b", "c"]`
51. `[3, 2, 1]`
52. `["grape", "apple", "banana"]` (grape/apple tie at length 5 — order is stable on current Elixir; verify in IEx)
53. `[{1, "b"}, {2, "a"}]`

---

## 12. `Enum.group_by/2` and `Enum.group_by/3`

### Concept

Groups elements by a key, returning a map. Version `/3` also lets you transform each element before grouping.

```elixir
iex> Enum.group_by([1, 2, 3, 4], fn x -> rem(x, 2) end)
%{0 => [2, 4], 1 => [1, 3]}

iex> Enum.group_by([1, 2, 3, 4], fn x -> rem(x, 2) end, fn x -> x * 10 end)
%{0 => [20, 40], 1 => [10, 30]}
```

### Counterexamples

```elixir
# ❌ group_by doesn't transform keys automatically
iex> Enum.group_by(["cat", "CAT"], fn s -> s end)
%{"cat" => ["cat"], "CAT" => ["CAT"]}

# ✅ Normalize before grouping
iex> Enum.group_by(["cat", "CAT"], fn s -> String.downcase(s) end)
%{"cat" => ["cat", "CAT"]}
```

### Common misconceptions

- **"group_by sorts."** It doesn't. It preserves order within each group.
- **"The key function and the value function are the same."** No. The 2nd function is applied only to the **values** — the key is fixed.

### Exercises

```elixir
# 54
Enum.group_by([1, 2, 3, 4, 5], fn x -> rem(x, 3) end)

# 55
Enum.group_by(["a", "bb", "c", "dd"], fn s -> String.length(s) end)

# 56
Enum.group_by(["a", "bb", "c"], fn s -> String.length(s) end, fn s -> String.upcase(s) end)

# 57
Enum.group_by(~w(cat cat dog), fn t -> t end)
```

**Answer key:**
54. `%{0 => [3], 1 => [1, 4], 2 => [2, 5]}`
55. `%{1 => ["a", "c"], 2 => ["bb", "dd"]}`
56. `%{1 => ["A", "C"], 2 => ["BB"]}`
57. `%{"cat" => ["cat", "cat"], "dog" => ["dog"]}`

---

## 13. `Enum.reduce/3`

### Concept

Iterates the collection accumulating a value. Receives element and current accumulator, returns the **new** accumulator.

```elixir
iex> Enum.reduce([1, 2, 3, 4], 0, fn x, acc -> acc + x end)
10
```

### Counterexamples

```elixir
# reduce/2 EXISTS (no initial) — uses the first element as accumulator
iex> Enum.reduce([1, 2, 3], fn x, acc -> acc + x end)
6

# ❌ Returning the element instead of the accumulator
iex> Enum.reduce([1, 2, 3], 0, fn x, acc -> x end)
3
```

**[v1-fix]** v1 claimed `reduce/2` raises `FunctionClauseError`. Verified: it returns `6`. Prefer `reduce/3` with an explicit initial value — it is clearer and works on empty lists (where `reduce/2` raises `Enum.EmptyError`).

### Common misconceptions

- **"reduce is always the best choice."** No. `map`, `filter`, `sum` cover most cases with more clarity.
- **"I always need the initial value."** `reduce/2` (without initial) exists, but **I recommend avoiding it** — it uses the first element as accumulator and confuses people. Always pass the initial.
- **"reduce only sums."** Summing is just the simplest example. `reduce` builds lists, maps, anything.

### Exercises

```elixir
# 58
Enum.reduce([1, 2, 3], 0, fn x, acc -> acc + x end)

# 59
Enum.reduce([1, 2, 3], 1, fn x, acc -> acc * x end)

# 60
Enum.reduce(["a", "b", "c"], "", fn s, acc -> acc <> s end)

# 61
Enum.reduce([1, 2, 3, 4], [], fn x, acc -> if rem(x, 2) == 0, do: acc ++ [x], else: acc end)

# 62
Enum.reduce(["a", "b", "c"], %{}, fn s, acc -> Map.put(acc, s, String.length(s)) end)
```

**Answer key:**
58. `6`
59. `6`
60. `"abc"`
61. `[2, 4]`
62. `%{"a" => 1, "b" => 1, "c" => 1}`

---

## 14. `Enum.with_index/1` and `Enum.with_index/2`

### Concept

Transforms each element into a tuple `{element, index}` starting at 0 by default.

```elixir
iex> Enum.with_index(["a", "b", "c"])
[{"a", 0}, {"b", 1}, {"c", 2}]
```

`with_index/2` has **two** forms: an integer offset, or a mapping function:

```elixir
iex> Enum.with_index(["a", "b"], 1)
[{"a", 1}, {"b", 2}]

iex> Enum.with_index(["a", "b"], fn el, i -> {el, i + 100} end)
[{"a", 100}, {"b", 101}]
```

**[v1-fix]** v1 claimed "there's no `with_index/2` in the way you imagine" and that `Enum.with_index(["a", "b"], 1)` raises `UndefinedFunctionError`. Verified: since Elixir 1.12 the offset form exists and returns `[{"a", 1}, {"b", 2}]`.

### Common misconceptions

- **"The index starts at 1."** It starts at **0** (unless you pass an offset).
- **"with_index changes the order."** It doesn't.

### Exercises

```elixir
# 63
Enum.with_index(["x", "y"])

# 64
Enum.with_index([10, 20, 30])

# 65
Enum.with_index(["a", "b"], fn el, i -> {el, i * 2} end)

# 66
[10, 20, 30] |> Enum.with_index() |> Enum.map(fn {v, _} -> v end)
```

**Answer key:**
63. `[{"x", 0}, {"y", 1}]`
64. `[{10, 0}, {20, 1}, {30, 2}]`
65. `[{"a", 0}, {"b", 2}]`
66. `[10, 20, 30]`

---

## 15. `Map.new/1` and `Map.new/2`

### Concept

Creates a map from a list of `{key, value}` tuples. Version `/2` applies a function first.

```elixir
iex> Map.new([{:a, 1}, {:b, 2}])
%{a: 1, b: 2}

iex> Map.new([1, 2, 3], fn x -> {x, x * x} end)
%{1 => 1, 2 => 4, 3 => 9}
```

### Counterexamples

```elixir
# ❌ List without 2-element tuples
iex> Map.new([1, 2, 3])
** (ArgumentError) ...

# Duplicates — the last one wins (no error)
iex> Map.new([{:a, 1}, {:a, 2}])
%{a: 2}
```

### Common misconceptions

- **"Map.new preserves order."** Maps in Elixir have **no defined order** for keys.
- **"Duplicates raise an error."** They don't. The last one overrides.
- **"Map.new accepts any list."** It needs a list of 2-element tuples (or a `/2` fun returning them).

### Exercises

```elixir
# 67
Map.new([{:a, 1}, {:b, 2}])

# 68
Map.new(["a", "bb"], fn s -> {s, String.length(s)} end)

# 69
Map.new([1, 2], fn x -> {x, x} end) |> Map.get(1)

# 70
Map.new([{:a, 1}, {:a, 2}])[:a]
```

**Answer key:**
67. `%{a: 1, b: 2}`
68. `%{"a" => 1, "bb" => 2}`
69. `1`
70. `2`

---

## 16. `Map.get/2` and `Map.get/3`

### Concept

Looks up a value by key. Without a default, returns `nil`. With a default, returns the default if the key doesn't exist.

```elixir
iex> Map.get(%{a: 1}, :a)
1

iex> Map.get(%{a: 1}, :z)
nil

iex> Map.get(%{a: 1}, :z, 0)
0
```

### Common misconceptions

- **"Map.get raises if the key doesn't exist."** It doesn't. Returns `nil` (or the default).
- **"I can use `map[:key]`."** You can, but `map[:key]` **doesn't accept a default** and is less idiomatic when you need one.

### Exercises

```elixir
# 71
Map.get(%{"cat" => [1, 2]}, "cat")

# 72
Map.get(%{"cat" => [1, 2]}, "dog")

# 73
Map.get(%{"cat" => [1, 2]}, "dog", [])

# 74
~w(cat dog) |> Enum.flat_map(fn t -> Map.get(%{"cat" => [1]}, t, []) end)
```

**Answer key:**
71. `[1, 2]`
72. `nil`
73. `[]`
74. `[1]`

---

## 17. `Map.update/4`

### Concept

Updates a key based on its current value. If the key doesn't exist, inserts the default value.

```elixir
iex> Map.update(%{a: 1}, :a, 0, fn v -> v + 10 end)
%{a: 11}

iex> Map.update(%{a: 1}, :b, 100, fn v -> v + 10 end)
%{a: 1, b: 100}
```

### Counterexamples

```elixir
# If the key exists, the default is ignored
iex> Map.update(%{a: 1}, :a, 999, fn v -> v + 1 end)
%{a: 2}

# If the key doesn't exist, the function is NOT called
iex> Map.update(%{}, :a, 100, fn _ -> raise "never runs" end)
%{a: 100}
```

### Common misconceptions

- **"The function always runs."** It only runs if the key exists.
- **"The default overrides."** It's only used if the key doesn't exist.
- **"update and put are the same."** `put` always overrides. `update` accumulates.

### Exercises

```elixir
# 75
Map.update(%{}, :a, 1, fn v -> v + 100 end)

# 76
Map.update(%{a: 1}, :a, 999, fn v -> v + 1 end)

# 77
Map.update(%{a: 1}, :b, 0, fn v -> v + 1 end)

# 78
Enum.reduce([1, 1, 2], %{}, fn x, acc ->
  Map.update(acc, x, 1, fn v -> v + 1 end)
end)
```

**Answer key:**
75. `%{a: 1}`
76. `%{a: 2}`
77. `%{a: 1, b: 0}`
78. `%{1 => 2, 2 => 1}`

---

## 18. Anonymous functions and the `&` capture

### Concept

Functions are values. `&` creates short anonymous functions. `&1`, `&2`, etc. refer to the arguments.

```elixir
iex> Enum.map([1, 2, 3], &(&1 * 2))
[2, 4, 6]

iex> Enum.map(["a", "b"], &String.upcase/1)
["A", "B"]
```

### Counterexamples

```elixir
# ❌ &1 outside a capture context
iex> &1
** (CompileError) ...

# ❌ Capturing a module function without /arity
iex> &String.upcase
** (CompileError) ...

# ✅ With /arity
iex> &String.upcase/1
```

### Common misconceptions

- **"`&1` works anywhere."** Only inside `&(...)` or as a direct function reference.
- **"Capture is faster."** It's not. It's just shorter.
- **"I have to memorize it."** You don't. If it gets confusing, use `fn ... end`.

### Exercises

Rewrite using capture:

```elixir
# 79 → capture
Enum.map([1, 2], fn x -> x + 1 end)

# 80 → capture
Enum.filter([1, 2, 3], fn x -> x > 1 end)

# 81 → capture
Enum.map(["a"], fn s -> String.upcase(s) end)

# 82 → capture
Enum.reject(~w(a the cat), fn t -> t in ~w(a the) end)
```

**Answer key:**
79. `Enum.map([1, 2], &(&1 + 1))`
80. `Enum.filter([1, 2, 3], &(&1 > 1))`
81. `Enum.map(["a"], &String.upcase/1)`
82. `Enum.reject(~w(a the cat), &(&1 in ~w(a the)))`

---

## 19. Pattern matching

### Concept

`=` is pattern matching. The left side describes the **shape**; the right side must match.

```elixir
iex> {a, b} = {1, 2}
iex> a
1

iex> [h | t] = [1, 2, 3]
iex> h
1
iex> t
[2, 3]

iex> %{name: n} = %{name: "Ana", age: 30}
iex> n
"Ana"
```

### Counterexamples

```elixir
# ❌ Different sizes don't match
iex> {a, b} = {1, 2, 3}
** (MatchError) ...

# ❌ Missing key doesn't match
iex> %{x: n} = %{a: 1}
** (MatchError) ...

# ✅ Key with required pattern
iex> %{age: i} = %{name: "Ana", age: 30}
iex> i
30
```

### Common misconceptions

- **"`=` is assignment."** It's matching. In `a = 1` with `a` free, it works like assignment — but with `a` already bound, it's comparison.
- **"Pattern matching on maps requires all keys."** It doesn't. Only the ones mentioned in the pattern.
- **"I can't nest."** You can, and a lot.

```elixir
iex> %{data: %{name: n}} = %{data: %{name: "Ana", age: 30}}
iex> n
"Ana"
```

### Exercises

```elixir
# 83
{a, b} = {10, 20}
a + b

# 84
[h | _] = [1, 2, 3]
h

# 85
[_, x | _] = [1, 2, 3, 4]
x

# 86
%{name: n} = %{name: "Ana", age: 30}
n

# 87
fn {t, id} -> "#{t}-#{id}" end.({"cat", 1})

# 88
fn {_, %{tf: tf}} -> tf end.({"cat", %{tf: 3, pos: [0]}})
```

**Answer key:**
83. `30`
84. `1`
85. `2`
86. `"Ana"`
87. `"cat-1"`
88. `3`

---

## 20. Guards

### Concept

`when` adds extra conditions to a function head. It only accepts "guard-safe" functions.

```elixir
defmodule M do
  def double(x) when is_integer(x), do: x * 2
  def double(x) when is_binary(x), do: String.duplicate(x, 2)
end

iex> M.double(5)
10
iex> M.double("ab")
"abab"
```

### Counterexamples

```elixir
# ❌ Function is not guard-safe
defmodule M do
  def valid?(x) when String.length(x) > 0, do: x
end
** (CompileError) ...

# ✅ Use a guard-safe one
defmodule M do
  def valid?(x) when is_binary(x) and byte_size(x) > 0, do: x
end
```

### Common misconceptions

- **"Any function works in a guard."** No. Only guard-safe ones (checks, comparisons, simple arithmetic).
- **"Guard is the same as `if`."** No. Guards are **declarative**, they live in the function head.

### Exercises

```elixir
# 89
defmodule Ex do
  def kind(x) when is_integer(x), do: :integer
  def kind(x) when is_binary(x), do: :string
  def kind(_), do: :other
end

Ex.kind(1)
Ex.kind("a")
Ex.kind(:a)
```

**Answer key:** `:integer`, `:string`, `:other`

---

## 21. Multiple function clauses

### Concept

The same function can have multiple clauses. Elixir tries to match from first to last.

```elixir
defmodule F do
  def calc(0), do: 1
  def calc(n), do: n * calc(n - 1)
end

iex> F.calc(5)
120
```

### Counterexamples

Order matters. The general case **before** the specific one kills the specific one:

```elixir
defmodule F do
  def calc(n), do: n * calc(n - 1)  # ❌ never reaches the base case
  def calc(0), do: 1
end
```

### Common misconceptions

- **"The order of clauses doesn't matter."** It matters, a lot.
- **"I need to cover all cases."** You don't, but if nothing matches, you get a runtime error.

### Exercises

```elixir
# 90
defmodule G do
  def f([]), do: 0
  def f([_ | t]), do: 1 + f(t)
end

G.f([1, 2, 3])
```

**Answer key:** `3`

---

## 22. The `in` operator

### Concept

Tests membership in a collection.

```elixir
iex> "cat" in ["cat", "dog"]
true

iex> 5 in 1..10
true

iex> "x" in ~w(a b c)
false
```

### Common misconceptions

- **"`in` works on anything."** It works on lists, ranges, and other collections implementing `Enumerable`.
- **"`in` is case-insensitive."** It's not.

### Exercises

```elixir
# 91
"the" in ~w(a the of)

# 92
"THE" in ~w(a the of)

# 93
5 in 1..10

# 94
11 in 1..10

# 95
~w(a the cat) |> Enum.reject(&(&1 in ~w(a the)))
```

**Answer key:**
91. `true`
92. `false`
93. `true`
94. `false`
95. `["cat"]`

---

## 23. `:math.log/1`

### Concept

Natural logarithm, via Erlang.

```elixir
iex> :math.log(1)
0.0

iex> :math.log(:math.exp(1))
1.0

iex> :math.log(10)
2.302585092994046
```

### Common misconceptions

- **"JS's `Math.log` is different."** It's the same natural log.
- **"I need to `import`."** You don't. It's available directly as `:math.log/1`.
- **"Log of a negative number returns `nan`."** It doesn't — it raises. **[v1-fix]**

```elixir
iex> :math.log(-1)
** (ArithmeticError) bad argument in arithmetic expression ...

iex> :math.log(0)
** (ArithmeticError) ...
```

### Exercises

```elixir
# 96
:math.log(3) > :math.log(2)

# 97
:math.log(3) / :math.log(3)

# 98
:math.log(1) == 0.0
```

**Answer key:** `true`, `1.0`, `true`

---

## 24. Module attributes (`@`)

### Concept

Compile-time constants. `@moduledoc` and `@doc` document.

```elixir
defmodule M do
  @version "1.0.0"
  def version, do: @version
end
```

### Common misconceptions

- **"An attribute is a variable."** It's not. It's evaluated at compile time and "frozen".
- **"I can change it at runtime."** You can't.

### Exercises

```elixir
# 99
defmodule C do
  @stopwords ~w(a the of)
  def stop?(t), do: t in @stopwords
end

C.stop?("the")
C.stop?("cat")
```

**Answer key:** `true`, `false`

---

## 25. `def`, `defp`, `alias`, `use`

### Concept

- `def` — public function.
- `defp` — private function.
- `alias` — module nickname.
- `use` — injects code (used in tests).

### Common misconceptions

- **"defp is just a convention."** It's not. It's truly inaccessible outside the module.

```elixir
defmodule M do
  def pub, do: priv()
  defp priv, do: 42
end

iex> M.pub()
42

iex> M.priv()
** (UndefinedFunctionError) ...
```

### Exercises

```elixir
# 100
defmodule N do
  def a(x), do: b(x) + 1
  defp b(x), do: x * 2
end

N.a(5)
```

**Answer key:** `11`

---

## 26. ExUnit and `mix`

### Concept

Elixir ships with ExUnit. `mix` is the build tool.

```bash
mix new project
cd project
mix test
iex -S mix
```

```elixir
defmodule MyTest do
  use ExUnit.Case

  test "sum" do
    assert 1 + 1 == 2
  end
end
```

### Common misconceptions

- **"I need to install ExUnit."** It's built-in.
- **"I need a config file."** The generated `mix.exs` already has it.
- **"assert is like if."** `assert` **fails the test** if the condition is false.

### Exercises

Create a project, write a simple test and run `mix test`. No answer key — just do it.

---

## Final training: mini-challenges

Without checking the answer key. Write, test, adjust.

**D1.** Use a pipe to transform `"  THE CAT CLIMBED!  "` into `["cat", "climbed"]` — that is: trim, downcase, remove punctuation, split, and remove stopwords.

**D2.** Given the list `~w(cat dog cat fish cat)`, count how many times each word appears, returning a map.

**D3.** Given a list of `{word, doc_id}`, group them into a map `%{word => [doc_ids]}` without duplicates, sorted.

**D4.** Given `%{1 => "a b c", 2 => "a b"}`, compute the count of `"a"` in each document, returning `%{doc_id => count}`.

**D5.** Write a function `intersection/1` that takes a list of lists and returns the elements present in all of them, using `Enum.reduce/3`.

### Answer key

```elixir
# D1
"  THE CAT CLIMBED!  "
|> String.trim()
|> String.downcase()
|> String.replace(~r/[^\p{L}\p{N}\s]/u, " ")
|> String.split(~r/\s+/, trim: true)
|> Enum.reject(&(&1 in ~w(a the of and to in on at for with by)))
# => ["cat", "climbed"]

# D2
~w(cat dog cat fish cat)
|> Enum.reduce(%{}, fn w, acc -> Map.update(acc, w, 1, &(&1 + 1)) end)
# => %{"cat" => 3, "dog" => 1, "fish" => 1}

# D3
[{"cat", 1}, {"cat", 2}, {"fish", 3}, {"cat", 1}]
|> Enum.uniq()
|> Enum.group_by(fn {w, _} -> w end, fn {_, id} -> id end)
|> Map.new(fn {w, ids} -> {w, Enum.sort(ids)} end)
# => %{"cat" => [1, 2], "fish" => [3]}

# D4 — [v1-fix] v1 used Enum.flat_map with a fun returning a tuple,
# which raises Protocol.UndefinedError (tuple is not enumerable).
# ❌ broken (v1):
# %{1 => "a b c", 2 => "a b"}
# |> Enum.flat_map(fn {id, txt} ->
#   txt |> String.split() |> Enum.count(&(&1 == "a")) |> then(fn c -> {id, c} end)
# end)
# |> Map.new()

# ✅ fixed — use Enum.map:
%{1 => "a b c", 2 => "a b"}
|> Enum.map(fn {id, txt} ->
  {id, txt |> String.split() |> Enum.count(&(&1 == "a"))}
end)
|> Map.new()
# => %{1 => 1, 2 => 1}

# D5
def intersection([]), do: []
def intersection([h | t]), do: Enum.reduce(t, h, &(&2 -- (&2 -- &1)))

intersection([[1, 2, 3], [2, 3, 4], [2, 3, 5]])
# => [2, 3]
```

---

## Errata from v1 (errors are learning)

Documenting the v1 mistakes found by `test/article_proof_test.exs` (Elixir 1.20.1 / OTP 29):

1. Sec 1: same `String.replace` pipe shown as both ❌ and ✅. It never raises.
2. Sec 1: `1 + 2 |> IO.puts()` does **not** raise — prints `3`, `:ok` (`+` binds tighter than `|>`).
3. Sec 4: `trim: true` removes **all** empties, not edges only. Ex. 16 fixed to `["a", "b", "c"]`.
4. Sec 6: `"é" =~ ~r/\p{L}/` without `/u` returns `true` here, not `Regex.CompileError`. Keep `/u` anyway.
5. Sec 8: `flat_map` with non-enumerable fun raises `Protocol.UndefinedError`, not `[2, 4]`.
6. Sec 11: `Enum.sort([1, "a", :ok])` returns `[1, :ok, "a"]` (term order), not `ArgumentError`.
7. Sec 13: `Enum.reduce/2` exists — returns `6`, no `FunctionClauseError`.
8. Sec 14: `Enum.with_index(list, 1)` offset form exists since Elixir 1.12.
9. Sec 23: `:math.log(-1)` and `:math.log(0)` raise `ArithmeticError`, not `nan`.
10. D4: `Enum.flat_map` + tuple fun is broken; fixed with `Enum.map`.

---

## Conclusion

If you **typed** every example, saw each error on purpose, and solved the mini-challenges, you're ready.

The inverted index tutorial will use **exactly** these blocks:

- `|>`, `String.*`, `~w`, `~r/u`
- `Enum.map/flat_map/filter/reject/uniq/sort/sort_by/group_by/reduce/with_index`
- `Map.new/get/update`
- `&`, pattern matching, guards, multiple clauses
- `in`, `:math.log/1`, `@` attributes
- `def`, `defp`, `alias`, ExUnit, mix

See you there. 🚀
