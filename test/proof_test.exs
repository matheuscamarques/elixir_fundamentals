# SINGLE-FILE PROOF SUITE — the only .exs file used for future Elixir finetuning.
# Contents: (1) ArticleProofTest — 100 fundamentals exercises + D1-D5 with
# 5W1H/STAR docs; (2) article modules inlined (Tokenizer, InvertedIndex,
# TFIDF — this repo never uses /lib); (3) InvertedIndexProofTest — inverted
# index to TF-IDF proofs. Natural-language comments pair with asserts so each
# block works as an instruction/response training pair.
# Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
defmodule ArticleProofTest do
  # Test documentation convention (English, natural language):
  # - 5W1H answers Who (reader/prover), What (behavior proven), When/Where
  #   (article section, Elixir 1.20.1/OTP 29), Why (which misconception it kills),
  #   How (assertion strategy).
  # - STAR answers Situation (the article claim), Task (what must be proven),
  #   Action (what the test executes), Result (expected outcome).
  # Every test below carries both lines so humans and AI readers know exactly
  # what is proven and why it matters for the inverted-index tutorial.
  use ExUnit.Case, async: true

  # Hides literal types from the compiler's type checker so intentional
  # counterexamples (wrong types, missing keys) don't emit type warnings
  # but still raise/return at runtime. The binary round-trip is opaque:
  # the compiler only knows the result is term().
  defp opaque(term), do: :erlang.binary_to_term(:erlang.term_to_binary(term))

  # ============================================================
  # 1. Pipe operator |>
  # ============================================================
  describe "section 1: pipe" do
    # 5W1H | Who: prover/reader. What: pipe basics send value as 1st arg. When/Where: article sec.1, Elixir 1.20. How: direct asserts. Why: the whole tutorial is pipelines.
    # STAR | Situation: article shows upcase/reverse/replace via |>. Task: lock the happy path. Action: assert each pipeline result. Result: all pass.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "basic examples" do
      assert "hello" |> String.upcase() == "HELLO"
      assert "hello" |> String.upcase() |> String.reverse() == "OLLEH"
      assert String.replace("hello world", "world", "elixir") == "hello elixir"
      # pipe passes as first arg, so this is identical to the line above
      assert "hello world" |> String.replace("world", "elixir") == "hello elixir"
    end

    # 5W1H | Who: trainee. What: answers to exercises 1,3,4 (chained pipes). When/Where: article sec.1. How: predict-then-assert. Why: builds pipe muscle memory.
    # STAR | Situation: three pipe chains with known outputs. Task: freeze them. Action: assert each value. Result: 3, "CBA", "CB".
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "exercises 1-4" do
      assert ("abc" |> String.upcase() |> String.length()) == 3
      assert String.upcase("abc") |> String.reverse() == "CBA"
      assert ("abc" |> String.reverse() |> String.upcase() |> String.slice(0, 2)) == "CB"
    end

    # 5W1H | Who: prover. What: exercise 2 must FAIL (upcase on an integer). When/Where: article sec.1. How: assert_raise. Why: teaches that pipes do not coerce types.
    # STAR | Situation: "abc" |> length() yields 3, then upcase(3). Task: prove it raises. Action: run inside assert_raise. Result: FunctionClauseError.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "exercise 2 raises (upcase on integer)" do
      assert_raise FunctionClauseError, fn ->
        "abc" |> String.length() |> String.upcase()
      end
    end
  end

  # ============================================================
  # 2. String.downcase/1
  # ============================================================
  describe "section 2: downcase" do
    # 5W1H | Who: reader. What: downcase handles ASCII sentences and accents. When/Where: article sec.2. How: equality asserts. Why: normalization step of tokenization.
    # STAR | Situation: "CAT", a sentence, "AÇÃO". Task: lock lowercase outputs. Action: assert each. Result: "cat", full sentence, "ação".
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "examples" do
      assert String.downcase("CAT") == "cat"
      assert String.downcase("The Cat Climbed The Roof") == "the cat climbed the roof"
      assert String.downcase("AÇÃO") == "ação"
    end

    # 5W1H | Who: prover. What: downcase rejects non-binaries (42, nil). When/Where: article sec.2 counterexamples. How: assert_raise with opaque/1 hiding literals from the type checker. Why: proves binary-only contract.
    # STAR | Situation: article claims FunctionClauseError for 42/nil. Task: verify. Action: call downcase on opaque values. Result: FunctionClauseError twice.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "counterexamples raise" do
      assert_raise FunctionClauseError, fn -> String.downcase(opaque(42)) end
      assert_raise FunctionClauseError, fn -> String.downcase(opaque(nil)) end
    end

    # 5W1H | Who: trainee. What: answers 5-8 (mixed case, empty string, cedilla, accented length). When/Where: article sec.2. How: value asserts. Why: edge cases of normalization.
    # STAR | Situation: four downcase facts incl. Unicode. Task: freeze them. Action: assert each. Result: "hello world", true, true, 3.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "exercises 5-8" do
      assert String.downcase("HELLO World") == "hello world"
      assert (String.downcase("") == "") == true
      assert (String.downcase("Ç") == "ç") == true
      assert String.length(String.downcase("ÉÀÇ")) == 3
    end
  end

  # ============================================================
  # 3. String.replace/3
  # ============================================================
  describe "section 3: replace" do
    # 5W1H | Who: reader. What: replace erases ("") vs separates (" ") incl. regex separators. When/Where: article sec.3, the tutorial's classic pitfall. How: equality asserts. Why: punctuation handling decides token quality.
    # STAR | Situation: "" vs " " replacement with strings and regexes. Task: lock the difference. Action: assert all seven cases. Result: all pass.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "examples" do
      assert String.replace("good morning", "morning", "night") == "good night"
      assert String.replace("a-a-a", "a", "b") == "b-b-b"
      assert String.replace("a1b2c3", ~r/\d/, "*") == "a*b*c*"
      assert String.replace("end.start", ".", "") == "endstart"
      assert String.replace("end.start", ".", " ") == "end start"
      assert String.replace("a,b;c.d", ~r/[,;.]/, "") == "abcd"
      assert String.replace("a,b;c.d", ~r/[,;.]/, " ") == "a b c d"
    end

    # 5W1H | Who: trainee. What: answers 9-13 (vowels, spaces, SSN digits, silent-a removal). When/Where: article sec.3. How: value asserts. Why: repetition on replacement semantics.
    # STAR | Situation: five replace exercises. Task: freeze outputs. Action: assert each. Result: "bonono", "abc", "a_b_c", "12345678900", "pinepple".
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "exercises 9-13" do
      assert String.replace("banana", "a", "o") == "bonono"
      assert String.replace("a b c", " ", "") == "abc"
      assert String.replace("a b c", " ", "_") == "a_b_c"
      assert String.replace("ssn: 123.456.789-00", ~r/\D/, "") == "12345678900"
      assert String.replace("pineapple", "a", "") == "pinepple"
    end

    # 5W1H | Who: prover. What: replace is global and case-sensitive. When/Where: article sec.3 misconceptions. How: two asserts. Why: kills "only first occurrence" and "ignores case" myths.
    # STAR | Situation: "aaa" and "Aaa" with pattern "a". Task: prove all-match + case matters. Action: assert both. Result: "bbb" and "Abb".
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "replace is global + case sensitive" do
      assert String.replace("aaa", "a", "b") == "bbb"
      assert String.replace("Aaa", "a", "b") == "Abb"
    end
  end

  # ============================================================
  # 4. String.split/2,3
  # ============================================================
  describe "section 4: split" do
    # 5W1H | Who: reader. What: default split vs "," vs " " vs ~r/\s+/ on multi-spaces. When/Where: article sec.4. How: list asserts. Why: splitting is the tokenizer core.
    # STAR | Situation: six split behaviors incl. empty-string artifacts. Task: freeze them. Action: assert each list. Result: all pass.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "examples (correct claims)" do
      assert String.split("cat dog") == ["cat", "dog"]
      assert String.split("a,b,c", ",") == ["a", "b", "c"]
      assert String.split("cat   dog", ~r/\s+/) == ["cat", "dog"]
      assert String.split("cat   dog", " ") == ["cat", "", "", "dog"]
      assert String.split("a   b   c", ~r/\s+/) == ["a", "b", "c"]
      assert String.split("a   b   c", " ") == ["a", "", "", "b", "", "", "c"]
    end

    # 5W1H | Who: trainee. What: answers 14,15,17,18 (untouched article claims). When/Where: article sec.4. How: value asserts. Why: repetition on separator choice.
    # STAR | Situation: four split exercises. Task: freeze outputs. Action: assert each incl. middle empties kept. Result: all pass.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "exercises 14,15,17,18 (correct)" do
      assert String.split("a b c") == ["a", "b", "c"]
      assert String.split("a,b,,c", ",") == ["a", "b", "", "c"]
      assert String.split("a   b   c", ~r/\s+/) == ["a", "b", "c"]
      assert String.split("a   b   c", " ") == ["a", "", "", "b", "", "", "c"]
    end

    # 5W1H | Who: prover + future AI reader. What: v1 article error — trim:true removes ALL empties, not edges only. When/Where: article sec.4, Elixir 1.20. How: asserts on real outputs. Why: this exact myth corrupts tokenizers.
    # STAR | Situation: v1 claimed ["a","","b"] and ["a","b","","c"]. Task: prove actual. Action: split with trim:true and without. Result: ["a","b"], ["a","b","c"], full empties list.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    @tag :documented_error
    test "trim: true removes ALL empties, not only edges (article error documented)" do
      # Article claims ["a", "", "b"] and ["a","b","","c"] — actually:
      assert String.split("  a  b  ", " ", trim: true) == ["a", "b"]
      assert String.split("a,b,,c", ",", trim: true) == ["a", "b", "c"]
      assert String.split("  a  b  ", " ") == ["", "", "a", "", "b", "", ""]
    end
  end

  # ============================================================
  # 5. Sigil ~w
  # ============================================================
  describe "section 5: ~w" do
    # 5W1H | Who: reader. What: ~w splits on spaces (commas stick), plus atom modifier. When/Where: article sec.5 stopword lists. How: asserts; comma case via runtime eval with stderr captured. Why: stopword literals must be exact.
    # STAR | Situation: space-split vs comma confusion. Task: prove commas become token chars. Action: assert plain, runtime-eval comma, atom, numeric cases. Result: all pass.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "examples" do
      assert ~w(a the of for) == ["a", "the", "of", "for"]
      # ~w splits on spaces only, so commas stick to the token.
      # Evaluated at runtime to avoid the compile-time sigil trailing-comma warning;
      # stderr captured since the sigil itself warns at runtime (which is the point).
      comma_words =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          send(self(), {:comma_words, Code.eval_string("~w(a, the, of)") |> elem(0)})
        end)
        |> then(fn _ -> receive do {:comma_words, v} -> v end end)

      assert comma_words == ["a,", "the,", "of"]
      assert ~w(a b c)a == [:a, :b, :c]
      assert ~w(1 2 3) == ["1", "2", "3"]
    end

    # 5W1H | Who: trainee. What: answers 19-22 (equality, order matters, duplicates count, membership). When/Where: article sec.5. How: boolean asserts. Why: list semantics for stopwords.
    # STAR | Situation: four ~w facts. Task: freeze them. Action: assert each. Result: true, false, 4, true.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "exercises 19-22" do
      assert (~w(cat dog fish) == ["cat", "dog", "fish"]) == true
      assert (~w(a b c) == ~w(c b a)) == false
      assert length(~w(a a a a)) == 4
      assert ("cat" in ~w(cat dog)) == true
    end
  end

  # ============================================================
  # 6. Regex /u
  # ============================================================
  describe "section 6: regex" do
    # 5W1H | Who: reader. What: \d, \p{L}+/u, and the negated class [^\p{L}\p{N}\s]/u. When/Where: article sec.6, punctuation detector of the tokenizer. How: =~ asserts. Why: this regex decides what is punctuation.
    # STAR | Situation: eight matching facts. Task: freeze them. Action: assert each boolean. Result: all pass.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "examples" do
      assert ("cat123" =~ ~r/\d/) == true
      assert ("cat123" =~ ~r/\p{L}+/u) == true
      assert ("123" =~ ~r/\p{L}/u) == false
      assert ("é" =~ ~r/\p{L}/u) == true
      assert ("hello" =~ ~r/[^\p{L}\p{N}\s]/u) == false
      assert ("hello!" =~ ~r/[^\p{L}\p{N}\s]/u) == true
      assert ("a b" =~ ~r/[^\p{L}\p{N}\s]/u) == false
      assert ("a-b" =~ ~r/[^\p{L}\p{N}\s]/u) == true
    end

    # 5W1H | Who: trainee. What: answers 23-29 (negated-class true/false incl. empty string). When/Where: article sec.6. How: boolean asserts. Why: repetition on "match means HAS punctuation".
    # STAR | Situation: seven =~ exercises. Task: freeze them. Action: assert each. Result: all pass, empty string is false.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "exercises 23-29" do
      assert ("abc" =~ ~r/[^\p{L}\p{N}\s]/u) == false
      assert ("abc!" =~ ~r/[^\p{L}\p{N}\s]/u) == true
      assert ("123" =~ ~r/[^\p{L}\p{N}\s]/u) == false
      assert ("a b" =~ ~r/[^\p{L}\p{N}\s]/u) == false
      assert ("a.b" =~ ~r/[^\p{L}\p{N}\s]/u) == true
      assert ("" =~ ~r/[^\p{L}\p{N}\s]/u) == false
      assert ("a  b" =~ ~r/[^\p{L}\p{N}\s]/u) == false
    end

    # 5W1H | Who: prover + future AI reader. What: v1 error — \p without /u does NOT raise on OTP 29. When/Where: article sec.6, Elixir 1.20.1/OTP 29. How: direct =~ asserts. Why: keeps the /u rule while fixing the claimed error type.
    # STAR | Situation: v1 claimed Regex.CompileError for "é". Task: prove actual. Action: match with and without /u. Result: true both times, no raise.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    @tag :documented_error
    test "\\p without /u does NOT raise on Elixir 1.20/OTP29 (article error documented)" do
      # Article claims ** (Regex.CompileError) for "é" =~ ~r/\p{L}/
      assert ("cat" =~ ~r/\p{L}/) == true
      assert ("é" =~ ~r/\p{L}/) == true
    end
  end

  # ============================================================
  # 7. Enum.map/2
  # ============================================================
  describe "section 7: map" do
    # 5W1H | Who: trainee. What: map preserves size, never flattens/filters; examples plus answers 30-34. When/Where: article sec.7. How: list asserts. Why: map-vs-flat_map confusion is the top Enum bug.
    # STAR | Situation: nine map facts incl. nested lists and booleans. Task: freeze them. Action: assert each. Result: all pass.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "examples + exercises 30-34" do
      assert Enum.map([1, 2, 3], fn x -> x * 2 end) == [2, 4, 6]
      assert Enum.map(["a", "b"], fn s -> String.upcase(s) end) == ["A", "B"]
      assert Enum.map([[1, 2], [3, 4]], fn l -> l end) == [[1, 2], [3, 4]]
      assert Enum.map([1, 2, 3, 4], fn x -> x > 2 end) == [false, false, true, true]
      assert Enum.map([1, 2, 3], fn x -> x + 1 end) == [2, 3, 4]
      assert Enum.map(["a", "b"], fn s -> s <> s end) == ["aa", "bb"]
      assert Enum.map([1, 2, 3], fn x -> x > 1 end) == [false, true, true]
      assert Enum.map([[1], [2, 3]], fn l -> length(l) end) == [1, 2]
      assert Enum.map([], fn x -> x end) == []
    end
  end

  # ============================================================
  # 8. Enum.flat_map/2
  # ============================================================
  describe "section 8: flat_map" do
    # 5W1H | Who: reader. What: flat_map flattens exactly one level; answers 35-38 shape. When/Where: article sec.8. How: list asserts. Why: one-level rule surprises everyone.
    # STAR | Situation: seven flat_map cases incl. graphemes and nested wrap. Task: freeze one-level behavior. Action: assert each. Result: all pass.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "examples + exercises (correct claims)" do
      assert Enum.flat_map([[1, 2], [3, 4]], fn l -> l end) == [1, 2, 3, 4]
      assert Enum.flat_map(["a b", "c d"], fn s -> String.split(s) end) == ["a", "b", "c", "d"]
      assert Enum.flat_map([[[1]], [[2]]], fn l -> l end) == [[1], [2]]
      assert Enum.flat_map([1, 2, 3], fn x -> [x, x] end) == [1, 1, 2, 2, 3, 3]
      assert Enum.flat_map(["ab", "cd"], fn s -> String.graphemes(s) end) == ["a", "b", "c", "d"]
      assert Enum.flat_map([1, 2], fn _ -> [] end) == []
      assert Enum.flat_map([1, 2], fn x -> [[x]] end) == [[1], [2]]
    end

    # 5W1H | Who: prover + future AI reader. What: v1 error — flat_map with a non-enumerable fun RAISES. When/Where: article sec.8. How: assert_raise. Why: AIs repeatedly emit flat_map where map belongs.
    # STAR | Situation: v1 claimed [2,4]. Task: prove the raise. Action: run flat_map with x*2. Result: Protocol.UndefinedError.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    @tag :documented_error
    test "flat_map with non-list fun raises (article error documented)" do
      # Article claims Enum.flat_map([1,2], fn x -> x*2 end) == [2,4]
      assert_raise Protocol.UndefinedError, fn ->
        Enum.flat_map([1, 2], fn x -> x * 2 end)
      end
    end
  end

  # ============================================================
  # 9. Enum.filter/reject
  # ============================================================
  describe "section 9: filter/reject" do
    # 5W1H | Who: trainee. What: answers 39-44 — filter keeps, reject drops, opposites under negation. When/Where: article sec.9 stopword removal. How: list asserts. Why: stopword filtering is reject(&(&1 in stopwords)).
    # STAR | Situation: six filter/reject facts incl. stopword lists. Task: freeze them. Action: assert each. Result: all pass.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "exercises 39-44" do
      assert Enum.filter([1, 2, 3], fn x -> x > 1 end) == [2, 3]
      assert Enum.reject([1, 2, 3], fn x -> x > 1 end) == [1]
      assert Enum.filter(~w(a the cat of), fn t -> t in ~w(a the of) end) == ["a", "the", "of"]
      assert Enum.reject(~w(a the cat of), fn t -> t in ~w(a the of) end) == ["cat"]
      assert Enum.filter([1, 2, 3], fn _ -> true end) == [1, 2, 3]
      assert Enum.reject([1, 2, 3], fn _ -> false end) == [1, 2, 3]
      assert Enum.reject([1, 2, 3, 4], fn x -> x <= 2 end) == [3, 4]
    end
  end

  # ============================================================
  # 10. Enum.uniq/1
  # ============================================================
  describe "section 10: uniq" do
    # 5W1H | Who: trainee. What: answers 45-48 — first occurrence kept, order kept, no sorting. When/Where: article sec.10. How: list asserts incl. pipe into sort. Why: dedup before postings.
    # STAR | Situation: six uniq facts. Task: freeze them. Action: assert each. Result: all pass.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "exercises 45-48" do
      assert Enum.uniq([1, 1, 1]) == [1]
      assert Enum.uniq([3, 1, 3, 2, 1]) == [3, 1, 2]
      assert Enum.uniq(["a", "A", "a"]) == ["a", "A"]
      assert ([1, 2, 2, 3] |> Enum.uniq() |> Enum.sort()) == [1, 2, 3]
      assert Enum.uniq([3, 1, 2, 1, 3]) == [3, 1, 2]
      assert ([3, 1, 2, 1, 3] |> Enum.uniq() |> Enum.sort()) == [1, 2, 3]
    end

    # 5W1H | Who: prover. What: uniq compares with strict === (1 vs 1.0 both survive). When/Where: article sec.10 misconception. How: single assert. Why: numeric dedup semantics.
    # STAR | Situation: 1 == 1.0 but not ===. Task: prove strictness. Action: uniq([1, 1.0]). Result: [1, 1.0].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "uniq uses strict === comparison" do
      # 1 == 1.0 but not 1 === 1.0, and uniq keeps both => proves ===
      assert Enum.uniq([1, 1.0]) == [1, 1.0]
    end
  end

  # ============================================================
  # 11. Enum.sort/sort_by
  # ============================================================
  describe "section 11: sort" do
    # 5W1H | Who: trainee. What: sort/sort_by incl. length-tie stability and case-sensitive strings; answers 49-53. When/Where: article sec.11. How: list asserts. Why: sorted postings need deterministic order.
    # STAR | Situation: seven ordering facts. Task: freeze them. Action: assert each. Result: all pass.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "correct claims + exercises 49-53" do
      assert Enum.sort([3, 1, 2]) == [1, 2, 3]
      assert Enum.sort(["c", "a", "b"]) == ["a", "b", "c"]
      assert Enum.sort_by([3, 1, 2], fn x -> -x end) == [3, 2, 1]
      assert Enum.sort_by(["banana", "grape", "apple"], fn s -> String.length(s) end) == ["grape", "apple", "banana"]
      assert Enum.sort_by([{2, "a"}, {1, "b"}], fn {n, _} -> n end) == [{1, "b"}, {2, "a"}]
      assert Enum.sort(["banana", "Apple", "grape"]) == ["Apple", "banana", "grape"]
      assert Enum.sort_by([{1, "b"}, {2, "a"}], fn {_, l} -> l end) == [{2, "a"}, {1, "b"}]
    end

    # 5W1H | Who: prover + future AI reader. What: v1 error — mixed-type sort does NOT raise; Erlang term order applies. When/Where: article sec.11. How: single assert. Why: AIs invent ArgumentError here.
    # STAR | Situation: v1 claimed ArgumentError. Task: prove actual. Action: sort [1, "a", :ok]. Result: [1, :ok, "a"].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    @tag :documented_error
    test "sort of mixed types does NOT raise (article error documented)" do
      # Article claims ** (ArgumentError); term ordering applies instead:
      # number < atom < binary
      assert Enum.sort([1, "a", :ok]) == [1, :ok, "a"]
    end
  end

  # ============================================================
  # 12. Enum.group_by
  # ============================================================
  describe "section 12: group_by" do
    # 5W1H | Who: trainee. What: group_by/2 keys plus /3 value transform; answers 54-57 incl. downcase normalization. When/Where: article sec.12, postings grouped by term. How: map asserts. Why: key-vs-value fun confusion is common.
    # STAR | Situation: eight grouping facts. Task: freeze them. Action: assert each map. Result: all pass.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "examples + exercises 54-57" do
      assert Enum.group_by([1, 2, 3, 4], fn x -> rem(x, 2) end) == %{0 => [2, 4], 1 => [1, 3]}

      assert Enum.group_by([1, 2, 3, 4], fn x -> rem(x, 2) end, fn x -> x * 10 end) ==
               %{0 => [20, 40], 1 => [10, 30]}

      assert Enum.group_by(["cat", "CAT"], fn s -> s end) == %{"cat" => ["cat"], "CAT" => ["CAT"]}

      assert Enum.group_by(["cat", "CAT"], fn s -> String.downcase(s) end) == %{
               "cat" => ["cat", "CAT"]
             }

      assert Enum.group_by([1, 2, 3, 4, 5], fn x -> rem(x, 3) end) == %{
               0 => [3],
               1 => [1, 4],
               2 => [2, 5]
             }

      assert Enum.group_by(["a", "bb", "c", "dd"], fn s -> String.length(s) end) == %{
               1 => ["a", "c"],
               2 => ["bb", "dd"]
             }

      assert Enum.group_by(["a", "bb", "c"], fn s -> String.length(s) end, fn s -> String.upcase(s) end) ==
               %{1 => ["A", "C"], 2 => ["BB"]}

      assert Enum.group_by(~w(cat cat dog), fn t -> t end) == %{"cat" => ["cat", "cat"], "dog" => ["dog"]}
    end
  end

  # ============================================================
  # 13. Enum.reduce/3
  # ============================================================
  describe "section 13: reduce" do
    # 5W1H | Who: trainee. What: reduce builds sums, strings, filtered lists, maps; answers 58-62. When/Where: article sec.13. How: value asserts. Why: reduce is the accumulator workhorse.
    # STAR | Situation: seven reduce facts incl. returning elem vs acc. Task: freeze them. Action: assert each. Result: all pass.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "examples + exercises 58-62" do
      assert Enum.reduce([1, 2, 3, 4], 0, fn x, acc -> acc + x end) == 10
      assert Enum.reduce([1, 2, 3], 0, fn x, _acc -> x end) == 3
      assert Enum.reduce([1, 2, 3], 0, fn x, acc -> acc + x end) == 6
      assert Enum.reduce([1, 2, 3], 1, fn x, acc -> acc * x end) == 6
      assert Enum.reduce(["a", "b", "c"], "", fn s, acc -> acc <> s end) == "abc"

      assert Enum.reduce([1, 2, 3, 4], [], fn x, acc ->
               if rem(x, 2) == 0, do: acc ++ [x], else: acc
             end) == [2, 4]

      assert Enum.reduce(["a", "b", "c"], %{}, fn s, acc -> Map.put(acc, s, String.length(s)) end) ==
               %{"a" => 1, "b" => 1, "c" => 1}
    end

    # 5W1H | Who: prover + future AI reader. What: v1 error — reduce/2 EXISTS and sums with first elem as acc. When/Where: article sec.13. How: single assert. Why: prefer explicit reduce/3 but know /2 works.
    # STAR | Situation: v1 claimed FunctionClauseError. Task: prove actual. Action: reduce without initial. Result: 6.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    @tag :documented_error
    test "reduce/2 exists and does NOT raise (article error documented)" do
      # Article claims FunctionClauseError; actually uses first elem as acc:
      assert Enum.reduce([1, 2, 3], fn x, acc -> acc + x end) == 6
    end
  end

  # ============================================================
  # 14. Enum.with_index
  # ============================================================
  describe "section 14: with_index" do
    # 5W1H | Who: trainee. What: with_index pairs {elem, 0-based idx} plus fun form; answers 63-66. When/Where: article sec.14 positions for postings. How: tuple asserts. Why: index base 0 vs 1 confusion.
    # STAR | Situation: six with_index facts. Task: freeze them. Action: assert each. Result: all pass.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "correct claims + exercises 63-66" do
      assert Enum.with_index(["a", "b", "c"]) == [{"a", 0}, {"b", 1}, {"c", 2}]
      assert Enum.with_index(["x", "y"]) == [{"x", 0}, {"y", 1}]
      assert Enum.with_index([10, 20, 30]) == [{10, 0}, {20, 1}, {30, 2}]
      assert Enum.with_index(["a", "b"], fn el, i -> {el, i * 2} end) == [{"a", 0}, {"b", 2}]
      assert Enum.with_index(["a", "b"], fn el, i -> {el, i + 100} end) == [{"a", 100}, {"b", 101}]

      assert ([10, 20, 30] |> Enum.with_index() |> Enum.map(fn {v, _} -> v end)) == [10, 20, 30]
    end

    # 5W1H | Who: prover + future AI reader. What: v1 error — with_index/2 integer offset EXISTS since Elixir 1.12. When/Where: article sec.14. How: single assert. Why: outdated "no offset" knowledge.
    # STAR | Situation: v1 claimed UndefinedFunctionError. Task: prove actual. Action: with_index(["a","b"], 1). Result: [{"a",1},{"b",2}].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    @tag :documented_error
    test "with_index/2 with offset EXISTS (article error documented)" do
      # Article claims UndefinedFunctionError; since Elixir 1.12 offset works:
      assert Enum.with_index(["a", "b"], 1) == [{"a", 1}, {"b", 2}]
    end
  end

  # ============================================================
  # 15. Map.new
  # ============================================================
  describe "section 15: Map.new" do
    # 5W1H | Who: trainee. What: Map.new from tuples, /2 fun form, last-wins duplicates; answers 67-70. When/Where: article sec.15 index maps. How: map asserts. Why: map-building basics.
    # STAR | Situation: six Map.new facts. Task: freeze them. Action: assert each. Result: all pass.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "examples + exercises 67-70" do
      assert Map.new([{:a, 1}, {:b, 2}]) == %{a: 1, b: 2}
      assert Map.new([1, 2, 3], fn x -> {x, x * x} end) == %{1 => 1, 2 => 4, 3 => 9}
      assert Map.new([{:a, 1}, {:a, 2}]) == %{a: 2}
      assert Map.new(["a", "bb"], fn s -> {s, String.length(s)} end) == %{"a" => 1, "bb" => 2}
      assert (Map.new([1, 2], fn x -> {x, x} end) |> Map.get(1)) == 1
      assert Map.new([{:a, 1}, {:a, 2}])[:a] == 2
    end

    # 5W1H | Who: prover. What: Map.new requires 2-tuples; plain list raises ArgumentError. When/Where: article sec.15 counterexamples. How: assert_raise with opaque/1 hiding the literal. Why: shape contract of Map.new/1.
    # STAR | Situation: Map.new([1,2,3]). Task: prove it raises. Action: run inside assert_raise. Result: ArgumentError.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "bad list raises ArgumentError" do
      assert_raise ArgumentError, fn -> Map.new(opaque([1, 2, 3])) end
    end
  end

  # ============================================================
  # 16. Map.get
  # ============================================================
  describe "section 16: Map.get" do
    # 5W1H | Who: trainee. What: get returns nil or default on miss; answers 71-74 incl. flat_map over lookups. When/Where: article sec.16 posting lookups. How: value asserts with opaque/1 on missing keys. Why: miss-handling is the postings-lookup pattern.
    # STAR | Situation: seven Map.get facts. Task: freeze nil-vs-default. Action: assert each. Result: all pass, D7-style lookup yields [1].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "examples + exercises 71-74" do
      assert Map.get(%{a: 1}, :a) == 1
      assert Map.get(%{a: 1}, opaque(:z)) == nil
      assert Map.get(%{a: 1}, opaque(:z), 0) == 0
      assert Map.get(%{"cat" => [1, 2]}, "cat") == [1, 2]
      assert Map.get(%{"cat" => [1, 2]}, opaque("dog")) == nil
      assert Map.get(%{"cat" => [1, 2]}, opaque("dog"), []) == []
      assert (~w(cat dog) |> Enum.flat_map(fn t -> Map.get(%{"cat" => [1]}, t, []) end)) == [1]
    end
  end

  # ============================================================
  # 17. Map.update/4
  # ============================================================
  describe "section 17: Map.update" do
    # 5W1H | Who: trainee. What: update runs fun only if key exists else inserts default; answers 75-78 incl. frequency counting. When/Where: article sec.17 counters. How: map asserts. Why: fun-vs-default confusion breaks counters.
    # STAR | Situation: seven update facts incl. never-runs fun. Task: freeze them. Action: assert each. Result: all pass, counts %{1=>2,2=>1}.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "examples + exercises 75-78" do
      assert Map.update(%{a: 1}, :a, 0, fn v -> v + 10 end) == %{a: 11}
      assert Map.update(%{a: 1}, :b, 100, fn v -> v + 10 end) == %{a: 1, b: 100}
      assert Map.update(%{a: 1}, :a, 999, fn v -> v + 1 end) == %{a: 2}
      assert Map.update(%{}, :a, 100, fn _ -> raise "never runs" end) == %{a: 100}
      assert Map.update(%{}, :a, 1, fn v -> v + 100 end) == %{a: 1}
      assert Map.update(%{a: 1}, :b, 0, fn v -> v + 1 end) == %{a: 1, b: 0}

      assert Enum.reduce([1, 1, 2], %{}, fn x, acc -> Map.update(acc, x, 1, fn v -> v + 1 end) end) ==
               %{1 => 2, 2 => 1}
    end
  end

  # ============================================================
  # 18. & capture
  # ============================================================
  describe "section 18: capture" do
    # 5W1H | Who: trainee. What: & capture equals fn forms; answers 79-82. When/Where: article sec.18 concise Enum callbacks. How: equivalence asserts. Why: capture readability in pipelines.
    # STAR | Situation: four fn-vs-& pairs. Task: prove equivalence. Action: assert each pair equal. Result: all pass.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "examples + exercises 79-82" do
      assert Enum.map([1, 2, 3], &(&1 * 2)) == [2, 4, 6]
      assert Enum.map(["a", "b"], &String.upcase/1) == ["A", "B"]
      assert Enum.map([1, 2], &(&1 + 1)) == Enum.map([1, 2], fn x -> x + 1 end)
      assert Enum.filter([1, 2, 3], &(&1 > 1)) == Enum.filter([1, 2, 3], fn x -> x > 1 end)
      assert Enum.map(["a"], &String.upcase/1) == Enum.map(["a"], fn s -> String.upcase(s) end)

      assert Enum.reject(~w(a the cat), &(&1 in ~w(a the))) ==
               Enum.reject(~w(a the cat), fn t -> t in ~w(a the) end)
    end

    # 5W1H | Who: prover. What: &1 and &Mod without arity do NOT compile. When/Where: article sec.18 counterexamples. How: assert_raise CompileError with stderr captured. Why: capture-syntax boundaries.
    # STAR | Situation: two invalid captures. Task: prove CompileError. Action: compile strings. Result: CompileError twice; &Mod/arity compiles.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "&1 outside capture does not compile" do
      # Diagnostics go to stderr; capture to keep suite output clean.
      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        assert_raise CompileError, fn -> Code.compile_string("&1") end
      end)

      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        assert_raise CompileError, fn -> Code.compile_string("&String.upcase") end
      end)

      # With /arity it compiles fine (returns [] / module list, must not raise):
      assert Code.compile_string("&String.upcase/1") |> is_list()
    end
  end

  # ============================================================
  # 19. Pattern matching
  # ============================================================
  describe "section 19: pattern matching" do
    # 5W1H | Who: trainee. What: answers 83-88 — tuples, head/tail, map keys, nested destructure in fn heads. When/Where: article sec.19. How: IIFE asserts. Why: matching is Elixir's core data access.
    # STAR | Situation: eight matching facts. Task: freeze them. Action: assert each extraction. Result: 30, 1, 2, "Ana", "cat-1", 3...
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "exercises 83-88" do
      assert (fn -> {a, b} = {10, 20}; a + b end).() == 30
      assert (fn -> [h | _] = [1, 2, 3]; h end).() == 1
      assert (fn -> [_, x | _] = [1, 2, 3, 4]; x end).() == 2
      assert (fn -> %{name: n} = %{name: "Ana", age: 30}; n end).() == "Ana"
      assert (fn {t, id} -> "#{t}-#{id}" end).({"cat", 1}) == "cat-1"
      assert (fn {_, %{tf: tf}} -> tf end).({"cat", %{tf: 3, pos: [0]}}) == 3
      assert (fn -> %{age: i} = %{name: "Ana", age: 30}; i end).() == 30
      assert (fn -> %{data: %{name: n}} = %{data: %{name: "Ana", age: 30}}; n end).() == "Ana"
    end

    # 5W1H | Who: prover. What: shape mismatch raises MatchError (tuple size, missing key). When/Where: article sec.19 counterexamples. How: assert_raise via eval_string. Why: matching is strict.
    # STAR | Situation: {a,b}={1,2,3} and %{x:} on %{a:}. Task: prove MatchError. Action: eval both. Result: MatchError twice.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "mismatches raise MatchError" do
      assert_raise MatchError, fn -> Code.eval_string("{a, b} = {1, 2, 3}") end
      assert_raise MatchError, fn -> Code.eval_string("%{x: n} = %{a: 1}") end
    end
  end

  # ============================================================
  # 22. in operator
  # ============================================================
  describe "section 22: in" do
    # 5W1H | Who: trainee. What: answers 91-95 — list/range membership, case-sensitive, reject-stopwords pipe. When/Where: article sec.22. How: boolean asserts. Why: `in` is the stopword test.
    # STAR | Situation: five membership facts. Task: freeze them. Action: assert each. Result: true, false, true, false, ["cat"].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "exercises 91-95" do
      assert ("the" in ~w(a the of)) == true
      assert ("THE" in ~w(a the of)) == false
      assert (5 in 1..10) == true
      assert (11 in 1..10) == false
      assert (~w(a the cat) |> Enum.reject(&(&1 in ~w(a the)))) == ["cat"]
    end
  end

  # ============================================================
  # 23. :math.log/1
  # ============================================================
  describe "section 23: math.log" do
    # 5W1H | Who: trainee. What: answers 96-98 — natural log ordering, self-ratio 1.0, log(1)==0.0. When/Where: article sec.23 IDF scoring. How: float asserts. Why: log is the IDF math.
    # STAR | Situation: three log facts. Task: freeze them. Action: assert each. Result: true, 1.0, true.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "exercises 96-98" do
      assert (:math.log(3) > :math.log(2)) == true
      assert (:math.log(3) / :math.log(3)) == 1.0
      assert (:math.log(1) == 0.0) == true
      assert :math.log(1) == 0.0
      assert :math.log(:math.exp(1)) == 1.0
    end

    # 5W1H | Who: prover + future AI reader. What: v1 error — log of negative/zero RAISES ArithmeticError, not nan. When/Where: article sec.23. How: assert_raise. Why: AIs hallucinate nan here.
    # STAR | Situation: v1 claimed nan. Task: prove the raise. Action: log(-1) and log(0). Result: ArithmeticError twice.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    @tag :documented_error
    test "log of negative/zero raises (article error documented)" do
      # Article claims "returns nan"; actually raises ArithmeticError:
      assert_raise ArithmeticError, fn -> :math.log(-1) end
      assert_raise ArithmeticError, fn -> :math.log(0) end
    end
  end

  # ============================================================
  # 24-25. Module attributes, def/defp
  # ============================================================
  describe "sections 24-25: attributes and def/defp" do
    # 5W1H | Who: trainee. What: @stopwords attribute membership plus def-public/defp-private boundary; answers 99-100 shape. When/Where: article sec.24-25. How: asserts incl. UndefinedFunctionError via apply/3. Why: attributes hold config, defp enforces encapsulation.
    # STAR | Situation: stop?/2 checks and N.a/1 delegating to private b/1. Task: prove both. Action: call public, apply private. Result: true/false, 11, UndefinedFunctionError.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "stopwords + private fn" do
      defmodule CProof do
        @stopwords ~w(a the of)
        def stop?(t), do: t in @stopwords
      end

      assert CProof.stop?("the") == true
      assert CProof.stop?("cat") == false

      defmodule NProof do
        def a(x), do: b(x) + 1
        defp b(x), do: x * 2
      end

      assert NProof.a(5) == 11
      assert_raise UndefinedFunctionError, fn -> apply(NProof, :b, [5]) end
    end
  end

  # ============================================================
  # Final mini-challenges D1-D5
  # ============================================================
  describe "final challenges D1-D5" do
    # 5W1H | Who: trainee. What: D1 full tokenize pipeline (trim→downcase→depunctuate→split→reject stopwords). When/Where: final challenge, the real tokenizer. How: pipeline assert. Why: integrates every section.
    # STAR | Situation: noisy "  THE CAT CLIMBED!  ". Task: produce ["cat","climbed"]. Action: run the five-stage pipe. Result: ["cat","climbed"].
    # FLOW | "  THE CAT CLIMBED!  "
    #          │ String.trim()
    #          ▼ "THE CAT CLIMBED!"
    #          │ String.downcase()
    #          ▼ "the cat climbed!"
    #          │ String.replace(~r/[^\p{L}\p{N}\s]/u, " ")
    #          ▼ "the cat climbed "
    #          │ String.split(~r/\s+/, trim: true)
    #          ▼ ["the", "cat", "climbed"]
    #          │ Enum.reject(stopwords)
    #          ▼ ["cat", "climbed"]
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "D1 tokenize pipeline" do
      result =
        "  THE CAT CLIMBED!  "
        |> String.trim()
        |> String.downcase()
        |> String.replace(~r/[^\p{L}\p{N}\s]/u, " ")
        |> String.split(~r/\s+/, trim: true)
        |> Enum.reject(&(&1 in ~w(a the of and to in on at for with by)))

      assert result == ["cat", "climbed"]
    end

    # 5W1H | Who: trainee. What: D2 term frequencies via Map.update counter. When/Where: final challenge, TF building block. How: reduce assert. Why: counting pattern reused in indexing.
    # STAR | Situation: [cat dog cat fish cat]. Task: count each. Action: reduce with Map.update. Result: %{"cat"=>3,"dog"=>1,"fish"=>1}.
    # FLOW | ~w(cat dog cat fish cat)
    #          │ Enum.reduce(%{}, Map.update(acc, w, 1, &(&1 + 1)))
    #          ▼ %{"cat" => 3, "dog" => 1, "fish" => 1}
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "D2 word count" do
      result =
        ~w(cat dog cat fish cat)
        |> Enum.reduce(%{}, fn w, acc -> Map.update(acc, w, 1, &(&1 + 1)) end)

      assert result == %{"cat" => 3, "dog" => 1, "fish" => 1}
    end

    # 5W1H | Who: trainee. What: D3 postings — uniq, group_by word, sort doc ids. When/Where: final challenge, inverted-index core shape. How: chained asserts in one pipeline. Why: exact postings construction.
    # STAR | Situation: [{word,doc}] pairs with a duplicate. Task: build %{word=>[sorted ids]}. Action: uniq→group_by→Map.new+sort. Result: %{"cat"=>[1,2],"fish"=>[3]}.
    # FLOW | [{"cat",1},{"cat",2},{"fish",3},{"cat",1}]
    #          │ Enum.uniq()
    #          ▼ [{"cat",1},{"cat",2},{"fish",3}]
    #          │ Enum.group_by(word) → Map.new(sort ids)
    #          ▼ %{"cat" => [1, 2], "fish" => [3]}
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "D3 group word -> sorted doc_ids" do
      result =
        [{"cat", 1}, {"cat", 2}, {"fish", 3}, {"cat", 1}]
        |> Enum.uniq()
        |> Enum.group_by(fn {w, _} -> w end, fn {_, id} -> id end)
        |> Map.new(fn {w, ids} -> {w, Enum.sort(ids)} end)

      assert result == %{"cat" => [1, 2], "fish" => [3]}
    end

    # 5W1H | Who: prover + future AI reader. What: D4 v1 answer is BROKEN (flat_map returning tuples); Enum.map fix works. When/Where: final challenge D4. How: assert_raise then fixed-pipeline assert. Why: the flat_map-vs-map trap in the wild.
    # STAR | Situation: v1 flat_map+tuple code. Task: prove it raises, prove the fix. Action: run broken (raises), run Enum.map version. Result: Protocol.UndefinedError, then %{1=>1,2=>1}.
    # FLOW | %{1 => "a b c", 2 => "a b"}   (fixed Enum.map version)
    #          │ per doc: String.split → Enum.count(&(&1 == "a"))
    #          ▼ [{1, 1}, {2, 1}]
    #          │ Map.new()
    #          ▼ %{1 => 1, 2 => 1}
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    @tag :documented_error
    test "D4 article version is BROKEN (documents error); fixed version works" do
      # Article code raises because flat_map fun returns a tuple (not enumerable):
      assert_raise Protocol.UndefinedError, fn ->
        %{1 => "a b c", 2 => "a b"}
        |> Enum.flat_map(fn {id, txt} ->
          txt |> String.split() |> Enum.count(&(&1 == "a")) |> then(fn c -> {id, c} end)
        end)
        |> Map.new()
      end

      # Fixed with Enum.map:
      fixed =
        %{1 => "a b c", 2 => "a b"}
        |> Enum.map(fn {id, txt} -> {id, txt |> String.split() |> Enum.count(&(&1 == "a"))} end)
        |> Map.new()

      assert fixed == %{1 => 1, 2 => 1}
    end

    # 5W1H | Who: trainee. What: D5 multi-list intersection via Enum.reduce and --/-- identity. When/Where: final challenge, AND-query semantics. How: asserts incl. empty and single-list edges. Why: reduce-powered set intersection.
    # STAR | Situation: three posting lists. Task: keep commons via reduce. Action: call intersection/1 thrice. Result: [2,3], [], [1,2].
    # FLOW | intersection([[1,2,3],[2,3,4],[2,3,5]]) = Enum.reduce(t, h, &(&2 -- (&2 -- &1)))
    #          │ acc [1,2,3] vs [2,3,4]: [1,2,3] -- ([1,2,3] -- [2,3,4]) = [1,2,3] -- [1]
    #          ▼ [2, 3]
    #          │ acc [2,3] vs [2,3,5]: [2,3] -- ([2,3] -- [2,3,5]) = [2,3] -- []
    #          ▼ [2, 3]
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "D5 intersection via reduce" do
      defmodule InterProof do
        def intersection([]), do: []
        def intersection([h | t]), do: Enum.reduce(t, h, &(&2 -- (&2 -- &1)))
      end

      assert InterProof.intersection([[1, 2, 3], [2, 3, 4], [2, 3, 5]]) == [2, 3]
      assert InterProof.intersection([]) == []
      assert InterProof.intersection([[1, 2]]) == [1, 2]
    end
  end

  # ============================================================
  # Pipe precedence (section 1 misconception — article error)
  # ============================================================
  describe "pipe precedence (article error)" do
    @describetag :documented_error
    # 5W1H | Who: prover + future AI reader. What: v1 precedence myth — AST shows (1+2) is the pipe's left side; runtime prints 3. When/Where: article sec.1 misconception, Elixir 1.20. How: quote-shape match plus captured IO. Why: precedence myths produce phantom ArithmeticErrors.
    # STAR | Situation: v1 claimed 1+(2|>puts) then raise. Task: prove (1+2)|>puts. Action: match AST, capture IO. Result: shape matches, output "3\n", :ok.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    @tag :documented_error
    test "1 + 2 |> IO.puts() is (1+2) |> puts, prints 3, no error" do
      # Article claims it parses as 1 + (2 |> puts) and raises ArithmeticError.
      # AST proof: left side of |> is (1+2):
      assert {:|>, _, [{:+, _, [1, 2]}, _]} = quote(do: 1 + 2 |> IO.puts())

      assert ExUnit.CaptureIO.capture_io(fn -> assert (1 + 2 |> IO.puts()) == :ok end) == "3\n"
    end

    # 5W1H | Who: prover. What: v1 self-contradiction — same replace pipe shown as both error and correct. When/Where: article sec.1 counterexamples. How: direct assert it never raises. Why: contradictory docs teach nothing.
    # STAR | Situation: identical line labeled ❌ and ✅. Task: settle it. Action: run the pipe. Result: "hello elixir", no raise.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    @tag :documented_error
    test "pipe replace counterexample is self-contradictory (article error)" do
      # Article shows the SAME line as both ❌ (ArgumentError) and ✅ (correct).
      # Proof: it never raises:
      assert ("hello world" |> String.replace("world", "elixir")) == "hello elixir"
    end
  end

  # ============================================================
  # Guards / clauses / ExUnit sanity (sections 20,21)
  # ============================================================
  describe "sections 20-21: guards and clauses" do
    # 5W1H | Who: prover. What: non-guard-safe String.length/1 rejected at compile; byte_size guard accepted. When/Where: article sec.20. How: assert_raise CompileError (stderr captured) plus GoodGuard call. Why: guard-safe boundary.
    # STAR | Situation: BadGuard with String.length vs GoodGuard with byte_size. Task: prove compile vs pass. Action: compile bad (raises), call good. Result: CompileError, then "a".
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "guard-safe vs not guard-safe" do
      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        assert_raise CompileError, fn ->
          Code.compile_string("""
          defmodule BadGuard do
            def valid?(x) when String.length(x) > 0, do: x
          end
          """)
        end
      end)

      defmodule GoodGuard do
        def valid?(x) when is_binary(x) and byte_size(x) > 0, do: x
      end

      assert GoodGuard.valid?("a") == "a"
    end

    # 5W1H | Who: trainee. What: multi-clause length counter G.f/1 plus kind/1 guard dispatch; answer 89-90 shape. When/Where: article sec.20-21. How: direct call asserts. Why: clause order and guard dispatch basics.
    # STAR | Situation: recursive G.f and three-clause ExProof.kind. Task: freeze dispatch. Action: call each. Result: 3, :integer, :string, :other.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "multiple clauses order + G.f/1" do
      defmodule GProof do
        def f([]), do: 0
        def f([_ | t]), do: 1 + f(t)
      end

      assert GProof.f([1, 2, 3]) == 3

      defmodule ExProof do
        def kind(x) when is_integer(x), do: :integer
        def kind(x) when is_binary(x), do: :string
        def kind(_), do: :other
      end

      assert ExProof.kind(1) == :integer
      assert ExProof.kind("a") == :string
      assert ExProof.kind(:a) == :other
    end
  end
end
# Article code under proof, inlined here (this repo never uses /lib):
# Tokenizer (article Step 1, verbatim).
defmodule Tokenizer do
  def tokenize(text) do
    # FLOW | "AÇÃO 123!"
    #          │ String.downcase()
    #          ▼ "ação 123!"
    #          │ String.split(~r/[^\p{L}\p{N}]+/u, trim: true)
    #          ▼ ["ação", "123"]
    text
    |> String.downcase()
    |> String.split(~r/[^\p{L}\p{N}]+/u, trim: true)
  end
end

# InvertedIndex (article Steps 2-4).
# NOTE (article gap): the article prints `def search` and `def build_with_tf`
# as bare definitions with no surrounding `defmodule`. They belong here —
# usage calls `InvertedIndex.search/3` and `InvertedIndex.build_with_tf/1`.
defmodule InvertedIndex do
  alias Tokenizer

  def build(documents) do
    # FLOW | %{"doc1" => "cat cat dog"}
    #          │ tokenize → Enum.uniq → Enum.map ({term, doc_id})
    #          ▼ [{"cat", "doc1"}, {"dog", "doc1"}]
    #          │ Enum.group_by (key: term, value: doc_id)
    #          ▼ %{"cat" => ["doc1"], "dog" => ["doc1"]}
    #          │ Map.new + Enum.uniq(docs)
    #          ▼ %{"cat" => ["doc1"], "dog" => ["doc1"]}
    documents
    |> Enum.flat_map(fn {doc_id, text} ->
      text
      |> Tokenizer.tokenize()
      |> Enum.uniq()
      |> Enum.map(fn term -> {term, doc_id} end)
    end)
    |> Enum.group_by(fn {term, _doc} -> term end, fn {_term, doc} -> doc end)
    |> Map.new(fn {term, docs} -> {term, Enum.uniq(docs)} end)
  end

  def build_with_tf(documents) do
    # FLOW | %{"doc1" => "cat cat dog"}
    #          │ tokenize → Enum.frequencies
    #          ▼ %{"cat" => 2, "dog" => 1}
    #          │ Enum.map ({term, {doc_id, count}})
    #          ▼ [{"cat", {"doc1", 2}}, {"dog", {"doc1", 1}}]
    #          │ Enum.group_by (key: term, value: {doc_id, count})
    #          ▼ %{"cat" => [{"doc1", 2}], "dog" => [{"doc1", 1}]}
    documents
    |> Enum.flat_map(fn {doc_id, text} ->
      text
      |> Tokenizer.tokenize()
      |> Enum.frequencies()
      |> Enum.map(fn {term, count} -> {term, {doc_id, count}} end)
    end)
    |> Enum.group_by(fn {term, _} -> term end, fn {_, value} -> value end)
  end

  def search(index, terms, :or) do
    # FLOW | terms ["beam", "functional"] (postings ["doc2"], ["doc1", "doc3"])
    #          │ Enum.flat_map(Map.get(index, term, []))
    #          ▼ ["doc2", "doc1", "doc3"]
    #          │ Enum.uniq()
    #          ▼ ["doc2", "doc1", "doc3"]
    terms
    |> Enum.flat_map(&Map.get(index, &1, []))
    |> Enum.uniq()
  end

  def search(index, terms, :and) do
    # FLOW | terms ["elixir", "functional"] (postings ["doc1","doc2"], ["doc1","doc3"])
    #          │ Enum.map(Map.get) → Enum.map(MapSet.new/1)
    #          ▼ [#MapSet<["doc1", "doc2"]>, #MapSet<["doc1", "doc3"]>]
    #          │ Enum.reduce(MapSet.intersection/2)
    #          ▼ #MapSet<["doc1"]>
    #          │ MapSet.to_list()
    #          ▼ ["doc1"]
    terms
    |> Enum.map(&Map.get(index, &1, []))
    |> Enum.map(&MapSet.new/1)
    |> Enum.reduce(fn set, acc -> MapSet.intersection(acc, set) end)
    |> MapSet.to_list()
  end
end

# TFIDF (article Step 5, verbatim).
defmodule TFIDF do
  def idf(index, total_docs, term) do
    # FLOW | idf(index, 3, "elixir")
    #          │ Map.get(index, "elixir", []) |> length()
    #          ▼ df = 2
    #          │ :math.log(3 / 2)
    #          ▼ 0.4054651081081644
    #
    #        idf(index, 3, "beam") → df = 1 → :math.log(3 / 1) → 1.0986122886681098
    #        idf(index, 3, "zzz")  → df = 0 → 0.0                    ← guard, not log(3/0)
    df = index |> Map.get(term, []) |> length()
    if df == 0, do: 0.0, else: :math.log(total_docs / df)
  end

  def score(index, total_docs, term, doc_id) do
    # FLOW | score(index, 3, "elixir", "doc1")
    #          │ Enum.find([{"doc1",1},{"doc2",1}], id == "doc1")
    #          ▼ {"doc1", 1}
    #          │ tf * idf(index, 3, "elixir")
    #          ▼ 1 * 0.4054651081081644 = 0.4054651081081644
    #
    #        score(index, 3, "elixir", "doc3") → find → nil → 0.0     ← doc lacks the term
    #        score(index, 3, "zzz",    "doc1") → Map.get → [] → nil → 0.0
    case Enum.find(Map.get(index, term, []), fn {id, _} -> id == doc_id end) do
      nil -> 0.0
      {_id, tf} -> tf * idf(index, total_docs, term)
    end
  end

  def rank(index, total_docs, query_terms) do
    # FLOW | index %{"elixir" => [{"doc1",1},{"doc2",1}], "functional" => [{"doc1",1},{"doc3",1}]}, query ["elixir","functional"]
    #          │ Map.keys → flat_map postings → uniq
    #          ▼ ["doc1", "doc2", "doc3"]                        (candidate docs)
    #          │ per doc: Σ score(term, doc)
    #          ▼ [{"doc1", 0.8109}, {"doc2", 0.4055}, {"doc3", 0.4055}]   (doc1 = 2·log(3/2), NOT log(3))
    #          │ Enum.reject(score == 0.0) → Enum.sort_by(-score)
    #          ▼ [{"doc1", 0.8109}, {"doc2", 0.4055}, {"doc3", 0.4055}]
    index
    |> Map.keys()
    |> Enum.flat_map(fn term ->
      index[term] |> Enum.map(fn {doc_id, _} -> doc_id end)
    end)
    |> Enum.uniq()
    |> Enum.map(fn doc_id ->
      score =
        query_terms
        |> Enum.map(&score(index, total_docs, &1, doc_id))
        |> Enum.sum()

      {doc_id, score}
    end)
    |> Enum.reject(fn {_doc, score} -> score == 0.0 end)
    |> Enum.sort_by(fn {_doc, score} -> -score end)
  end
end

defmodule InvertedIndexProofTest do
  # Proof suite for the article "Building an Inverted Index in Elixir:
  # From Scratch to TF-IDF" (Elixir 1.20.1 / OTP 29).
  # Documentation convention (English, natural language):
  # - 5W1H: Who (reader/prover), What (behavior proven), When/Where
  #   (article step), Why (which misconception it kills), How (strategy).
  # - STAR: Situation (article claim), Task (what must be proven),
  #   Action (what the test executes), Result (expected outcome).
  use ExUnit.Case, async: true

  @docs %{
    "doc1" => "Elixir is a functional language",
    "doc2" => "Elixir runs on the BEAM virtual machine",
    "doc3" => "Functional programming is powerful"
  }

  # ============================================================
  # Step 1: Tokenization
  # ============================================================
  describe "Step 1: Tokenizer.tokenize/1" do
    # 5W1H | Who: reader. What: article's exact example plus empty/Unicode edges. When/Where: article Step 1. How: equality asserts. Why: every later step trusts these tokens.
    # STAR | Situation: "Elixir is fun!" claimed ["elixir","is","fun"]. Task: lock it + edges. Action: tokenize example, "", "AÇÃO 123!". Result: all pass.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "article example plus edge cases" do
      assert Tokenizer.tokenize("Elixir is fun!") == ["elixir", "is", "fun"]
      assert Tokenizer.tokenize("") == []
      assert Tokenizer.tokenize("AÇÃO 123!") == ["ação", "123"]
      assert Tokenizer.tokenize("end.start") == ["end", "start"]
    end
  end

  # ============================================================
  # Step 2: Building the inverted index
  # ============================================================
  describe "Step 2: InvertedIndex.build/1" do
    # 5W1H | Who: reader. What: article's three-doc index, term -> doc_ids. When/Where: article Step 2. How: Map.get asserts on postings. Why: the core data structure.
    # STAR | Situation: docs from the article. Task: prove postings. Action: build, assert elixir/functional/beam/language. Result: ["doc1","doc2"], ["doc1","doc3"], ["doc2"], ["doc1"].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "article example index" do
      index = InvertedIndex.build(@docs)

      assert Map.get(index, "elixir") == ["doc1", "doc2"]
      assert Map.get(index, "functional") == ["doc1", "doc3"]
      assert Map.get(index, "beam") == ["doc2"]
      assert Map.get(index, "language") == ["doc1"]
      assert Map.get(index, "missing") == nil
    end

    # 5W1H | Who: prover. What: repeated terms in one doc yield ONE posting (Enum.uniq per doc). When/Where: article Step 2 pipeline detail. How: single-doc assert. Why: proves dedup, not just the happy path.
    # STAR | Situation: "cat cat cat" in doc1. Task: prove single posting. Action: build one-doc index. Result: %{"cat" => ["doc1"]}.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "repeated term in one doc posts once" do
      assert InvertedIndex.build(%{"doc1" => "cat cat cat"}) == %{"cat" => ["doc1"]}
    end
  end

  # ============================================================
  # Step 3: Boolean search (AND / OR)
  # ============================================================
  describe "Step 3: boolean search" do
    # 5W1H | Who: reader. What: article's AND/OR examples incl. exact OR order. When/Where: article Step 3. How: equality asserts on built index. Why: set-operation semantics.
    # STAR | Situation: AND ["elixir","functional"] -> ["doc1"]; OR ["beam","functional"] -> ["doc2","doc1","doc3"]. Task: lock both. Action: search each. Result: exact lists pass.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "article AND/OR examples" do
      index = InvertedIndex.build(@docs)

      assert InvertedIndex.search(index, ["elixir", "functional"], :and) == ["doc1"]
      assert InvertedIndex.search(index, ["beam", "functional"], :or) == ["doc2", "doc1", "doc3"]
    end

    # 5W1H | Who: prover. What: unknown terms degrade gracefully (OR ignores, AND empties). When/Where: article Step 3 defaults (Map.get ... []). How: asserts. Why: miss-handling is the lookup contract.
    # STAR | Situation: term "zzz" in no doc. Task: prove no crash. Action: OR [zzz, elixir], AND [elixir, zzz], OR [zzz]. Result: ["doc1","doc2"], [], [].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "missing terms degrade gracefully" do
      index = InvertedIndex.build(@docs)

      assert InvertedIndex.search(index, ["zzz", "elixir"], :or) == ["doc1", "doc2"]
      assert InvertedIndex.search(index, ["elixir", "zzz"], :and) == []
      assert InvertedIndex.search(index, ["zzz"], :or) == []
    end

    # 5W1H | Who: prover + future AI reader. What: ARTICLE GAP — empty AND query crashes (reduce/2 on []). When/Where: article Step 3 never covers []. How: assert_raise. Why: reduce/2 needs ≥1 element; OR [] is fine.
    # STAR | Situation: search(index, [], :and). Task: prove the crash. Action: run inside assert_raise; contrast OR []. Result: Enum.EmptyError; OR gives [].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    @tag :documented_gap
    test "empty AND terms raise Enum.EmptyError (article gap documented)" do
      index = InvertedIndex.build(@docs)

      assert_raise Enum.EmptyError, fn ->
        InvertedIndex.search(index, [], :and)
      end

      assert InvertedIndex.search(index, [], :or) == []
    end

    # 5W1H | Who: prover. What: ARTICLE GAP — bare `def search` blocks belong to InvertedIndex. When/Where: article Step 3 prints defs with no defmodule. How: function_exported? asserts. Why: as printed, the code does not compile standalone.
    # STAR | Situation: usage calls InvertedIndex.search/3. Task: pin the home module. Action: assert exports. Result: search/3, build/1, build_with_tf/1 all exported.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    @tag :documented_gap
    test "search lives in InvertedIndex (article gap documented)" do
      assert function_exported?(InvertedIndex, :search, 3)
      assert function_exported?(InvertedIndex, :build, 1)
      assert function_exported?(InvertedIndex, :build_with_tf, 1)
    end
  end

  # ============================================================
  # Step 4: Term Frequency (TF)
  # ============================================================
  describe "Step 4: InvertedIndex.build_with_tf/1" do
    # 5W1H | Who: reader. What: article's {doc_id, tf} postings shape. When/Where: article Step 4. How: equality asserts. Why: postings-with-counts power ranking.
    # STAR | Situation: same three docs. Task: prove posting tuples. Action: build_with_tf, assert elixir/functional. Result: [{"doc1",1},{"doc2",1}], [{"doc1",1},{"doc3",1}].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "article TF postings shape" do
      index = InvertedIndex.build_with_tf(@docs)

      assert Map.get(index, "elixir") == [{"doc1", 1}, {"doc2", 1}]
      assert Map.get(index, "functional") == [{"doc1", 1}, {"doc3", 1}]
    end

    # 5W1H | Who: prover. What: frequencies count repeats (tf=3), unlike boolean build. When/Where: article Step 4 Enum.frequencies detail. How: single-doc assert. Why: proves TF actually counts.
    # STAR | Situation: "elixir elixir elixir" in doc9. Task: prove tf 3. Action: build_with_tf. Result: %{"elixir" => [{"doc9", 3}]}.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "repeated term counts tf" do
      assert InvertedIndex.build_with_tf(%{"doc9" => "elixir elixir elixir"}) == %{
               "elixir" => [{"doc9", 3}]
             }
    end
  end

  # ============================================================
  # Step 5: TF-IDF ranking
  # ============================================================
  describe "Step 5: TFIDF" do
    # 5W1H | Who: reader. What: IDF rewards rarity: log(3/2) for shared terms, log(3/1) for unique, 0.0 for missing. When/Where: article Step 5 formula IDF=log(N/df). How: float asserts. Why: IDF is the ranking math.
    # STAR | Situation: 3 docs; elixir in 2, beam in 1, zzz in 0. Task: prove formula values. Action: idf each. Result: 0.405..., 1.098..., 0.0.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "idf rewards rarity" do
      index = InvertedIndex.build_with_tf(@docs)

      assert TFIDF.idf(index, 3, "elixir") == :math.log(3 / 2)
      assert TFIDF.idf(index, 3, "beam") == :math.log(3 / 1)
      assert TFIDF.idf(index, 3, "zzz") == 0.0
    end

    # 5W1H | Who: reader. What: score = tf*idf, 0.0 on miss. When/Where: article Step 5 scoring. How: float asserts. Why: per-term doc scoring.
    # STAR | Situation: doc1 has elixir tf=1; doc3 lacks elixir. Task: prove scores. Action: score both + missing term. Result: 0.405..., 0.0, 0.0.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "score is tf*idf, zero on miss" do
      index = InvertedIndex.build_with_tf(@docs)

      assert TFIDF.score(index, 3, "elixir", "doc1") == :math.log(3 / 2)
      assert TFIDF.score(index, 3, "elixir", "doc3") == 0.0
      assert TFIDF.score(index, 3, "zzz", "doc1") == 0.0
    end

    # 5W1H | Who: prover + future AI reader. What: ARTICLE ERROR — doc1 scores 2*log(3/2)=0.8109, NOT log(3)=1.0986; order [doc1,doc2,doc3] is right. When/Where: article Step 5 final ranking. How: exact-list assert. Why: the article's headline number is wrong.
    # STAR | Situation: article claims [{"doc1",1.098...},...]. Task: prove actual. Action: rank ["elixir","functional"]. Result: [{"doc1",0.8109...},{"doc2",0.405...},{"doc3",0.405...}].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    @tag :documented_error
    test "rank numbers (article doc1 value corrected)" do
      index = InvertedIndex.build_with_tf(@docs)

      assert TFIDF.rank(index, 3, ["elixir", "functional"]) == [
               {"doc1", 2 * :math.log(3 / 2)},
               {"doc2", :math.log(3 / 2)},
               {"doc3", :math.log(3 / 2)}
             ]
    end

    # 5W1H | Who: prover. What: empty query ranks nothing (all scores 0.0 rejected). When/Where: article Step 5 reject-zero step. How: assert []. Why: edge behavior of the pipeline.
    # STAR | Situation: rank with []. Task: prove []. Action: rank empty query. Result: [].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "empty query ranks nothing" do
      index = InvertedIndex.build_with_tf(@docs)

      assert TFIDF.rank(index, 3, []) == []
    end
  end
end

# Two Sum article code, inlined here (this repo never uses /lib).
# NOTE: the article names every version `Solution` in separate blocks;
# they are renamed here so all four can coexist in one file.
defmodule TwoSumBrute do
  @spec two_sum(nums :: [integer], target :: integer) :: [integer]
  def two_sum(nums, target) do
    Enum.find_value(0..(length(nums) - 2), fn i ->
      Enum.find_value((i + 1)..(length(nums) - 1), fn j ->
        if Enum.at(nums, i) + Enum.at(nums, j) == target, do: [i, j]
      end)
    end)
  end
end

defmodule TwoSumRec do
  @spec two_sum(nums :: [integer], target :: integer) :: [integer]
  def two_sum(nums, target) do
    find(nums, target, %{}, 0)
  end

  defp find([num | rest], target, map, i) do
    val = target - num

    case Map.fetch(map, val) do
      {:ok, index} -> [index, i]
      :error -> find(rest, target, Map.put(map, num, i), i + 1)
    end
  end

  defp find([], _target, _map, _i), do: []
end

defmodule TwoSumReduceWhile do
  @spec two_sum(nums :: [integer], target :: integer) :: [integer]
  def two_sum(nums, target) do
    nums
    |> Enum.with_index()
    |> Enum.reduce_while(%{}, fn {num, index}, map ->
      case map[target - num] do
        nil -> {:cont, Map.put(map, num, index)}
        found -> {:halt, [index, found]}
      end
    end)
  end
end

defmodule TwoSumPattern do
  @spec two_sum(nums :: [integer], target :: integer) :: [integer]
  def two_sum(nums, target) do
    helper(Enum.with_index(nums), %{}, target)
  end

  defp helper([{value, index} | _t], map, _target) when is_map_key(map, value) do
    [map[value], index]
  end

  defp helper([{value, index} | t], map, target) do
    helper(t, Map.put(map, target - value, index), target)
  end
end

defmodule TwoSumProofTest do
  # Proof suite for the article "Solving LeetCode's Two Sum Problem in Elixir"
  # (Elixir 1.20.1 / OTP 29). Same 5W1H/STAR convention as above.
  use ExUnit.Case, async: true

  describe "Two Sum: LeetCode examples" do
    # 5W1H | Who: reader. What: brute force passes all three LeetCode examples in [earlier, later] order. When/Where: article Solution 1. How: equality asserts. Why: baseline correctness.
    # STAR | Situation: [2,7,11,15]/9, [3,2,4]/6, [3,3]/6. Task: lock outputs. Action: two_sum each. Result: [0,1], [1,2], [0,1].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | two_sum([2,7,11,15], 9)   (TwoSumBrute)
    #        i=0: j=1 → 2+7=9  ✓
    #        ▼ [0,1]  ← outer Enum.find_value returns the first non-nil
    #
    # FLOW | two_sum([3,2,4], 6)   (TwoSumBrute)
    #        i=0: j=1 → 5 ✗ ; j=2 → 7 ✗ → nil
    #        i=1: j=2 → 6 ✓
    #        ▼ [1,2]
    test "brute force passes the three examples" do
      assert TwoSumBrute.two_sum([2, 7, 11, 15], 9) == [0, 1]
      assert TwoSumBrute.two_sum([3, 2, 4], 6) == [1, 2]
      assert TwoSumBrute.two_sum([3, 3], 6) == [0, 1]
    end

    # 5W1H | Who: reader. What: recursive hash map passes all three examples, same order as brute force. When/Where: article Solution 2 (recursion). How: equality asserts. Why: optimal O(n) correctness.
    # STAR | Situation: same three examples. Task: lock outputs. Action: two_sum each. Result: [0,1], [1,2], [0,1].
    # FLOW (two_sum([2,7,11,15], 9))
    # find([2,7,11,15], 9, %{}, 0)
    #   need 7, miss → find([7,11,15], 9, %{2 => 0}, 1)
    #     need 2, hit 0 → [0, 1]
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "recursive hash map passes the three examples" do
      assert TwoSumRec.two_sum([2, 7, 11, 15], 9) == [0, 1]
      assert TwoSumRec.two_sum([3, 2, 4], 6) == [1, 2]
      assert TwoSumRec.two_sum([3, 3], 6) == [0, 1]
    end

    # 5W1H | Who: prover + future AI reader. What: reduce_while finds the SAME pair but REVERSED ([later, earlier]) — article shows no outputs, hiding this. When/Where: article Solution 2 (reduce_while). How: equality asserts on reversed lists. Why: order differs across "equivalent" solutions.
    # STAR | Situation: same three examples. Task: prove reversed order. Action: two_sum each. Result: [1,0], [2,1], [1,0] (LeetCode accepts either order).
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "reduce_while passes examples reversed (behavioral difference documented)" do
      assert TwoSumReduceWhile.two_sum([2, 7, 11, 15], 9) == [1, 0]
      assert TwoSumReduceWhile.two_sum([3, 2, 4], 6) == [2, 1]
      assert TwoSumReduceWhile.two_sum([3, 3], 6) == [1, 0]
    end

    # 5W1H | Who: reader. What: guard-clause pattern version passes all three examples via complement-keys. When/Where: article alternative recursion. How: equality asserts. Why: guard + complement-key style correctness.
    # STAR | Situation: same three examples. Task: lock outputs. Action: two_sum each. Result: [0,1], [1,2], [0,1].
    # FLOW | two_sum([3,2,4], 6)   (TwoSumPattern — map holds COMPLEMENTS)
    #        {3,0}: is_map_key(%{}, 3)?            no  → put 6-3=3 → %{3=>0}
    #        {2,1}: is_map_key(%{3=>0}, 2)?        no  → put 6-2=4 → %{3=>0,4=>1}
    #        {4,2}: is_map_key(%{3=>0,4=>1}, 4)?   yes → [map[4], 2]
    #        ▼ [1,2]
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "pattern-matching version passes the three examples" do
      assert TwoSumPattern.two_sum([2, 7, 11, 15], 9) == [0, 1]
      assert TwoSumPattern.two_sum([3, 2, 4], 6) == [1, 2]
      assert TwoSumPattern.two_sum([3, 3], 6) == [0, 1]
    end

    # 5W1H | Who: prover. What: all versions agree (as sets) on negatives and duplicates. When/Where: beyond-article robustness. How: MapSet equality asserts. Why: proves same solution, not just same examples.
    # STAR | Situation: [-3,4,3,90]/0 and [3,3]/6. Task: prove agreement. Action: compare MapSets. Result: equal.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "all versions agree on negatives and duplicates" do
      assert TwoSumBrute.two_sum([-3, 4, 3, 90], 0) |> MapSet.new() ==
               TwoSumRec.two_sum([-3, 4, 3, 90], 0) |> MapSet.new()

      assert TwoSumRec.two_sum([-3, 4, 3, 90], 0) |> MapSet.new() ==
               TwoSumPattern.two_sum([-3, 4, 3, 90], 0) |> MapSet.new()

      assert TwoSumReduceWhile.two_sum([-3, 4, 3, 90], 0) |> MapSet.new() ==
               TwoSumBrute.two_sum([-3, 4, 3, 90], 0) |> MapSet.new()
    end
  end

  describe "Two Sum: no-solution contracts (article gaps documented)" do
    @describetag :documented_gap
    # 5W1H | Who: prover + future AI reader. What: the three "equivalent" solutions DISAGREE with no solution — brute nil, rec [], reduce_while leaks the map, pattern crashes (missing [] clause). When/Where: article assumes exactly one solution, never covers miss. How: asserts + assert_raise. Why: hidden contract divergence.
    # STAR | Situation: [1,2,3]/100 has no pair. Task: prove each behavior. Action: call all four. Result: nil, [], %{1=>0,2=>1,3=>2}, FunctionClauseError.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | two_sum([1,2,3], 100)   (no solution — the four diverge)
    #        Brute        → [i,j] never matches → Enum.find_value returns nil → nil
    #        Rec          → find([], …, map, 3) hits find([], …) → []
    #        ReduceWhile  → never halts → the MAP leaks: %{1=>0, 2=>1, 3=>2}
    #        Pattern      → helper([], …) has NO clause → FunctionClauseError
    @tag :documented_gap
    test "no-solution inputs diverge per implementation" do
      assert TwoSumBrute.two_sum([1, 2, 3], 100) == nil
      assert TwoSumRec.two_sum([1, 2, 3], 100) == []
      assert TwoSumReduceWhile.two_sum([1, 2, 3], 100) == %{1 => 0, 2 => 1, 3 => 2}

      assert_raise FunctionClauseError, fn ->
        TwoSumPattern.two_sum([1, 2, 3], 100)
      end
    end

    # 5W1H | Who: prover. What: brute force on []/single-elem crashes with ArithmeticError (nil + nil) plus a decreasing-Range warning. When/Where: article never covers short inputs. How: assert_raise with stderr captured. Why: Enum.at on missing index returns nil, + explodes.
    # STAR | Situation: two_sum([], 0) and two_sum([5], 5). Task: prove the crash. Action: run inside assert_raise, stderr captured. Result: ArithmeticError twice.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "brute force on empty/singleton raises ArithmeticError" do
      for args <- [[[], 0], [[5], 5]] do
        err =
          ExUnit.CaptureIO.capture_io(:stderr, fn ->
            send(self(), {:err, try do
              apply(TwoSumBrute, :two_sum, args)
            rescue
              e -> e
            end})
          end)
          |> then(fn _ ->
            receive do
              {:err, e} -> e
            end
          end)

        assert %ArithmeticError{} = err
      end
    end
  end
end

# Median article code, inlined here (this repo never uses /lib).
# NOTE: the article names every version `Solution` in separate blocks;
# they are renamed here so all three can coexist in one file.
defmodule MedianBrute do
  @spec find_median_sorted_arrays(nums1 :: [integer], nums2 :: [integer]) :: float
  def find_median_sorted_arrays(nums1, nums2) do
    merged = Enum.sort(nums1 ++ nums2)
    len = length(merged)

    if rem(len, 2) == 1 do
      Enum.at(merged, div(len, 2)) * 1.0
    else
      mid1 = Enum.at(merged, div(len, 2) - 1)
      mid2 = Enum.at(merged, div(len, 2))
      (mid1 + mid2) / 2
    end
  end
end

defmodule MedianAtomBS do
  @spec find_median_sorted_arrays(nums1 :: [integer], nums2 :: [integer]) :: float
  def find_median_sorted_arrays(nums1, nums2) do
    {a, b} = if length(nums1) <= length(nums2), do: {nums1, nums2}, else: {nums2, nums1}
    m = length(a)
    n = length(b)
    binary_search(a, b, 0, m, div(m + n + 1, 2), m + n)
  end

  defp binary_search(a, b, low, high, half, total) when low <= high do
    partition1 = div(low + high, 2)
    partition2 = half - partition1

    left1 = if partition1 > 0, do: Enum.at(a, partition1 - 1), else: :neg_infinity
    right1 = if partition1 < length(a), do: Enum.at(a, partition1), else: :infinity
    left2 = if partition2 > 0, do: Enum.at(b, partition2 - 1), else: :neg_infinity
    right2 = if partition2 < length(b), do: Enum.at(b, partition2), else: :infinity

    cond do
      left1 != :neg_infinity and right2 != :infinity and left1 > right2 ->
        binary_search(a, b, low, partition1 - 1, half, total)

      left2 != :neg_infinity and right1 != :infinity and left2 > right1 ->
        binary_search(a, b, partition1 + 1, high, half, total)

      true ->
        max_left = max_value(left1, left2)
        min_right = min_value(right1, right2)

        if rem(total, 2) == 1 do
          max_left * 1.0
        else
          (max_left + min_right) / 2
        end
    end
  end

  defp binary_search(_a, _b, _low, _high, _half, _total) do
    raise "No valid partition found"
  end

  defp max_value(:neg_infinity, other), do: other
  defp max_value(other, :neg_infinity), do: other
  defp max_value(a, b), do: max(a, b)

  defp min_value(:infinity, other), do: other
  defp min_value(other, :infinity), do: other
  defp min_value(a, b), do: min(a, b)
end

defmodule MedianFloatBS do
  @spec find_median_sorted_arrays(nums1 :: [integer], nums2 :: [integer]) :: float
  def find_median_sorted_arrays(nums1, nums2) do
    {a, b} = if length(nums1) <= length(nums2), do: {nums1, nums2}, else: {nums2, nums1}
    m = length(a)
    n = length(b)
    total = m + n
    half = div(total + 1, 2)

    result =
      Enum.reduce_while(0..m, {0, m}, fn _, {low, high} ->
        partition1 = div(low + high, 2)
        partition2 = half - partition1

        left1 = if partition1 > 0, do: Enum.at(a, partition1 - 1), else: -1.0e308
        right1 = if partition1 < m, do: Enum.at(a, partition1), else: 1.0e308
        left2 = if partition2 > 0, do: Enum.at(b, partition2 - 1), else: -1.0e308
        right2 = if partition2 < n, do: Enum.at(b, partition2), else: 1.0e308

        cond do
          left1 > right2 -> {:cont, {low, partition1 - 1}}
          left2 > right1 -> {:cont, {partition1 + 1, high}}
          true -> {:halt, {left1, right1, left2, right2, total}}
        end
      end)

    case result do
      {left1, right1, left2, right2, total} ->
        max_left = max(left1, left2)
        min_right = min(right1, right2)
        if rem(total, 2) == 1, do: max_left * 1.0, else: (max_left + min_right) / 2

      _ ->
        raise "No valid partition found"
    end
  end
end

defmodule MedianProofTest do
  # Proof suite for the article "Solving LeetCode's Median of Two Sorted
  # Arrays in Elixir" (Elixir 1.20.1 / OTP 29). Same 5W1H/STAR convention.
  use ExUnit.Case, async: true

  describe "Median: LeetCode examples and shape" do
    # FLOW | find_median_sorted_arrays([1,3], [2])   (MedianBrute)
    #        [1,3] ++ [2] → sort → [1,2,3] → len 3 (odd) → Enum.at(1) * 1.0
    #        ▼ 2.0
    #
    # FLOW | find_median_sorted_arrays([], [])   (MedianBrute)
    #        merged [] → len 0 (even) → Enum.at(-1) = nil, Enum.at(0) = nil
    #        ✗ ArithmeticError (nil + nil)
    # 5W1H | Who: reader. What: brute force passes both LeetCode examples plus one-empty, swapped, negative/zero inputs — always float. When/Where: article Solution 1. How: equality + is_float asserts. Why: baseline correctness.
    # STAR | Situation: [1,3]/[2], [1,2]/[3,4], [1,2,3]/[], [2]/[1,3], negatives. Task: lock outputs. Action: find_median each. Result: 2.0, 2.5, 2.0, 2.0, -0.5, all floats.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "brute force passes examples and edges" do
      assert MedianBrute.find_median_sorted_arrays([1, 3], [2]) == 2.0
      assert MedianBrute.find_median_sorted_arrays([1, 2], [3, 4]) == 2.5
      assert MedianBrute.find_median_sorted_arrays([1, 2, 3], []) == 2.0
      assert MedianBrute.find_median_sorted_arrays([2], [1, 3]) == 2.0
      assert MedianBrute.find_median_sorted_arrays([-5, -3, -1], [0, 2, 4]) == -0.5
      assert MedianBrute.find_median_sorted_arrays([0, 0], [0, 0]) == 0.0

      assert is_float(MedianBrute.find_median_sorted_arrays([1, 3], [2]))
      assert is_float(MedianBrute.find_median_sorted_arrays([1, 2], [3, 4]))
    end

    # 5W1H | Who: reader. What: atom-sentinel binary search matches brute force on every case incl. swapped inputs. When/Where: article Solution 2 (recursion). How: equality asserts incl. is_float. Why: optimal O(log) correctness.
    # STAR | Situation: same six inputs. Task: lock outputs. Action: find_median each. Result: 2.0, 2.5, 2.0, 2.0, -0.5, 0.0, all floats.
    # FLOW ([1,2],[3,4]: a=[1,2], total=4, half=2)
    # p1=1, p2=1: left1=1, right1=2, left2=3, right2=4 → left2 > right1 → low=2
    # p1=2, p2=0: left1=2, right1=inf, left2=-inf, right2=3 → max=2, min=3
    #          ▼ (2 + 3) / 2 = 2.5
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "atom binary search matches brute force" do
      assert MedianAtomBS.find_median_sorted_arrays([1, 3], [2]) == 2.0
      assert MedianAtomBS.find_median_sorted_arrays([1, 2], [3, 4]) == 2.5
      assert MedianAtomBS.find_median_sorted_arrays([1, 2, 3], []) == 2.0
      assert MedianAtomBS.find_median_sorted_arrays([], [1]) == 1.0
      assert MedianAtomBS.find_median_sorted_arrays([2], [1, 3]) == 2.0
      assert MedianAtomBS.find_median_sorted_arrays([-5, -3, -1], [0, 2, 4]) == -0.5
      assert MedianAtomBS.find_median_sorted_arrays([0, 0], [0, 0]) == 0.0

      assert is_float(MedianAtomBS.find_median_sorted_arrays([1, 3], [2]))
    end

    # 5W1H | Who: reader. What: float-sentinel reduce_while agrees with atom version on all standard inputs (LeetCode range). When/Where: article reduce_while alternative. How: equality asserts. Why: proves equivalence inside constraints.
    # STAR | Situation: six standard inputs incl. swapped. Task: lock agreement. Action: find_median each. Result: 2.0, 2.5, 2.0, 1.0, 2.0, -0.5.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "float version agrees on standard inputs" do
      for {n1, n2} <- [
            {[1, 3], [2]},
            {[1, 2], [3, 4]},
            {[1, 2, 3], []},
            {[], [1]},
            {[2], [1, 3]},
            {[-5, -3, -1], [0, 2, 4]}
          ] do
        assert MedianFloatBS.find_median_sorted_arrays(n1, n2) ==
                 MedianAtomBS.find_median_sorted_arrays(n1, n2)
      end

      assert MedianFloatBS.find_median_sorted_arrays([1, 3], [2]) == 2.0
      assert MedianFloatBS.find_median_sorted_arrays([1, 2], [3, 4]) == 2.5
    end
  end

  describe "Median: sentinel limits and empty inputs (gaps documented)" do
    @describetag :documented_gap
    # 5W1H | Who: prover + future AI reader. What: BEHAVIORAL DIFFERENCE — float sentinels assume inputs within ±1e308; beyond that the partition logic corrupts and raises RuntimeError, while atom sentinels stay exact (only float conversion can overflow). When/Where: article never bounds its inputs. How: assert_raise on 10^400. Why: sentinel choice is a hidden precondition.
    # STAR | Situation: [10^400]/[]. Task: prove divergence. Action: run both versions. Result: float raises RuntimeError("No valid partition found"); atom raises ArithmeticError (honest 1.0e400 overflow).
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | find_median_sorted_arrays([10^400], [])   (sentinels diverge)
    #        MedianAtomBS :  left/right stay :neg_infinity/:infinity — no comparison against them
    #                        → odd branch → max_left * 1.0 → big * 1.0 overflows
    #                        ✗ ArithmeticError
    #        MedianFloatBS:  left1 = -1.0e308, right1 = 1.0e308, left2 = 10^400
    #                        cond: left2 (10^400) > right1 (1.0e308) → {:cont, {1, 0}}
    #                        range 0..0 exhausted → result is a 2-tuple
    #                        case {left1,right1,left2,right2,total} does not match → fallback
    #                        ✗ RuntimeError "No valid partition found"
    @tag :documented_error
    test "sentinels diverge beyond float range" do
      big = 10 ** 400

      assert_raise RuntimeError, "No valid partition found", fn ->
        MedianFloatBS.find_median_sorted_arrays([big], [])
      end

      assert_raise ArithmeticError, fn ->
        MedianAtomBS.find_median_sorted_arrays([big], [])
      end
    end

    # 5W1H | Who: prover. What: both-empty inputs diverge — brute/atom raise ArithmeticError (nil+nil, :neg_infinity+:infinity), float version silently returns 0.0. When/Where: article never covers degenerate input. How: asserts + assert_raise. Why: undefined-median handling differs.
    # STAR | Situation: ([], []). Task: prove each behavior. Action: run all three. Result: ArithmeticError, ArithmeticError, 0.0.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    @tag :documented_error
    test "both-empty inputs diverge per implementation" do
      assert_raise ArithmeticError, fn ->
        MedianBrute.find_median_sorted_arrays([], [])
      end

      assert_raise ArithmeticError, fn ->
        MedianAtomBS.find_median_sorted_arrays([], [])
      end

      assert MedianFloatBS.find_median_sorted_arrays([], []) == 0.0
    end
  end
end

# Add Two Numbers article code, inlined here (this repo never uses /lib).
# NOTE: the article names every version `Solution` in separate blocks;
# they are renamed here so all four can coexist in one file.
defmodule ListNode do
  @type t :: %__MODULE__{val: integer, next: ListNode.t() | nil}
  defstruct val: 0, next: nil
end

defmodule AddTwoNumbersConvert do
  def add_two_numbers(l1, l2) do
    num1 = list_to_integer(l1, 0, 1)
    num2 = list_to_integer(l2, 0, 1)
    integer_to_list(num1 + num2)
  end

  defp list_to_integer(nil, acc, _multiplier), do: acc

  defp list_to_integer(%ListNode{val: val, next: next}, acc, multiplier) do
    list_to_integer(next, acc + val * multiplier, multiplier * 10)
  end

  defp integer_to_list(0), do: %ListNode{val: 0}

  defp integer_to_list(num) do
    build_list(num, nil)
  end

  defp build_list(0, acc), do: acc

  defp build_list(num, acc) do
    digit = rem(num, 10)
    build_list(div(num, 10), %ListNode{val: digit, next: acc})
  end
end

defmodule AddTwoNumbersRecursive do
  @spec add_two_numbers(l1 :: ListNode.t() | nil, l2 :: ListNode.t() | nil) :: ListNode.t() | nil
  def add_two_numbers(l1, l2) do
    add_lists(l1, l2, 0)
  end

  defp add_lists(nil, nil, 0), do: nil
  defp add_lists(nil, nil, carry) when carry > 0, do: %ListNode{val: carry}

  defp add_lists(nil, %ListNode{val: val, next: next}, carry) do
    sum = val + carry
    %ListNode{val: rem(sum, 10), next: add_lists(nil, next, div(sum, 10))}
  end

  defp add_lists(%ListNode{val: val, next: next}, nil, carry) do
    sum = val + carry
    %ListNode{val: rem(sum, 10), next: add_lists(next, nil, div(sum, 10))}
  end

  defp add_lists(%ListNode{val: v1, next: n1}, %ListNode{val: v2, next: n2}, carry) do
    sum = v1 + v2 + carry
    %ListNode{val: rem(sum, 10), next: add_lists(n1, n2, div(sum, 10))}
  end
end

defmodule AddTwoNumbersAcc do
  def add_two_numbers(l1, l2) do
    add_lists(l1, l2, 0, nil)
  end

  defp add_lists(nil, nil, 0, acc), do: acc
  defp add_lists(nil, nil, carry, acc), do: %ListNode{val: carry, next: acc}

  defp add_lists(nil, %ListNode{val: val, next: next}, carry, acc) do
    sum = val + carry
    add_lists(nil, next, div(sum, 10), %ListNode{val: rem(sum, 10), next: acc})
  end

  defp add_lists(%ListNode{val: val, next: next}, nil, carry, acc) do
    sum = val + carry
    add_lists(next, nil, div(sum, 10), %ListNode{val: rem(sum, 10), next: acc})
  end

  defp add_lists(%ListNode{val: v1, next: n1}, %ListNode{val: v2, next: n2}, carry, acc) do
    sum = v1 + v2 + carry
    add_lists(n1, n2, div(sum, 10), %ListNode{val: rem(sum, 10), next: acc})
  end
end

defmodule AddTwoNumbersLists do
  def add_two_numbers(l1, l2) do
    do_add(Enum.reverse(l1), Enum.reverse(l2), 0, [])
  end

  defp do_add([], [], 0, acc), do: Enum.reverse(acc)
  defp do_add([], [], carry, acc), do: Enum.reverse([carry | acc])

  defp do_add([], [h | t], carry, acc) do
    sum = h + carry
    do_add([], t, div(sum, 10), [rem(sum, 10) | acc])
  end

  defp do_add([h | t], [], carry, acc) do
    sum = h + carry
    do_add(t, [], div(sum, 10), [rem(sum, 10) | acc])
  end

  defp do_add([h1 | t1], [h2 | t2], carry, acc) do
    sum = h1 + h2 + carry
    do_add(t1, t2, div(sum, 10), [rem(sum, 10) | acc])
  end
end

defmodule AddTwoNumbersProofTest do
  # Proof suite for the article "Solving LeetCode's Add Two Numbers in Elixir"
  # (Elixir 1.20.1 / OTP 29). Same 5W1H/STAR convention.
  use ExUnit.Case, async: true

  defp from_list([]), do: nil
  defp from_list([h | t]), do: %ListNode{val: h, next: from_list(t)}

  defp to_list(nil), do: []
  defp to_list(%ListNode{val: v, next: n}), do: [v | to_list(n)]

  describe "Add Two Numbers: correct versions" do
    # 5W1H | Who: reader. What: recursive pattern-matching version passes all three LeetCode examples plus final-carry and uneven lengths. When/Where: article Solution 2. How: struct→list asserts. Why: the recommended optimal approach.
    # STAR | Situation: [2,4,3]+[5,6,4], [0]+[0], 7×9+4×9, [9]+[1], [1,8]+[0]. Task: lock outputs. Action: add_two_numbers each. Result: [7,0,8], [0], [8,9,9,9,0,0,0,1], [0,1], [1,8].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | add_two_numbers([2,4,3], [5,6,4])   (AddTwoNumbersRecursive)
    #        carry 0: 2+5=7 → {7, 0} → recurse([4,3],[6,4],0)
    #        carry 0: 4+6=10 → {0, 1} → recurse([3],[4],1)
    #        carry 1: 3+4+1=8 → {8, 0} → recurse(nil,nil,0) → nil
    #        ▼ 7 → 0 → 8 → nil  =  [7,0,8]
    #
    # FLOW | add_two_numbers([9,9,9,9,9,9,9], [9,9,9,9])   (uneven + final carry)
    #        9+9  =18 → 8, c=1 | 9+9+1=19 → 9, c=1 | 9+9+1=19 → 9, c=1 | 9+9+1=19 → 9, c=1
    #        9+nil+1=10 → 0, c=1 | 9+nil+1=10 → 0, c=1 | 9+nil+1=10 → 0, c=1
    #        nil+nil+1 → carry>0 clause → {val: 1}
    #        ▼ [8,9,9,9,0,0,0,1]
    test "recursive version passes all examples and edges" do
      assert AddTwoNumbersRecursive.add_two_numbers(from_list([2, 4, 3]), from_list([5, 6, 4])) |> to_list() == [7, 0, 8]
      assert AddTwoNumbersRecursive.add_two_numbers(from_list([0]), from_list([0])) |> to_list() == [0]

      assert AddTwoNumbersRecursive.add_two_numbers(
               from_list([9, 9, 9, 9, 9, 9, 9]),
               from_list([9, 9, 9, 9])
             )
             |> to_list() == [8, 9, 9, 9, 0, 0, 0, 1]

      assert AddTwoNumbersRecursive.add_two_numbers(from_list([9]), from_list([1])) |> to_list() == [0, 1]
      assert AddTwoNumbersRecursive.add_two_numbers(from_list([1, 8]), from_list([0])) |> to_list() == [1, 8]
    end

    # 5W1H | Who: reader. What: plain-list Solution 4 passes the equal-length example and final carry. When/Where: article Solution 4 (plain lists, not structs). How: equality asserts. Why: proves the double-reverse accumulator logic — for equal lengths.
    # STAR | Situation: [2,4,3]+[5,6,4], [9]+[1]. Task: lock outputs. Action: add_two_numbers each. Result: [7,0,8], [0,1].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "plain-list version passes equal-length cases" do
      assert AddTwoNumbersLists.add_two_numbers([2, 4, 3], [5, 6, 4]) == [7, 0, 8]
      assert AddTwoNumbersLists.add_two_numbers([9], [1]) == [0, 1]
    end

    # 5W1H | Who: prover. What: conversion version handles only the trivial [0]+[0] case. When/Where: article Solution 1 partial credit. How: single assert. Why: isolates what the buggy version gets right.
    # STAR | Situation: [0]+[0]. Task: prove [0]. Action: add_two_numbers. Result: [0].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "conversion version handles zero" do
      assert AddTwoNumbersConvert.add_two_numbers(from_list([0]), from_list([0])) |> to_list() == [0]
    end
  end

  describe "Add Two Numbers: reversed-output bugs (article errors documented)" do
    @describetag :documented_error
    # 5W1H | Who: prover + future AI reader. What: ARTICLE ERROR — integer-conversion returns digits FORWARD ([8,0,7]) because build_list prepends least-significant-first. When/Where: article Solution 1. How: assert actual + refute expected. Why: prepend-direction confusion.
    # STAR | Situation: 342+465=807, article implies [7,0,8]. Task: prove actual. Action: add_two_numbers. Result: [8,0,7], refutes [7,0,8].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | add_two_numbers([2,4,3], [5,6,4])   (AddTwoNumbersConvert)
    #        list_to_integer([2,4,3], 0, 1) = 2*1 + 4*10 + 3*100 = 342
    #        list_to_integer([5,6,4], 0, 1) = 465
    #        sum = 807
    #        build_list(807, nil): 807→7 | 80→0 | 8→8 | 0→stop
    #        ▼ LN{8, LN{0, LN{7}}} = [8,0,7]     ← article error: LSB prepended, never reversed
    @tag :documented_error
    test "conversion version returns forward order" do
      assert AddTwoNumbersConvert.add_two_numbers(from_list([2, 4, 3]), from_list([5, 6, 4])) |> to_list() == [8, 0, 7]
      refute AddTwoNumbersConvert.add_two_numbers(from_list([2, 4, 3]), from_list([5, 6, 4])) |> to_list() == [7, 0, 8]
    end

    # 5W1H | Who: prover + future AI reader. What: ARTICLE ERROR — accumulator version returns [8,0,7], contradicting the "built in the correct order" claim; prepending LSB-first yields MSB-first. When/Where: article Solution 3. How: assert actual + refute expected. Why: same prepend-direction confusion, plus a false correctness claim.
    # STAR | Situation: [2,4,3]+[5,6,4]. Task: prove actual. Action: add_two_numbers. Result: [8,0,7], refutes [7,0,8].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | add_two_numbers([2,4,3], [5,6,4])   (AddTwoNumbersAcc — same digits, reversed output)
    #        7 → acc = LN{7, nil}
    #        10 → acc = LN{0, LN{7}}
    #        8  → acc = LN{8, LN{0, LN{7}}}
    #        base case returns acc AS-IS — never reversed
    #        ▼ [8,0,7]                     ← article error: 807 reads backwards
    @tag :documented_error
    test "accumulator version returns forward order" do
      assert AddTwoNumbersAcc.add_two_numbers(from_list([2, 4, 3]), from_list([5, 6, 4])) |> to_list() == [8, 0, 7]
      refute AddTwoNumbersAcc.add_two_numbers(from_list([2, 4, 3]), from_list([5, 6, 4])) |> to_list() == [7, 0, 8]
    end

    # 5W1H | Who: prover + future AI reader. What: ARTICLE ERROR — plain-list version misaligns place values on UNEVEN lengths: reversing then pairing head-to-head aligns MSB-with-MSB, but addition needs LSB-with-LSB; 81+0 yields [8,1] (=18). When/Where: article Solution 4, never tested uneven. How: assert actual wrong value. Why: reverse-then-zip only works for equal lengths.
    # STAR | Situation: [1,8]+[0] is 81+0=81, expect [1,8]. Task: prove actual. Action: add_two_numbers. Result: [8,1] (wrong value, not just order).
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | add_two_numbers([1,8], [0])   (AddTwoNumbersLists — 81 + 0)
    #        Enum.reverse([1,8]) = [8,1]   ← head is now the TENS digit of 81
    #        Enum.reverse([0])   = [0]     ← head is the UNITS digit of 0
    #        do_add pairs head-to-head: 8+0=8, then 1+0=1 → acc = [1,8]
    #        Enum.reverse(acc) = [8,1]
    #        ▼ [8,1]   → reads as 18, not 81     ← article error: reverse-then-zip only aligns equal lengths
    @tag :documented_error
    test "plain-list version misaligns uneven lengths" do
      assert AddTwoNumbersLists.add_two_numbers([1, 8], [0]) == [8, 1]
      refute AddTwoNumbersLists.add_two_numbers([1, 8], [0]) == [1, 8]
    end
  end
end

# Longest Substring article code, inlined here (this repo never uses /lib).
# NOTE: the article names every version `Solution` in separate blocks;
# they are renamed here so all three can coexist in one file.
defmodule SubstrBrute do
  @spec length_of_longest_substring(s :: String.t()) :: integer
  def length_of_longest_substring(s) do
    n = String.length(s)

    0..(n - 1)
    |> Enum.flat_map(fn i ->
      (i + 1)..n
      |> Enum.map(fn j -> String.slice(s, i, j - i) end)
    end)
    |> Enum.filter(&has_unique_chars?/1)
    |> Enum.map(&String.length/1)
    |> Enum.max(fn -> 0 end)
  end

  defp has_unique_chars?(str) do
    chars = String.graphemes(str)
    length(chars) == length(Enum.uniq(chars))
  end
end

defmodule SubstrRec do
  @spec length_of_longest_substring(s :: String.t()) :: integer
  def length_of_longest_substring(s) do
    s |> String.graphemes() |> find_longest(0, 0, 0, %{})
  end

  defp find_longest([], _left, _right, max_len, _last_seen), do: max_len

  defp find_longest([char | rest], left, right, max_len, last_seen) do
    new_left =
      case Map.get(last_seen, char) do
        nil -> left
        prev_index when prev_index >= left -> prev_index + 1
        _ -> left
      end

    new_max = max(max_len, right - new_left + 1)
    new_seen = Map.put(last_seen, char, right)

    find_longest(rest, new_left, right + 1, new_max, new_seen)
  end
end

defmodule SubstrReduceWhile do
  @spec length_of_longest_substring(s :: String.t()) :: integer
  def length_of_longest_substring(s) do
    s
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.reduce_while({0, 0, 0, %{}}, fn {char, right}, {left, max_len, _right, last_seen} ->
      new_left =
        case Map.get(last_seen, char) do
          nil -> left
          prev_index when prev_index >= left -> prev_index + 1
          _ -> left
        end

      new_max = max(max_len, right - new_left + 1)
      new_seen = Map.put(last_seen, char, right)

      {:cont, {new_left, new_max, right + 1, new_seen}}
    end)
    |> elem(1)
  end
end

defmodule SubstrProofTest do
  # Proof suite for the article "Solving LeetCode's Longest Substring Without
  # Repeating Characters in Elixir" (Elixir 1.20.1 / OTP 29). Same convention.
  use ExUnit.Case, async: true

  describe "Longest Substring: examples and traps" do
    # 5W1H | Who: reader. What: all three versions pass the LeetCode examples plus classic traps (abba, dvdf), full-repeat, all-unique, single char, Unicode. When/Where: article examples + pitfalls. How: equality asserts per version. Why: baseline + trap coverage.
    # STAR | Situation: 10 inputs from "" to "éàüé". Task: lock every output. Action: run brute, rec, reduce_while on each. Result: 3,1,3,0,1,2,3,6,2,3 on all three.
    # FLOW (s = "abba", graphemes + with_index)
    # | i | char | left | max | last_seen          |
    # | 0 | a    | 0    | 1   | %{"a" => 0}        |
    # | 1 | b    | 0    | 2   | %{"a"=>0, "b"=>1}  |
    # | 2 | b    | 2    | 2   | %{"a"=>0, "b"=>2}  |  ← left jumps past prev b
    # | 3 | a    | 2    | 2   | %{"a"=>3, "b"=>2}  |
    #          ▼ elem(1) = 2
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | length_of_longest_substring("dvdf")
    #        | i | char | hit?        | left | max |
    #        | 0 | d    | nil         | 0    | 1   |
    #        | 1 | v    | nil         | 0    | 2   |
    #        | 2 | d    | 0 ≥ 0       | 1    | 2   |
    #        | 3 | f    | nil         | 1    | 3   |
    #        ▼ 3
    test "all versions agree on examples, traps and edges" do
      cases = [
        {"abcabcbb", 3},
        {"bbbbb", 1},
        {"pwwkew", 3},
        {"a", 1},
        {"abba", 2},
        {"dvdf", 3},
        {"abcdef", 6},
        {"aaaaab", 2},
        {"éàüé", 3}
      ]

      for {s, expected} <- cases do
        assert SubstrBrute.length_of_longest_substring(s) == expected
        assert SubstrRec.length_of_longest_substring(s) == expected
        assert SubstrReduceWhile.length_of_longest_substring(s) == expected
      end
    end

    # 5W1H | Who: prover. What: empty string returns 0 on all three (brute via Enum.max default, sliding windows via base acc). When/Where: article pitfalls (empty input). How: asserts; brute wrapped in stderr capture (see next test). Why: empty-input contract.
    # STAR | Situation: "". Task: prove 0. Action: run rec and reduce_while directly. Result: 0, 0.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "empty string returns zero" do
      assert SubstrRec.length_of_longest_substring("") == 0
      assert SubstrReduceWhile.length_of_longest_substring("") == 0
    end

    # 5W1H | Who: prover + future AI reader. What: MINOR WART — brute force on "" still returns 0 but emits TWO decreasing-Range warnings (0..-1 and inner (i+1)..n); the article credits Enum.max(fn->0 end) yet omits this noise. When/Where: article Solution 1 on empty input, Elixir 1.20. How: capture stderr, assert result + warning text. Why: keeps suite output clean and documents the wart.
    # STAR | Situation: length_of_longest_substring(""). Task: prove 0 AND the warnings. Action: run with stderr captured. Result: 0 with "Range" warnings present.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    @tag :wart
    test "brute force on empty string warns but returns zero" do
      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          send(self(), {:res, SubstrBrute.length_of_longest_substring("")})
        end)

      receive do
        {:res, result} -> assert result == 0
      end

      assert output =~ "Range"
    end
  end
end

# Longest Palindromic Substring article code, inlined here (this repo never
# uses /lib). NOTE: the article names every version `Solution`; renamed here.
defmodule PalinBrute do
  @spec longest_palindrome(s :: String.t()) :: String.t()
  def longest_palindrome(s) do
    n = String.length(s)

    0..(n - 1)
    |> Enum.flat_map(fn i ->
      (i + 1)..n
      |> Enum.map(fn j -> String.slice(s, i, j - i) end)
    end)
    |> Enum.filter(&palindrome?/1)
    |> Enum.max_by(&String.length/1, fn -> "" end)
  end

  defp palindrome?(str), do: str == String.reverse(str)
end

# Expand-around-center with the article's guard FIXED: the printed guard
# `when ... and Enum.at(chars, left) == Enum.at(chars, right)` does not
# compile (Enum.at/2 is not guard-safe), so the comparison moved into the body.
defmodule PalinExpandFixed do
  @spec longest_palindrome(s :: String.t()) :: String.t()
  def longest_palindrome(s) do
    chars = String.graphemes(s)
    n = length(chars)

    {start, max_len} =
      0..(n - 1)
      |> Enum.reduce({0, 0}, fn i, {best_start, best_len} ->
        {s1, l1} = expand(chars, i, i)
        {s2, l2} = expand(chars, i, i + 1)
        {cs, cl} = if l1 >= l2, do: {s1, l1}, else: {s2, l2}
        if cl > best_len, do: {cs, cl}, else: {best_start, best_len}
      end)

    chars |> Enum.slice(start, max_len) |> Enum.join()
  end

  defp expand(chars, left, right), do: expand(chars, left, right, length(chars))

  defp expand(chars, left, right, n) when left >= 0 and right < n do
    if Enum.at(chars, left) == Enum.at(chars, right) do
      expand(chars, left - 1, right + 1, n)
    else
      {left + 1, right - left - 1}
    end
  end

  defp expand(_chars, left, right, _n), do: {left + 1, right - left - 1}
end

defmodule PalinProofTest do
  # Proof suite for the article "Solving LeetCode's Longest Palindromic
  # Substring in Elixir" (Elixir 1.20.1 / OTP 29). Same convention.
  use ExUnit.Case, async: true

  # The article's expand/4 clause, VERBATIM (guard calls Enum.at/2).
  # Kept as a string: it must never compile into this suite.
  @verbatim_expand_src """
  defmodule VerbatimExpand do
    defp expand(chars, left, right, n) when left >= 0 and right < n and Enum.at(chars, left) == Enum.at(chars, right) do
      expand(chars, left - 1, right + 1, n)
    end
    defp expand(_chars, left, right, _n), do: {left + 1, right - left - 1}
  end
  """

  # The article's Manacher implementation, VERBATIM (renamed module only).
  # Kept as a string: compiling it into the suite would emit rebinding
  # warnings, and its behavior is the bug under proof.
  @verbatim_manacher_src """
  defmodule VerbatimManacher do
    def longest_palindrome(s) do
      t = "#" <> Enum.join(String.graphemes(s), "#") <> "#"
      chars = String.graphemes(t)
      n = length(chars)
      p = :array.new(n, default: 0)
      {center, right} =
        Enum.reduce(0..(n - 1), {0, 0}, fn i, {c, r} ->
          mirror = 2 * c - i
          initial = if i < r, do: min(r - i, :array.get(mirror, p)), else: 0
          {fr, _} = expand_man(chars, i - initial, i + initial, n, initial, p, i)
          new_p = :array.set(i, fr, p)
          p = new_p
          if i + fr > r, do: {i, i + fr}, else: {c, r}
        end)
      {ml, mc} =
        Enum.reduce(0..(n - 1), {0, 0}, fn i, {m1, mcc} ->
          radius = :array.get(i, p)
          if radius > m1, do: {radius, i}, else: {m1, mcc}
        end)
      _ = {center, right}
      s |> String.slice(div(mc - ml, 2), ml)
    end
    defp expand_man(chars, l, r, n, radius, p, i) do
      if l >= 0 and r < n and Enum.at(chars, l) == Enum.at(chars, r) do
        expand_man(chars, l - 1, r + 1, n, radius + 1, p, i)
      else
        {radius, p}
      end
    end
  end
  """

  describe "Palindrome: correct versions" do
    # 5W1H | Who: reader. What: brute force passes both LeetCode examples plus unambiguous cases (even, all-same, single, unicode). When/Where: article Solution 1. How: equality asserts. Why: baseline correctness.
    # STAR | Situation: "babad", "cbbd", "racecar", "abba", "a", "aaaa", "été", "abcde". Task: lock outputs. Action: longest_palindrome each. Result: "bab", "bb", "racecar", "abba", "a", "aaaa", "été", "a".
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | longest_palindrome("babad")   (PalinBrute) — different path, same answer
    #        all substrings in i-major order → filter palindrome → max_by length (first max wins)
    #        candidates of length 3: "bab" (i=0), "aba" (i=1)
    #        ▼ "bab"
    test "brute force passes examples and cases" do
      assert PalinBrute.longest_palindrome("babad") == "bab"
      assert PalinBrute.longest_palindrome("cbbd") == "bb"
      assert PalinBrute.longest_palindrome("racecar") == "racecar"
      assert PalinBrute.longest_palindrome("abba") == "abba"
      assert PalinBrute.longest_palindrome("a") == "a"
      assert PalinBrute.longest_palindrome("aaaa") == "aaaa"
      assert PalinBrute.longest_palindrome("été") == "été"
      assert PalinBrute.longest_palindrome("abcde") == "a"
    end

    # 5W1H | Who: reader. What: FIXED expand-around-center matches brute force on every case above. When/Where: article Solution 2 after moving Enum.at out of the guard. How: equality asserts. Why: proves the algorithm once the guard is fixed.
    # STAR | Situation: same eight inputs. Task: lock agreement. Action: longest_palindrome each. Result: identical outputs.
    # FLOW ("babad": odd (i,i) vs even (i,i+1) per center, keep longest)
    # i=0: odd {0,1} "b", even {1,0} → best {0,1}
    # i=1: odd expand(1,1)→(0,2)→(-1,3) = {0,3} "bab" → best {0,3}
    # i=2..3: length 3 never beaten
    #          ▼ slice(0, 3) = "bab"
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "fixed expand matches brute force" do
      for s <- ["babad", "cbbd", "racecar", "abba", "a", "aaaa", "été", "abcde", "abcba", "abccba", "bananas", "aabbaa"] do
        assert PalinExpandFixed.longest_palindrome(s) == PalinBrute.longest_palindrome(s)
      end
    end
  end

  describe "Palindrome: critical article errors (documented)" do
    @describetag :documented_error
    # 5W1H | Who: prover + future AI reader. What: CRITICAL — the printed expand/4 guard calls Enum.at/2, which is NOT guard-safe: the flagship solution does not compile as printed. When/Where: article Solution 2. How: assert_raise CompileError on verbatim source, stderr captured. Why: guard-safe boundary every Elixir dev must know.
    # STAR | Situation: verbatim guard with Enum.at. Task: prove it fails. Action: Code.compile_string. Result: CompileError (cannot invoke remote Enum.at/2 inside guard).
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    @tag :documented_error
    test "verbatim expand guard does not compile" do
      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        send(self(), {:raised, assert_raise(CompileError, fn -> Code.compile_string(@verbatim_expand_src) end)})
      end)

      receive do
        {:raised, _} -> :ok
      end
    end

    # 5W1H | Who: prover + future AI reader. What: CRITICAL — verbatim Manacher returns "" for EVERY input: `p = new_p` rebinds inside the fn body so radius updates never escape the iteration, and the final scan reads the pristine all-zero array (max radius 0, length 0). When/Where: article Solution 3. How: runtime-compile verbatim source (stderr captured), assert "" on three inputs. Why: rebinding-vs-threading through Enum acc. Fix: thread p as {c, r, p} and scan the returned array.
    # STAR | Situation: verbatim Manacher on "babad", "cbbd", "racecar". Task: prove empty results. Action: compile source, run each. Result: "", "", "".
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    @tag :documented_error
    test "verbatim Manacher always returns empty string" do
      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        send(self(), {:mods, Code.compile_string(@verbatim_manacher_src)})
      end)

      [{mod, _}] =
        receive do
          {:mods, mods} -> mods
        end

      assert apply(mod, :longest_palindrome, ["babad"]) == ""
      assert apply(mod, :longest_palindrome, ["cbbd"]) == ""
      assert apply(mod, :longest_palindrome, ["racecar"]) == ""
    end
  end
end

# Zigzag Conversion article code, inlined here (this repo never uses /lib).
# NOTE: the article names every version `Solution`; renamed here so the two
# real simulations can coexist. Solution 3 is a stub (see test below) and is
# compiled from a verbatim source string instead of a defmodule, because its
# unused variables would otherwise pollute the suite with warnings.
defmodule ZigzagMap do
  @spec convert(s :: String.t(), num_rows :: integer) :: String.t()
  def convert(s, num_rows) do
    if num_rows == 1 or num_rows >= String.length(s) do
      s
    else
      s
      |> String.graphemes()
      |> build_rows(num_rows, 0, 1, %{})
      |> rows_in_order(num_rows)
      |> Enum.join()
    end
  end

  defp build_rows([], _num_rows, _row, _direction, acc), do: acc

  defp build_rows([char | rest], num_rows, row, direction, acc) do
    acc = Map.update(acc, row, [char], &(&1 ++ [char]))
    {next_row, next_dir} = next_position(row, direction, num_rows)
    build_rows(rest, num_rows, next_row, next_dir, acc)
  end

  defp next_position(row, direction, num_rows) do
    next = row + direction

    cond do
      next < 0 -> {1, 1}
      next >= num_rows -> {num_rows - 2, -1}
      true -> {next, direction}
    end
  end

  defp rows_in_order(map, num_rows) do
    Enum.map(0..(num_rows - 1), fn i -> Map.get(map, i, []) end)
  end
end

defmodule ZigzagList do
  @spec convert(s :: String.t(), num_rows :: integer) :: String.t()
  def convert(s, num_rows) do
    if num_rows == 1 or num_rows >= String.length(s) do
      s
    else
      rows = List.duplicate([], num_rows)

      s
      |> String.graphemes()
      |> build_rows_list(num_rows, 0, 1, rows)
      |> Enum.join()
    end
  end

  defp build_rows_list([], _num_rows, _row, _direction, rows), do: rows

  defp build_rows_list([char | rest], num_rows, row, direction, rows) do
    rows = List.update_at(rows, row, fn r -> r ++ [char] end)
    {next_row, next_dir} = next_position(row, direction, num_rows)
    build_rows_list(rest, num_rows, next_row, next_dir, rows)
  end

  defp next_position(row, direction, num_rows) do
    next = row + direction

    cond do
      next < 0 -> {1, 1}
      next >= num_rows -> {num_rows - 2, -1}
      true -> {next, direction}
    end
  end
end

defmodule ZigzagProofTest do
  # Proof suite for the article "Solving LeetCode's Zigzag Conversion in
  # Elixir" (Elixir 1.20.1 / OTP 29). Same convention.
  use ExUnit.Case, async: true

  # Solution 3 ("Mathematical Pattern"), VERBATIM (renamed module only).
  # The unfold step body is literally comments, so every row builds "".
  @verbatim_math_src """
  defmodule VerbatimZigzagMath do
    def convert(s, num_rows) do
      if num_rows == 1, do: s, else: do_convert(s, num_rows)
    end
    defp do_convert(s, num_rows) do
      chars = String.graphemes(s)
      n = length(chars)
      cycle = 2 * num_rows - 2
      0..(num_rows - 1)
      |> Enum.map(fn row -> build_row(chars, n, row, cycle) end)
      |> Enum.join()
    end
    defp build_row(chars, n, row, cycle) do
      Stream.unfold(0, fn step ->
        # compute positions for this row
        # ...
      end)
      |> Enum.take_while(&(&1 < n))
      |> Enum.map(&Enum.at(chars, &1))
      |> Enum.join()
    end
  end
  """

  describe "Zigzag: simulations" do
    # 5W1H | Who: reader. What: map simulation passes both LeetCode examples plus direction/edge cases (2 rows, rows > length, 1 row, punctuation). When/Where: article Solution 1. How: equality asserts. Why: recommended approach correctness.
    # STAR | Situation: PAYPALISHIRING/3, /4, A/1, /2, AB/5, HELLO/1, a,b.c/2. Task: lock outputs. Action: convert each. Result: PAHNAPLSIIGYIR, PINALSIGYAHRPI, A, PYAIHRNAPLSIIG, AB, HELLO, abc,..
    # FLOW ("PAYPALISHIRING", rows=3: row cycle 0,1,2,1,…)
    # P0 A1 Y2 P1 A0 L1 I2 S1 H0 I1 R2 I1 N0 G1
    # row 0 ▼ "PAHN" | row 1 ▼ "APLSIIG" | row 2 ▼ "YIR"
    #          ▼ "PAHN" <> "APLSIIG" <> "YIR" = "PAHNAPLSIIGYIR"
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | convert("A", 3)   (early exit)
    #        num_rows (3) >= String.length("A") (1) → return input unchanged
    #        ▼ "A"
    test "map simulation passes examples and edges" do
      assert ZigzagMap.convert("PAYPALISHIRING", 3) == "PAHNAPLSIIGYIR"
      assert ZigzagMap.convert("PAYPALISHIRING", 4) == "PINALSIGYAHRPI"
      assert ZigzagMap.convert("A", 1) == "A"
      assert ZigzagMap.convert("PAYPALISHIRING", 2) == "PYAIHRNAPLSIIG"
      assert ZigzagMap.convert("AB", 5) == "AB"
      assert ZigzagMap.convert("A", 3) == "A"
      assert ZigzagMap.convert("HELLO", 1) == "HELLO"
      assert ZigzagMap.convert("a,b.c", 2) == "abc,."
    end

    # 5W1H | Who: reader. What: list-of-rows version agrees with the map version on every case above. When/Where: article Solution 2. How: equality asserts against ZigzagMap. Why: proves same traversal, different accumulator.
    # STAR | Situation: same eight inputs. Task: lock agreement. Action: convert each with both. Result: identical outputs.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "list version agrees with map version" do
      for {s, r} <- [
            {"PAYPALISHIRING", 3},
            {"PAYPALISHIRING", 4},
            {"A", 1},
            {"PAYPALISHIRING", 2},
            {"AB", 5},
            {"A", 3},
            {"HELLO", 1},
            {"a,b.c", 2}
          ] do
        assert ZigzagList.convert(s, r) == ZigzagMap.convert(s, r)
      end
    end
  end

  describe "Zigzag: stub solution (article error documented)" do
    @describetag :documented_error
    # 5W1H | Who: prover + future AI reader. What: CRITICAL — Solution 3 is an unfinished STUB: the unfold step body is only comments, so it halts immediately and every row is ""; both examples return "". When/Where: article "Mathematical Pattern". How: runtime-compile verbatim source (stderr captured for its unused-var warnings), assert "". Why: sketches presented as implementations.
    # STAR | Situation: verbatim math solution on both LeetCode examples. Task: prove empty results. Action: compile source, convert each. Result: "", "".
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | @verbatim_math_src
    #        build_row → Stream.unfold(0, fn step -> # comments only end)
    #        the step body evaluates to nil → unfold halts at element 0 → Enum.take_while → []
    #        every row builds ""
    #        ▼ "" for ALL inputs (article error: the "Mathematical Pattern" is a stub)
    @tag :documented_error
    test "math-pattern stub always returns empty string" do
      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        send(self(), {:mods, Code.compile_string(@verbatim_math_src)})
      end)

      [{mod, _}] =
        receive do
          {:mods, mods} -> mods
        end

      assert apply(mod, :convert, ["PAYPALISHIRING", 3]) == ""
      assert apply(mod, :convert, ["PAYPALISHIRING", 4]) == ""
    end
  end
end

# Reverse Integer article code, inlined here (this repo never uses /lib).
# NOTE: the article names every version `Solution`; renamed here so all four
# can coexist in one file.
defmodule RevStr do
  @spec reverse(x :: integer) :: integer
  def reverse(x) do
    sign = if x < 0, do: -1, else: 1
    x = abs(x)

    reversed =
      x
      |> Integer.to_string()
      |> String.reverse()
      |> String.to_integer()

    result = reversed * sign

    if result < -2_147_483_648 or result > 2_147_483_647 do
      0
    else
      result
    end
  end
end

defmodule RevMath do
  @spec reverse(x :: integer) :: integer
  def reverse(x) do
    sign = if x < 0, do: -1, else: 1
    reversed = do_reverse(abs(x), 0)
    result = reversed * sign

    if result < -2_147_483_648 or result > 2_147_483_647 do
      0
    else
      result
    end
  end

  defp do_reverse(0, acc), do: acc

  defp do_reverse(n, acc) do
    do_reverse(div(n, 10), acc * 10 + rem(n, 10))
  end
end

defmodule RevDigits do
  @spec reverse(x :: integer) :: integer
  def reverse(x) do
    sign = if x < 0, do: -1, else: 1

    reversed =
      x
      |> abs()
      |> Integer.digits()
      |> Enum.reverse()
      |> Integer.undigits()

    result = reversed * sign

    if result < -2_147_483_648 or result > 2_147_483_647 do
      0
    else
      result
    end
  end
end

defmodule RevSafe do
  @max 2_147_483_647
  @min -2_147_483_648

  @spec reverse(x :: integer) :: integer
  def reverse(x) do
    sign = if x < 0, do: -1, else: 1
    do_reverse(abs(x), 0, sign)
  end

  defp do_reverse(0, res, sign) do
    result = res * sign
    if result < @min or result > @max, do: 0, else: result
  end

  defp do_reverse(n, res, sign) do
    digit = rem(n, 10)

    if res > div(@max, 10) or (res == div(@max, 10) and digit > 7) do
      0
    else
      do_reverse(div(n, 10), res * 10 + digit, sign)
    end
  end
end

defmodule ReverseIntProofTest do
  # Proof suite for the article "Solving LeetCode's Reverse Integer in Elixir"
  # (Elixir 1.20.1 / OTP 29). Same convention.
  use ExUnit.Case, async: true

  describe "Reverse Integer: examples and boundaries" do
    # 5W1H | Who: reader. What: all four versions pass the LeetCode examples (sign, trailing zero, overflow-to-zero). When/Where: article examples 1-4. How: equality asserts per version. Why: baseline correctness.
    # STAR | Situation: 123, -123, 120, 1534236469. Task: lock outputs. Action: reverse each on all four. Result: 321, -321, 21, 0 everywhere.
    # FLOW (reverse(123) via do_reverse/2 accumulator)
    # (123, 0) → (12, 3) → (1, 32) → (0, 321)
    #          ▼ 321
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | 120 → RevStr  : abs → 120 → "120" → String.reverse → "021" → String.to_integer → 21 → × sign(1) → in range → 21
    # FLOW | 120 → RevMath : do_reverse(120, 0) → (12, 0) → (1, 2) → (0, 21) → 21 → × sign → 21
    # FLOW | 120 → RevDigits: abs → 120 → Integer.digits → [1,2,0] → reverse → [0,2,1] → undigits → 21 → × sign → 21
    # FLOW | 120 → RevSafe : do_reverse(120, 0, 1) → digit 0, res 0 → (12, 0, 1) → digit 2, res 0 → (1, 2, 1) → digit 1, res 2 → (0, 21, 1) → 21 → in range → 21
    test "all versions pass the four examples" do
      for {x, expected} <- [{123, 321}, {-123, -321}, {120, 21}, {1_534_236_469, 0}] do
        assert RevStr.reverse(x) == expected
        assert RevMath.reverse(x) == expected
        assert RevDigits.reverse(x) == expected
        assert RevSafe.reverse(x) == expected
      end
    end

    # 5W1H | Who: reader. What: all four agree on zero, trailing zeros, single digits, 32-bit limits, near-limit reversals staying in range. When/Where: article constraints and pitfalls (overflow, negatives, leading zeros). How: equality asserts per version. Why: boundary contract.
    # STAR | Situation: 0, 10, 100, -120, ±max/min, ±1463847412, 1000000003. Task: lock outputs. Action: reverse each on all four. Result: identical correct values everywhere.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "all versions agree on edges and limits" do
      cases = [
        {0, 0},
        {5, 5},
        {-5, -5},
        {10, 1},
        {100, 1},
        {-120, -21},
        {2_147_483_647, 0},
        {-2_147_483_648, 0},
        {1_463_847_412, 2_147_483_641},
        {-1_463_847_412, -2_147_483_641},
        {1_000_000_003, 0}
      ]

      for {x, expected} <- cases do
        assert RevStr.reverse(x) == expected
        assert RevMath.reverse(x) == expected
        assert RevDigits.reverse(x) == expected
        assert RevSafe.reverse(x) == expected
      end
    end
  end

  describe "Reverse Integer: pre-check asymmetry (documented)" do
    @describetag :documented_error
    # 5W1H | Who: prover + future AI reader. What: SUBTLE — the safe-math `digit > 7` threshold encodes only MAX (…847); a reversal of exactly 2147483648 with negative sign is the valid MIN, but the pre-check returns 0. Unreachable under LeetCode constraints (it needs abs(x) = 8463847412), provable only with out-of-range input since Elixir has big ints. When/Where: article Solution 4. How: assert divergence on x = -8463847412. Why: thresholds copied from editorials carry hidden asymmetry.
    # STAR | Situation: x = -8463847412 (outside constraints). Task: expose asymmetry. Action: reverse with math vs safe versions. Result: -2147483648 vs 0.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | -8463847412   (the asymmetry the test exposes)
    #        RevMath : do_reverse(8463847412, 0) → 2147483648 → × sign(-1) → -2147483648
    #                  2147483648 fits as a MAGNITUDE → returns MIN
    #        RevSafe : res grows: …214748364 → next digit 8 > 7 → pre-check fires
    #                  → returns 0, even though -2147483648 is the valid MIN
    #        ▼ -2147483648 vs 0
    @tag :documented_error
    test "safe pre-check is exact only within constraints" do
      assert RevMath.reverse(-8_463_847_412) == -2_147_483_648
      assert RevSafe.reverse(-8_463_847_412) == 0
    end
  end
end

# String to Integer (atoi) article code, inlined here (this repo never uses
# /lib). NOTE: the article names every version `Solution`; renamed here so
# all three can coexist in one file.
defmodule AtoiRegex do
  @max 2_147_483_647
  @min -2_147_483_648

  @spec my_atoi(s :: String.t()) :: integer
  def my_atoi(s) do
    case Regex.run(~r/^\s*([+-]?\d+)/, s) do
      [_, num_str] ->
        {num, _} = Integer.parse(num_str)
        clamp(num)

      nil ->
        0
    end
  end

  defp clamp(num) when num > @max, do: @max
  defp clamp(num) when num < @min, do: @min
  defp clamp(num), do: num
end

defmodule AtoiRec do
  @max 2_147_483_647
  @min -2_147_483_648

  @spec my_atoi(s :: String.t()) :: integer
  def my_atoi(s) do
    chars = String.graphemes(s)
    {index, sign} = skip_whitespace_and_sign(chars, 0, 1)
    parse_digits(chars, index, sign, 0)
  end

  defp skip_whitespace_and_sign(chars, i, sign) do
    cond do
      i >= length(chars) -> {i, sign}
      Enum.at(chars, i) == " " -> skip_whitespace_and_sign(chars, i + 1, sign)
      Enum.at(chars, i) == "+" -> {i + 1, 1}
      Enum.at(chars, i) == "-" -> {i + 1, -1}
      true -> {i, sign}
    end
  end

  defp parse_digits(chars, i, sign, acc) do
    if i < length(chars) and digit?(Enum.at(chars, i)) do
      digit = String.to_integer(Enum.at(chars, i))

      cond do
        sign == 1 and (acc > div(@max, 10) or (acc == div(@max, 10) and digit > 7)) ->
          @max

        sign == -1 and (acc > div(-@min, 10) or (acc == div(-@min, 10) and digit > 8)) ->
          @min

        true ->
          parse_digits(chars, i + 1, sign, acc * 10 + digit)
      end
    else
      sign * acc
    end
  end

  defp digit?(char) when char >= "0" and char <= "9", do: true
  defp digit?(_), do: false
end

defmodule AtoiParse do
  @max 2_147_483_647
  @min -2_147_483_648

  @spec my_atoi(s :: String.t()) :: integer
  def my_atoi(s) do
    trimmed = String.trim_leading(s, " ")

    case Integer.parse(trimmed) do
      {num, _rest} -> clamp(num)
      :error -> 0
    end
  end

  defp clamp(num) when num > @max, do: @max
  defp clamp(num) when num < @min, do: @min
  defp clamp(num), do: num
end

defmodule AtoiProofTest do
  # Proof suite for the article "Solving LeetCode's String to Integer (atoi)
  # in Elixir" (Elixir 1.20.1 / OTP 29). Same convention.
  use ExUnit.Case, async: true

  describe "atoi: examples and edges" do
    # 5W1H | Who: reader. What: all three versions pass the five article examples (spaces, sign, trailing junk, no-digits). When/Where: article examples. How: equality asserts per version. Why: baseline parsing contract.
    # STAR | Situation: "42", " -042", "1337c0d3", "0-1", "words and 987". Task: lock outputs. Action: my_atoi each on all three. Result: 42, -42, 1337, 0, 0 everywhere.
    # FLOW (my_atoi(" -042") via skip + parse_digits)
    # skip " " → "-" sign, i=2 → digits 0, 4, 2 (acc 0 → 4 → 42)
    #          ▼ -1 * 42 = -42
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | my_atoi(" -042")   (AtoiRegex)
    #        ~r/^\s*([+-]?\d+)/ on " -042" → [" -042", "-042"]   ← \s* ate the space
    #        Integer.parse("-042") → {-42, ""} → clamp(-42)
    #        ▼ -42
    #
    # FLOW | my_atoi(" -042")   (AtoiRec)
    #        skip_whitespace_and_sign: i=0 " " → i=1; i=1 "-" → {2, -1}
    #        parse_digits: 0 → acc 0; 4 → acc 4; 2 → acc 42; i=4 ≥ len → sign * acc
    #        ▼ -42
    test "all versions pass the five examples" do
      for {s, expected} <- [
            {"42", 42},
            {" -042", -42},
            {"1337c0d3", 1337},
            {"0-1", 0},
            {"words and 987", 0}
          ] do
        assert AtoiRegex.my_atoi(s) == expected
        assert AtoiRec.my_atoi(s) == expected
        assert AtoiParse.my_atoi(s) == expected
      end
    end

    # 5W1H | Who: reader. What: all three agree on empties, lone signs, double signs, zeros, mid-string spaces, dots, exact limits and overflows. When/Where: article pitfalls + constraints. How: equality asserts per version. Why: edge-case contract incl. correct MIN handling (digit > 8) this time.
    # STAR | Situation: 16 edge inputs. Task: lock outputs. Action: my_atoi each on all three. Result: identical correct values everywhere.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "all versions agree on edges and limits" do
      cases = [
        {"", 0},
        {"   ", 0},
        {"+", 0},
        {"-", 0},
        {"+-2", 0},
        {"0032", 32},
        {"   +0 123", 0},
        {".5", 0},
        {"+ 413", 0},
        {"2147483647", 2_147_483_647},
        {"2147483648", 2_147_483_647},
        {"-2147483648", -2_147_483_648},
        {"-2147483649", -2_147_483_648},
        {"9999999999", 2_147_483_647},
        {"-9999999999", -2_147_483_648},
        {"00000-42a1234", 0}
      ]

      for {s, expected} <- cases do
        assert AtoiRegex.my_atoi(s) == expected
        assert AtoiRec.my_atoi(s) == expected
        assert AtoiParse.my_atoi(s) == expected
      end
    end
  end

  describe "atoi: whitespace divergence (article inconsistency documented)" do
    @describetag :documented_error
    # 5W1H | Who: prover + future AI reader. What: INTERNAL CONTRADICTION — the regex version skips ALL whitespace (\s: tab, newline), while the article's own pitfall rule says only ' ' counts and Solutions 2/3 enforce exactly that. When/Where: article Solution 1 vs its pitfalls + Solutions 2/3. How: assert divergence on "\t42" and "\n-42". Why: \s vs " " is a real spec fork.
    # STAR | Situation: leading tab/newline inputs. Task: prove the split. Action: my_atoi on all three. Result: regex 42/-42 vs 0/0 on the other two.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | my_atoi("\t42")   (the divergence)
    #        AtoiRegex : ^\s* matches "\t"         → 42
    #        AtoiRec   : skip_whitespace only skips " " → "\t" is not a digit → 0
    #        AtoiParse : String.trim_leading(s, " ") leaves "\t42" → Integer.parse → :error → 0
    #        ▼ 42  vs  0  vs  0
    @tag :documented_error
    test "tab and newline split the implementations" do
      assert AtoiRegex.my_atoi("\t42") == 42
      assert AtoiRec.my_atoi("\t42") == 0
      assert AtoiParse.my_atoi("\t42") == 0

      assert AtoiRegex.my_atoi("\n-42") == -42
      assert AtoiRec.my_atoi("\n-42") == 0
      assert AtoiParse.my_atoi("\n-42") == 0
    end
  end
end

# Palindrome Number article code, inlined here (this repo never uses /lib).
# NOTE: the article names every version `Solution`; renamed here so all five
# can coexist in one file. The first Solution 4 (half reversal returning only
# the accumulator) is kept verbatim as PalHalfBroken — the article itself
# walks through why it fails before presenting the tuple fix.
defmodule PalStr do
  @spec is_palindrome(x :: integer) :: boolean
  def is_palindrome(x) do
    original = Integer.to_string(x)
    original == String.reverse(original)
  end
end

defmodule PalTwoPtr do
  @spec is_palindrome(x :: integer) :: boolean
  def is_palindrome(x) do
    chars = x |> Integer.to_string() |> String.graphemes()
    n = length(chars)

    0..(div(n, 2) - 1)
    |> Enum.all?(fn i -> Enum.at(chars, i) == Enum.at(chars, n - 1 - i) end)
  end
end

defmodule PalFullMath do
  @spec is_palindrome(x :: integer) :: boolean
  def is_palindrome(x) when x < 0, do: false
  def is_palindrome(x) when x < 10, do: true
  def is_palindrome(x) when rem(x, 10) == 0, do: false
  def is_palindrome(x), do: x == reverse(x, 0)

  defp reverse(0, acc), do: acc
  defp reverse(n, acc), do: reverse(div(n, 10), acc * 10 + rem(n, 10))
end

defmodule PalHalfBroken do
  @spec is_palindrome(x :: integer) :: boolean
  def is_palindrome(x) when x < 0, do: false
  def is_palindrome(x) when x < 10, do: true
  def is_palindrome(x) when rem(x, 10) == 0, do: false

  def is_palindrome(x) do
    reversed = reverse_half(x, 0)
    x == reversed or x == div(reversed, 10)
  end

  defp reverse_half(n, acc) when n > acc do
    reverse_half(div(n, 10), acc * 10 + rem(n, 10))
  end

  defp reverse_half(_n, acc), do: acc
end

defmodule PalHalfFixed do
  @spec is_palindrome(x :: integer) :: boolean
  def is_palindrome(x) when x < 0, do: false
  def is_palindrome(x) when x < 10, do: true
  def is_palindrome(x) when rem(x, 10) == 0, do: false

  def is_palindrome(x) do
    {first_half, reversed} = reverse_half(x, 0)
    first_half == reversed or first_half == div(reversed, 10)
  end

  defp reverse_half(n, acc) when n > acc do
    reverse_half(div(n, 10), acc * 10 + rem(n, 10))
  end

  defp reverse_half(n, acc), do: {n, acc}
end

defmodule PalNumProofTest do
  # Proof suite for the article "Solving LeetCode's Palindrome Number in
  # Elixir" (Elixir 1.20.1 / OTP 29). Same convention.
  use ExUnit.Case, async: true

  describe "Palindrome Number: correct versions" do
    # 5W1H | Who: reader. What: string version passes the LeetCode examples plus single digits, trailing zeros, even/odd lengths. When/Where: article Solution 1. How: equality asserts. Why: baseline correctness.
    # STAR | Situation: 121, -121, 10, 0, 5, 1221, 12321, 123, 100, 1001. Task: lock outputs. Action: is_palindrome each. Result: true, false, false, true, true, true, true, false, false, true.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | is_palindrome(121) → PalStr: "121" == String.reverse("121") → "121" == "121" → true
    # FLOW | is_palindrome(10)  → PalStr: "10" == "01" → false
    test "string version passes examples and edges" do
      for {x, expected} <- [
            {121, true},
            {-121, false},
            {10, false},
            {0, true},
            {5, true},
            {1221, true},
            {12321, true},
            {123, false},
            {100, false},
            {1001, true}
          ] do
        assert PalStr.is_palindrome(x) == expected
      end
    end

    # 5W1H | Who: reader. What: full math reversal matches the string version on every case above. When/Where: article Solution 3. How: equality asserts. Why: optimal no-string correctness.
    # STAR | Situation: same ten inputs. Task: lock agreement. Action: is_palindrome each. Result: identical outputs.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "full math reversal matches string version" do
      for x <- [121, -121, 10, 0, 5, 1221, 12321, 123, 100, 1001] do
        assert PalFullMath.is_palindrome(x) == PalStr.is_palindrome(x)
      end
    end

    # 5W1H | Who: reader. What: FIXED half reversal (tuple version) matches on every case. When/Where: article corrected Solution 4. How: equality asserts. Why: gold-standard correctness.
    # STAR | Situation: same ten inputs. Task: lock agreement. Action: is_palindrome each. Result: identical outputs.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | is_palindrome(121)   (PalHalfFixed — the tuple version)
    #        reverse_half(121, 0): 121 > 0  → (12, 1)
    #                            12  > 1  → (1, 12)
    #                            1   > 12? no → {1, 12}      ← returns BOTH halves
    #        first_half(1) == reversed(12)? no
    #        first_half(1) == div(12,10)=1? yes
    #        ▼ true
    #
    # FLOW | is_palindrome(121)   (PalHalfBroken — same walk, wrong comparison)
    #        reverse_half returns just 12
    #        x(121) == 12? no
    #        x(121) == div(12,10)=1? no
    #        ▼ false     ← article error: compares x against the reversed HALF
    test "fixed half reversal matches string version" do
      for x <- [121, -121, 10, 0, 5, 1221, 12321, 123, 100, 1001] do
        assert PalHalfFixed.is_palindrome(x) == PalStr.is_palindrome(x)
      end
    end

    # 5W1H | Who: prover. What: two-pointer version is correct for multi-digit inputs (its bug needs a single digit). When/Where: article Solution 2, n >= 2. How: equality asserts. Why: isolates the working range.
    # STAR | Situation: 121, 1221, 10, 123, 1001. Task: lock outputs. Action: is_palindrome each. Result: true, true, false, false, true.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "two-pointer version works for multi-digit inputs" do
      for {x, expected} <- [{121, true}, {1221, true}, {10, false}, {123, false}, {1001, true}] do
        assert PalTwoPtr.is_palindrome(x) == expected
      end
    end
  end

  describe "Palindrome Number: article errors (documented)" do
    @describetag :documented_error
    # 5W1H | Who: prover + future AI reader. What: ARTICLE ERROR — two-pointer on a SINGLE digit builds 0..-1 (decreasing range, warns) and compares the char against out-of-range nil, returning false for true palindromes 0-9. When/Where: article Solution 2, n = 1. How: assert false with stderr captured. Why: single-element range edge.
    # STAR | Situation: is_palindrome(5). Task: prove the wrong answer. Action: run with stderr captured. Result: false (plus Range warning).
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | is_palindrome(5)   (PalTwoPtr)
    #        chars ["5"], n=1 → 0..(div(1,2)-1) = 0..-1   ← decreasing range → warning
    #        i=0: chars[0]==chars[0] ✓ → i=-1: Enum.at(["5"],-1)="5" vs Enum.at(["5"],1)=nil ✗
    #        ▼ false (correct answer would be true)
    test "two-pointer fails single digits" do
      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        send(self(), {:res, PalTwoPtr.is_palindrome(5)})
      end)

      receive do
        {:res, result} -> assert result == false
      end
    end

    # 5W1H | Who: prover + future AI reader. What: ARTICLE'S OWN TRACE ADMITS IT — first half-reversal compares the ORIGINAL x against the reversed half (121 vs 12), so every multi-digit palindrome returns false. When/Where: article Solution 4 before its self-correction. How: assert false on known palindromes. Why: compares wrong halves.
    # STAR | Situation: 121, 1221, 12321, 1001. Task: prove the failure. Action: is_palindrome each. Result: false, false, false, false.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    @tag :documented_error
    test "first half-reversal rejects real palindromes" do
      for x <- [121, 1221, 12321, 1001] do
        assert PalHalfBroken.is_palindrome(x) == false
      end
    end

    # 5W1H | Who: prover + future AI reader. What: FACTUAL ERROR — article claims div(-121, 10) returns -13; Elixir div truncates toward zero, so it is -12 (floor_div would give -13). rem(-121, 10) == -1 is correct. When/Where: article pitfalls on negative rem/div. How: equality asserts. Why: truncated vs floored division.
    # STAR | Situation: div(-121, 10), rem(-121, 10). Task: prove actual values. Action: evaluate both. Result: -12 (refutes -13), -1.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | div(-121, 10)
    #        Elixir div truncates toward zero → -12
    #        (floor_div would give -13 — the article's claim)
    #        ▼ -12,  and rem(-121, 10) → -1
    @tag :documented_error
    test "negative div truncates toward zero" do
      assert div(-121, 10) == -12
      refute div(-121, 10) == -13
      assert rem(-121, 10) == -1
    end
  end
end

# Regex Matching article code, inlined here (this repo never uses /lib).
# NOTE: the article names every version `Solution`; renamed here.
# RegexNaive is verbatim. RegexDPFixed is verbatim EXCEPT the table init
# (flat generators instead of nested for-into-map — see bug test below).
# Solution 2 (memoized) is compiled from a verbatim source string at test
# time because its `_s`/`_p`-in-guard style emits compile warnings.
defmodule RegexNaive do
  @spec is_match(s :: String.t(), p :: String.t()) :: boolean
  def is_match(s, p) do
    match(String.graphemes(s), String.graphemes(p))
  end

  defp match([], []), do: true
  defp match(_, []), do: false

  defp match(s, [p_char, "*" | rest_p]) do
    zero_occurrences = match(s, rest_p)

    one_or_more =
      case s do
        [s_char | rest_s] when s_char == p_char or p_char == "." ->
          match(rest_s, [p_char, "*" | rest_p])

        _ ->
          false
      end

    zero_occurrences or one_or_more
  end

  defp match([s_char | rest_s], [p_char | rest_p]) do
    (s_char == p_char or p_char == ".") and match(rest_s, rest_p)
  end

  defp match([], _), do: false
end

defmodule RegexDPFixed do
  @spec is_match(s :: String.t(), p :: String.t()) :: boolean
  def is_match(s, p) do
    s_chars = String.graphemes(s)
    p_chars = String.graphemes(p)
    m = length(s_chars)
    n = length(p_chars)

    dp = for i <- 0..m, j <- 0..n, into: %{}, do: {{i, j}, false}
    dp = Map.put(dp, {0, 0}, true)

    dp =
      Enum.reduce(1..n, dp, fn j, acc ->
        if Enum.at(p_chars, j - 1) == "*" and Map.get(acc, {0, j - 2}, false) do
          Map.put(acc, {0, j}, true)
        else
          acc
        end
      end)

    dp =
      Enum.reduce(1..m, dp, fn i, acc_i ->
        Enum.reduce(1..n, acc_i, fn j, acc_j ->
          s_char = Enum.at(s_chars, i - 1)
          p_char = Enum.at(p_chars, j - 1)

          cond do
            p_char == "*" ->
              p_prev = Enum.at(p_chars, j - 2)
              zero_occ = Map.get(acc_j, {i, j - 2}, false)

              one_or_more =
                (s_char == p_prev or p_prev == ".") and
                  Map.get(acc_j, {i - 1, j}, false)

              Map.put(acc_j, {i, j}, zero_occ or one_or_more)

            p_char == "." or p_char == s_char ->
              Map.put(acc_j, {i, j}, Map.get(acc_j, {i - 1, j - 1}, false))

            true ->
              acc_j
          end
        end)
      end)

    Map.get(dp, {m, n}, false)
  end
end

defmodule RegexProofTest do
  # Proof suite for the article "Solving LeetCode's Regular Expression
  # Matching in Elixir" (Elixir 1.20.1 / OTP 29). Same convention.
  use ExUnit.Case, async: true

  # Solution 2 (memoized), VERBATIM — `_s`/`_p` used inside the guard.
  # Runtime-compiled: those names emit "underscored variable used" warnings.
  @verbatim_memo_src """
  defmodule VerbatimRegexMemo do
    def is_match(s, p) do
      {result, _memo} = match(String.graphemes(s), 0, String.graphemes(p), 0, %{})
      result
    end
    defp char_at(list, i), do: Enum.at(list, i)
    defp match(s, i, p, j, memo) do
      key = {i, j}
      case Map.get(memo, key) do
        nil ->
          {result, memo2} = compute_match(s, i, p, j, memo)
          {result, Map.put(memo2, key, result)}
        cached ->
          {cached, memo}
      end
    end
    defp compute_match(_s, i, _p, j, memo) when j >= length(_p), do: {i >= length(_s), memo}
    defp compute_match(s, i, p, j, memo) do
      p_char = char_at(p, j)
      next_p = char_at(p, j + 1)
      if next_p == "*" do
        {zero_result, memo1} = match(s, i, p, j + 2, memo)
        if zero_result do
          {true, memo1}
        else
          s_char = char_at(s, i)
          if s_char != nil and (s_char == p_char or p_char == ".") do
            match(s, i + 1, p, j, memo1)
          else
            {false, memo1}
          end
        end
      else
        s_char = char_at(s, i)
        if s_char != nil and (s_char == p_char or p_char == ".") do
          match(s, i + 1, p, j + 1, memo)
        else
          {false, memo}
        end
      end
    end
  end
  """

  # Solution 3 (bottom-up DP), VERBATIM (renamed module only).
  # Runtime-compiled: the nested for-into-map init crashes at runtime.
  @verbatim_dp_src """
  defmodule VerbatimRegexDP do
    def is_match(s, p) do
      s_chars = String.graphemes(s)
      p_chars = String.graphemes(p)
      m = length(s_chars)
      n = length(p_chars)
      dp =
        for i <- 0..m, into: %{} do
          for j <- 0..n, into: %{} do
            {{i, j}, false}
          end
        end
      dp = Map.put(dp, {0, 0}, true)
      dp =
        Enum.reduce(1..n, dp, fn j, acc ->
          if Enum.at(p_chars, j - 1) == "*" and Map.get(acc, {0, j - 2}, false) do
            Map.put(acc, {0, j}, true)
          else
            acc
          end
        end)
      dp =
        Enum.reduce(1..m, dp, fn i, acc_i ->
          Enum.reduce(1..n, acc_i, fn j, acc_j ->
            s_char = Enum.at(s_chars, i - 1)
            p_char = Enum.at(p_chars, j - 1)
            cond do
              p_char == "*" ->
                p_prev = Enum.at(p_chars, j - 2)
                zero_occ = Map.get(acc_j, {i, j - 2}, false)
                one_or_more =
                  (s_char == p_prev or p_prev == ".") and
                    Map.get(acc_j, {i - 1, j}, false)
                Map.put(acc_j, {i, j}, zero_occ or one_or_more)
              p_char == "." or p_char == s_char ->
                Map.put(acc_j, {i, j}, Map.get(acc_j, {i - 1, j - 1}, false))
              true ->
                acc_j
            end
          end)
        end)
      Map.get(dp, {m, n}, false)
    end
  end
  """

  @cases [
    {"aa", "a", false},
    {"aa", "a*", true},
    {"ab", ".*", true},
    {"aab", "c*a*b", true},
    {"", "a*", true},
    {"a", "", false},
    {"ab", ".*c", false},
    {"mississippi", "mis*is*p*.", false},
    {"aaa", "a*a", true},
    {"ab", ".*..", true}
  ]

  describe "Regex: correct versions" do
    # 5W1H | Who: reader. What: naive recursion passes the four LeetCode examples plus six extras (empty pattern/string, star edge, classic mississippi). When/Where: article Solution 1. How: equality asserts. Why: baseline correctness.
    # STAR | Situation: ten (s, p) cases. Task: lock outputs. Action: is_match each. Result: false, true, true, true, true, false, false, false, true, true.
    # FLOW (is_match("aab", "c*a*b"))
    # [a,a,b] vs [c,*,a,*,b]: c* zero → [a,a,b] vs [a,*,b]
    # a* zero → [a,a,b] vs [b]: a vs b ✗ → backtrack
    # a* one: [a,b] vs [a,*,b] → zero: [a,b] vs [b] ✗ → one: [b] vs [a,*,b]
    #   → zero: [b] vs [b] ✓ → true
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | is_match("aab", "c*a*b")   (RegexNaive)
    #        match([a,a,b], [c,*,a,*,b]) → c* zero → match([a,a,b], [a,*,b])
    #          a* zero → match([a,a,b], [b]) → a vs b ✗ → backtrack
    #          a* one  → match([a,b], [a,*,b]) → zero → match([a,b],[b]) ✗
    #                                              → one → match([b],[a,*,b]) → zero → match([b],[b]) ✓
    #        ▼ true
    test "naive recursion passes examples and extras" do
      for {s, p, expected} <- @cases do
        assert RegexNaive.is_match(s, p) == expected
      end
    end

    # 5W1H | Who: reader. What: verbatim memoized version agrees with naive on all ten cases (runtime-compiled: its `_s`/`_p` guard names warn at compile time). When/Where: article Solution 2. How: equality asserts via apply. Why: memoization preserves semantics.
    # STAR | Situation: same ten cases. Task: lock agreement. Action: compile verbatim source (stderr captured), is_match each. Result: identical outputs.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "verbatim memoized version agrees with naive" do
      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        send(self(), {:mods, Code.compile_string(@verbatim_memo_src)})
      end)

      [{mod, _}] =
        receive do
          {:mods, mods} -> mods
        end

      for {s, p, expected} <- @cases do
        assert apply(mod, :is_match, [s, p]) == expected
      end
    end

    # 5W1H | Who: reader. What: bottom-up DP with the ONE-LINE init fix (flat generators) agrees with naive on all non-empty cases. When/Where: article Solution 3 corrected. How: equality asserts. Why: proves the recurrence; only the init was broken.
    # STAR | Situation: eight cases with m,n >= 1. Task: lock agreement. Action: is_match each. Result: identical outputs.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | is_match("a", "a*")   (RegexDPFixed)
    #        m=1 n=2 → dp is 2×3, all false, then {0,0}=true
    #        j-loop: j=1 p[0]="a" not "*" → skip
    #                j=2 p[1]="*" and dp[{0,0}]=true → dp[{0,2}]=true
    #        i=1 j=1: s="a" p="a"  → dp[{1,1}] = dp[{0,0}] = true
    #        i=1 j=2: p="*" p_prev="a"; zero=dp[{1,0}]=false
    #                 one = ("a"=="a") and dp[{0,2}]=true → dp[{1,2}]=true
    #        ▼ dp[{1,2}] = true
    test "fixed bottom-up agrees on non-empty inputs" do
      for {s, p, expected} <- Enum.reject(@cases, fn {s, p, _} -> s == "" or p == "" end) do
        assert RegexDPFixed.is_match(s, p) == expected
      end
    end

    # 5W1H | Who: prover. What: fixed bottom-up handles empty string/pattern (ranges 1..0 warn on Elixir 1.20, captured). When/Where: article base cases dp[0][j]. How: asserts with stderr captured. Why: empty-input contract of the table.
    # STAR | Situation: ("", "a*"), ("a", ""). Task: lock outputs. Action: run with stderr captured. Result: true, false.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "fixed bottom-up handles empty inputs" do
      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        send(self(), {:r1, RegexDPFixed.is_match("", "a*")})
        send(self(), {:r2, RegexDPFixed.is_match("a", "")})
      end)

      receive do
        {:r1, r1} -> assert r1 == true
      end

      receive do
        {:r2, r2} -> assert r2 == false
      end
    end
  end

  describe "Regex: broken table init (article error documented)" do
    @describetag :documented_error
    # 5W1H | Who: prover + future AI reader. What: CRITICAL — verbatim bottom-up DP crashes on ANY input: nested `for i <- 0..m, into: %{} do <map>` tries to collect maps as entries (`:maps.from_list` gets maps, not tuples) → ArgumentError before any matching. When/Where: article Solution 3 table init. How: runtime-compile verbatim source, assert_raise on apply. Why: for-into shape must yield entries, not collections. Fix: `for i <- 0..m, j <- 0..n, into: %{}, do: {{i, j}, false}`.
    # STAR | Situation: verbatim DP on ("aa", "a"). Task: prove the crash. Action: compile source, is_match. Result: ArgumentError.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | @verbatim_dp_src
    #        for i <- 0..m, into: %{} do for j <- 0..n, into: %{} do {{i,j}, false} end end
    #        the OUTER body returns a MAP; Enum.into(%{}, [map, map, …]) needs {k,v} tuples
    #        ✗ ArgumentError   (article error)
    #        FIX: for i <- 0..m, j <- 0..n, into: %{}, do: {{i, j}, false}
    @tag :documented_error
    test "verbatim bottom-up crashes on table init" do
      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        send(self(), {:mods, Code.compile_string(@verbatim_dp_src)})
      end)

      [{mod, _}] =
        receive do
          {:mods, mods} -> mods
        end

      assert_raise ArgumentError, fn ->
        apply(mod, :is_match, ["aa", "a"])
      end
    end
  end
end

# Container With Most Water article code, inlined here (this repo never uses
# /lib). NOTE: the article names every version `Solution`; renamed here.
# WaterRwFixed differs from the article by ONE pattern (`{_, _, max_area}`
# instead of `{_, max_area}`) — see the crash test below.
defmodule WaterBrute do
  @spec max_area(height :: [integer]) :: integer
  def max_area(height) do
    n = length(height)
    heights = List.to_tuple(height)

    0..(n - 2)
    |> Enum.reduce(0, fn i, best ->
      (i + 1)..(n - 1)
      |> Enum.reduce(best, fn j, acc ->
        h = min(elem(heights, i), elem(heights, j))
        max(acc, h * (j - i))
      end)
    end)
  end
end

defmodule WaterRec do
  @spec max_area(height :: [integer]) :: integer
  def max_area(height) do
    height |> List.to_tuple() |> solve(0, length(height) - 1, 0)
  end

  defp solve(_height, l, r, ans) when l >= r, do: ans

  defp solve(height, l, r, ans) do
    lh = elem(height, l)
    rh = elem(height, r)
    new_ans = max(min(lh, rh) * (r - l), ans)

    if lh < rh do
      solve(height, l + 1, r, new_ans)
    else
      solve(height, l, r - 1, new_ans)
    end
  end
end

defmodule WaterRwVerbatim do
  @spec max_area(height :: [integer]) :: integer
  def max_area(height) do
    n = length(height)
    heights = List.to_tuple(height)

    {_, max_area} =
      Enum.reduce_while(0..n, {0, n - 1, 0}, fn _, {left, right, best} ->
        if left >= right do
          {:halt, {left, right, best}}
        else
          lh = elem(heights, left)
          rh = elem(heights, right)
          new_best = max(best, min(lh, rh) * (right - left))

          if lh < rh do
            {:cont, {left + 1, right, new_best}}
          else
            {:cont, {left, right - 1, new_best}}
          end
        end
      end)

    max_area
  end
end

defmodule WaterRwFixed do
  @spec max_area(height :: [integer]) :: integer
  def max_area(height) do
    n = length(height)
    heights = List.to_tuple(height)

    {_, _, max_area} =
      Enum.reduce_while(0..n, {0, n - 1, 0}, fn _, {left, right, best} ->
        if left >= right do
          {:halt, {left, right, best}}
        else
          lh = elem(heights, left)
          rh = elem(heights, right)
          new_best = max(best, min(lh, rh) * (right - left))

          if lh < rh do
            {:cont, {left + 1, right, new_best}}
          else
            {:cont, {left, right - 1, new_best}}
          end
        end
      end)

    max_area
  end
end

defmodule WaterProofTest do
  # Proof suite for the article "Solving LeetCode's Container With Most Water
  # in Elixir" (Elixir 1.20.1 / OTP 29). Same convention.
  use ExUnit.Case, async: true

  @cases [
    {[1, 8, 6, 2, 5, 4, 8, 3, 7], 49},
    {[1, 1], 1},
    {[4, 3, 2, 1, 4], 16},
    {[0, 0], 0},
    {[5, 5, 5, 5], 15},
    {[1, 2, 3, 4, 5], 6},
    {[5, 4, 3, 2, 1], 6},
    {[1, 0, 0, 0, 1], 4},
    {[2, 3, 10, 5, 7, 8, 9], 36},
    {[0, 1, 0], 0}
  ]

  describe "Water: correct versions" do
    # 5W1H | Who: reader. What: brute force passes the three LeetCode examples plus zeros, ties, monotonic and gapped inputs. When/Where: article Solution 1. How: equality asserts. Why: baseline correctness (tuple access is genuinely O(1) here).
    # STAR | Situation: ten height arrays. Task: lock outputs. Action: max_area each. Result: 49, 1, 16, 0, 15, 6, 6, 4, 36, 0.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "brute force passes examples and edges" do
      for {h, expected} <- @cases do
        assert WaterBrute.max_area(h) == expected
      end
    end

    # 5W1H | Who: reader. What: recursive two-pointer matches brute force on every case. When/Where: article Solution 2 (recursion). How: equality asserts. Why: optimal O(n) correctness.
    # STAR | Situation: same ten arrays. Task: lock agreement. Action: max_area each. Result: identical outputs.
    # FLOW (max_area([4,3,2,1,4]))
    # (l=0,r=4): min(4,4)*4 = 16 → tie → r=3
    # (l=0,r=3): min(4,1)*3 = 3 → r=2
    # (l=0,r=2): min(4,2)*2 = 4 → r=1
    # (l=0,r=1): min(4,3)*1 = 3 → r=0 → halt
    #          ▼ 16
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | max_area([1,8,6,2,5,4,8,3,7])   (WaterRec / WaterBrute → 49)
    #        | l | r | h[l] | h[r] | area = min·(r-l) | best | move |
    #        | 0 | 8 | 1    | 7    | 8                | 8    | l++  |
    #        | 1 | 8 | 8    | 7    | 49               | 49   | r--  |  ← 7·7
    #        | 1 | 7 | 8    | 3    | 18               | 49   | r--  |
    #        | 1 | 6 | 8    | 8    | 40               | 49   | r--  |
    #        | 1 | 5 | 8    | 4    | 16               | 49   | r--  |
    #        | 1 | 4 | 8    | 5    | 15               | 49   | r--  |
    #        | 1 | 3 | 8    | 2    | 4                | 49   | r--  |
    #        | 1 | 2 | 8    | 6    | 6                | 49   | r--  |
    #        | 1 | 1 | —    | —    | l >= r           | 49   | halt |
    #        ▼ 49
    test "recursive two-pointer matches brute force" do
      for {h, expected} <- @cases do
        assert WaterRec.max_area(h) == expected
      end
    end

    # 5W1H | Who: reader. What: reduce_while with the ONE-PATTERN fix ({_, _, max_area}) matches brute force everywhere. When/Where: article Solution 2 alternative, corrected. How: equality asserts. Why: proves only the destructure was broken.
    # STAR | Situation: same ten arrays. Task: lock agreement. Action: max_area each. Result: identical outputs.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "fixed reduce_while matches brute force" do
      for {h, expected} <- @cases do
        assert WaterRwFixed.max_area(h) == expected
      end
    end
  end

  describe "Water: broken destructure (article error documented)" do
    @describetag :documented_error
    # 5W1H | Who: prover + future AI reader. What: CRITICAL — verbatim reduce_while destructures `{_, max_area}` but the accumulator is always the 3-tuple {left, right, best}, so EVERY input raises MatchError. When/Where: article Solution 2 alternative. How: assert_raise on three inputs. Why: acc shape must match the pattern.
    # STAR | Situation: verbatim version on [1,1], the big example, [4,3,2,1,4]. Task: prove the crash. Action: max_area each. Result: MatchError thrice.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | @verbatim reduce_while   (WaterRwVerbatim)
    #        reduce_while(0..n, {0, n-1, 0}, fn _, {left,right,best} -> … {:halt, {left,right,best}} end)
    #        accumulator is ALWAYS a 3-tuple
    #        the final destructure is {_, max_area}  — a 2-tuple pattern
    #        ✗ MatchError on EVERY input   (article error)
    #        FIX: {_, _, max_area} = …
    @tag :documented_error
    test "verbatim reduce_while raises MatchError on any input" do
      for h <- [[1, 1], [1, 8, 6, 2, 5, 4, 8, 3, 7], [4, 3, 2, 1, 4]] do
        assert_raise MatchError, fn ->
          WaterRwVerbatim.max_area(h)
        end
      end
    end
  end
end

# Integer to Roman article code, inlined here (this repo never uses /lib).
# NOTE: the article names every version `Solution`; renamed here so both can
# coexist in one file.
defmodule RomanGreedy do
  @spec int_to_roman(num :: integer) :: String.t()
  def int_to_roman(num) do
    mappings = [
      {1000, "M"}, {900, "CM"}, {500, "D"}, {400, "CD"},
      {100, "C"}, {90, "XC"}, {50, "L"}, {40, "XL"},
      {10, "X"}, {9, "IX"}, {5, "V"}, {4, "IV"}, {1, "I"}
    ]

    build(num, mappings, [])
  end

  defp build(0, _mappings, acc), do: acc |> Enum.reverse() |> Enum.join()

  defp build(num, [{value, symbol} | rest] = mappings, acc) do
    if value <= num do
      build(num - value, mappings, [symbol | acc])
    else
      build(num, rest, acc)
    end
  end
end

defmodule RomanTable do
  @spec int_to_roman(num :: integer) :: String.t()
  def int_to_roman(num) do
    thousands = ["", "M", "MM", "MMM"]
    hundreds = ["", "C", "CC", "CCC", "CD", "D", "DC", "DCC", "DCCC", "CM"]
    tens = ["", "X", "XX", "XXX", "XL", "L", "LX", "LXX", "LXXX", "XC"]
    ones = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"]

    Enum.at(thousands, div(num, 1000)) <>
      Enum.at(hundreds, div(rem(num, 1000), 100)) <>
      Enum.at(tens, div(rem(num, 100), 10)) <>
      Enum.at(ones, rem(num, 10))
  end
end

defmodule RomanProofTest do
  # Proof suite for the article "Solving LeetCode's Integer to Roman in
  # Elixir" (Elixir 1.20.1 / OTP 29). Same convention.
  use ExUnit.Case, async: true

  @cases [
    {3, "III"},
    {4, "IV"},
    {9, "IX"},
    {58, "LVIII"},
    {1994, "MCMXCIV"},
    {1, "I"},
    {3999, "MMMCMXCIX"},
    {40, "XL"},
    {90, "XC"},
    {400, "CD"},
    {900, "CM"},
    {49, "XLIX"},
    {99, "XCIX"},
    {444, "CDXLIV"},
    {999, "CMXCIX"},
    {3888, "MMMDCCCLXXXVIII"}
  ]

  describe "Roman: correct versions" do
    # 5W1H | Who: reader. What: greedy version passes the five LeetCode examples plus subtractive forms, repeat-heavy numerals and both range ends. When/Where: article Solution 1. How: equality asserts. Why: greedy-with-subtractives correctness.
    # STAR | Situation: 16 inputs incl. 3999 and 3888. Task: lock outputs. Action: int_to_roman each. Result: all match (note: 3999 is MMMCMXCIX, three Ms).
    # FLOW (int_to_roman(1994))
    # 1994 → M → 994 → CM → 94 → XC → 4 → IV → 0
    #          ▼ "M" <> "CM" <> "XC" <> "IV" = "MCMXCIV"
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | int_to_roman(1994)   (RomanGreedy)
    #        | num  | mapping matched | acc (pre-reverse)      |
    #        | 1994 | 1000 → "M"      | ["M"]                  |
    #        | 994  | 900  → "CM"     | ["CM","M"]             |
    #        | 94   | 90   → "XC"     | ["XC","CM","M"]        |
    #        | 4    | 4    → "IV"     | ["IV","XC","CM","M"]   |
    #        | 0    | base case       | Enum.reverse |> join   |
    #        ▼ "MCMXCIV"
    #
    # FLOW | int_to_roman(3999)   (the MMM trap)
    #        1000 M → 2999 | 1000 M → 1999 | 1000 M → 999
    #        900 CM → 99 | 90 XC → 9 | 9 IX → 0
    #        ▼ "MMMCMXCIX"   ← three Ms, never four
    test "greedy passes examples and edges" do
      for {n, expected} <- @cases do
        assert RomanGreedy.int_to_roman(n) == expected
      end
    end

    # 5W1H | Who: reader. What: lookup-table version matches greedy on every case above. When/Where: article Solution 2. How: equality asserts. Why: place-value decomposition correctness.
    # STAR | Situation: same 16 inputs. Task: lock agreement. Action: int_to_roman each. Result: identical outputs.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | int_to_roman(1994)   (RomanTable — no loop, pure indexing)
    #        div(1994,1000) = 1               → thousands[1] = "M"
    #        div(rem(1994,1000)=994, 100) = 9 → hundreds[9]  = "CM"
    #        div(rem(1994,100)=94, 10) = 9    → tens[9]      = "XC"
    #        rem(1994,10) = 4                 → ones[4]      = "IV"
    #        ▼ "MCMXCIV"
    test "lookup table matches greedy" do
      for {n, expected} <- @cases do
        assert RomanTable.int_to_roman(n) == expected
      end
    end

    # 5W1H | Who: prover + future AI reader. What: EXHAUSTIVE — both versions agree on the ENTIRE valid domain 1..3999 (zero mismatches), so no input in range can distinguish them. When/Where: article constraints. How: full-sweep assert. Why: strongest possible equivalence proof for a bounded domain.
    # STAR | Situation: every n in 1..3999. Task: prove agreement. Action: compare both versions. Result: 0 mismatches.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # PROPERTY | forall n in 1..3999: greedy(n) == table(n) — exhaustive sweep, zero mismatches.
    test "both versions agree on the whole domain" do
      mismatches = Enum.reject(1..3999, fn n -> RomanGreedy.int_to_roman(n) == RomanTable.int_to_roman(n) end)

      assert mismatches == []
    end

    # 5W1H | Who: prover. What: article's side claim — longest numeral in range is 15 chars (3888 = MMMDCCCLXXXVIII). When/Where: article complexity section. How: length assert. Why: pins the space-bound illustration.
    # STAR | Situation: int_to_roman(3888). Task: prove length 15. Action: measure. Result: 15.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "longest numeral is fifteen chars" do
      assert RomanGreedy.int_to_roman(3888) |> String.length() == 15
    end
  end
end

# Roman to Integer article code, inlined here (this repo never uses /lib).
# NOTE: the article names every version `Solution`; renamed here so all three
# can coexist in one file.
defmodule RomToIntReduce do
  @roman_map %{
    "I" => 1, "V" => 5, "X" => 10, "L" => 50,
    "C" => 100, "D" => 500, "M" => 1000
  }

  @spec roman_to_int(s :: String.t()) :: integer
  def roman_to_int(s) do
    {total, _} =
      Enum.reduce(String.graphemes(s), {0, 0}, fn char, {sum, prev_value} ->
        current_value = Map.get(@roman_map, char)

        if current_value > prev_value do
          {sum + current_value - 2 * prev_value, current_value}
        else
          {sum + current_value, current_value}
        end
      end)

    total
  end
end

defmodule RomToIntPat do
  @spec roman_to_int(s :: String.t()) :: integer
  def roman_to_int(s) do
    s |> String.graphemes() |> parse(0)
  end

  defp parse([], acc), do: acc
  defp parse(["I", "V" | rest], acc), do: parse(rest, acc + 4)
  defp parse(["I", "X" | rest], acc), do: parse(rest, acc + 9)
  defp parse(["X", "L" | rest], acc), do: parse(rest, acc + 40)
  defp parse(["X", "C" | rest], acc), do: parse(rest, acc + 90)
  defp parse(["C", "D" | rest], acc), do: parse(rest, acc + 400)
  defp parse(["C", "M" | rest], acc), do: parse(rest, acc + 900)
  defp parse(["I" | rest], acc), do: parse(rest, acc + 1)
  defp parse(["V" | rest], acc), do: parse(rest, acc + 5)
  defp parse(["X" | rest], acc), do: parse(rest, acc + 10)
  defp parse(["L" | rest], acc), do: parse(rest, acc + 50)
  defp parse(["C" | rest], acc), do: parse(rest, acc + 100)
  defp parse(["D" | rest], acc), do: parse(rest, acc + 500)
  defp parse(["M" | rest], acc), do: parse(rest, acc + 1000)
end

defmodule RomToIntRtl do
  @roman_map %{
    "I" => 1, "V" => 5, "X" => 10, "L" => 50,
    "C" => 100, "D" => 500, "M" => 1000
  }

  @spec roman_to_int(s :: String.t()) :: integer
  def roman_to_int(s) do
    s
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.reduce({0, 0}, fn char, {sum, prev} ->
      current = Map.get(@roman_map, char)

      if current >= prev do
        {sum + current, current}
      else
        {sum - current, current}
      end
    end)
    |> elem(0)
  end
end

defmodule RomToIntProofTest do
  # Proof suite for the article "Solving LeetCode's Roman to Integer in
  # Elixir" (Elixir 1.20.1 / OTP 29). Same convention.
  use ExUnit.Case, async: true

  @cases [
    {"III", 3},
    {"LVIII", 58},
    {"MCMXCIV", 1994},
    {"IV", 4},
    {"IX", 9},
    {"XL", 40},
    {"XC", 90},
    {"CD", 400},
    {"CM", 900},
    {"MMMCMXCIX", 3999},
    {"I", 1},
    {"", 0}
  ]

  describe "Roman to Integer: correct versions" do
    # 5W1H | Who: reader. What: all three versions pass the LeetCode examples plus every subtractive pair, the max numeral and empty string. When/Where: article examples + edges. How: equality asserts per version. Why: baseline parsing contract.
    # STAR | Situation: twelve inputs. Task: lock outputs. Action: roman_to_int each on all three. Result: identical correct values everywhere.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | roman_to_int("MCMXCIV")   (RomToIntReduce — left-to-right, subtract 2×prev)
    #        | char | cur  | prev | sum                              |
    #        | M    | 1000 | 0    | 1000                             |
    #        | C    | 100  | 1000 | 1000 + 100 = 1100                |
    #        | M    | 1000 | 100  | 1100 + 1000 - 200 = 1900         |  ← 2×100 subtracted
    #        | X    | 10   | 1000 | 1910                             |
    #        | C    | 100  | 10   | 1910 + 100 - 20 = 1990           |
    #        | I    | 1    | 100  | 1991                             |
    #        | V    | 5    | 1    | 1991 + 5 - 2 = 1994              |
    #        ▼ 1994
    #
    # FLOW | roman_to_int("MCMXCIV")   (RomToIntPat — clause order is the algorithm)
    #        ["C","M"] matches BEFORE ["C"] and ["M"] → 900
    #        ["X","C"] matches BEFORE ["X"] and ["C"] → 90
    #        ["I","V"] matches BEFORE ["I"] and ["V"] → 4
    #        remaining "M" → 1000
    #        ▼ 900 + 90 + 4 + 1000 = 1994
    #
    # FLOW | roman_to_int("MCMXCIV")   (RomToIntRtl — reverse, then current >= prev ? + : -)
    #        reversed = V,I,C,X,M,C,M
    #        | char | cur  | prev | sum              | rule      |
    #        | V    | 5    | 0    | 5                | +         |
    #        | I    | 1    | 5    | 4                | -         |  ← 1 < 5
    #        | C    | 100  | 1    | 104              | +         |
    #        | X    | 10   | 100  | 94               | -         |
    #        | M    | 1000 | 10   | 1094             | +         |
    #        | C    | 100  | 1000 | 994              | -         |
    #        | M    | 1000 | 100  | 1994             | +         |
    #        ▼ 1994
    test "all versions pass examples and edges" do
      for {s, expected} <- @cases do
        assert RomToIntReduce.roman_to_int(s) == expected
        assert RomToIntPat.roman_to_int(s) == expected
        assert RomToIntRtl.roman_to_int(s) == expected
      end
    end

    # 5W1H | Who: prover + future AI reader. What: CROSS-ARTICLE — every int_to_roman output from the previous article round-trips through all three parsers over the ENTIRE domain 1..3999 (zero failures), proving both directions at once. When/Where: Integer-to-Roman generator (already proven) as oracle. How: full-sweep asserts. Why: strongest equivalence across two articles.
    # STAR | Situation: every n in 1..3999. Task: prove round-trip. Action: parse int_to_roman(n) with all three. Result: n every time, 0 failures.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # PROPERTY | forall n in 1..3999: parse(int_to_roman(n)) == n for all three parsers — exhaustive round-trip.
    test "full domain round-trips through all parsers" do
      failures =
        Enum.reject(1..3999, fn n ->
          s = RomanGreedy.int_to_roman(n)

          RomToIntReduce.roman_to_int(s) == n and
            RomToIntPat.roman_to_int(s) == n and
            RomToIntRtl.roman_to_int(s) == n
        end)

      assert failures == []
    end
  end
end

# Longest Common Prefix article code, inlined here (this repo never uses
# /lib). NOTE: the article names every version `Solution`; renamed here so
# all three can coexist in one file.
defmodule LcpHoriz do
  @spec longest_common_prefix(strs :: [String.t()]) :: String.t()
  def longest_common_prefix([]), do: ""

  def longest_common_prefix([first | rest]) do
    Enum.reduce_while(rest, first, fn str, prefix ->
      new_prefix = shrink_prefix(prefix, str)
      if new_prefix == "", do: {:halt, ""}, else: {:cont, new_prefix}
    end)
  end

  defp shrink_prefix(prefix, str) do
    if String.starts_with?(str, prefix) do
      prefix
    else
      shrink_prefix(String.slice(prefix, 0..-2//1), str)
    end
  end
end

defmodule LcpVert do
  @spec longest_common_prefix(strs :: [String.t()]) :: String.t()
  def longest_common_prefix([]), do: ""

  def longest_common_prefix(strs) do
    first = hd(strs)
    rest = tl(strs)
    chars = String.graphemes(first)
    n = length(chars)

    Enum.reduce_while(0..(n - 1), first, fn i, _acc ->
      char = Enum.at(chars, i)

      if Enum.all?(rest, fn s -> String.at(s, i) == char end) do
        {:cont, first}
      else
        {:halt, String.slice(first, 0, i)}
      end
    end)
  end
end

defmodule LcpSort do
  @spec longest_common_prefix(strs :: [String.t()]) :: String.t()
  def longest_common_prefix([]), do: ""

  def longest_common_prefix(strs) do
    sorted = Enum.sort(strs)
    first = hd(sorted)
    last = List.last(sorted)

    Enum.zip(String.graphemes(first), String.graphemes(last))
    |> Enum.take_while(fn {a, b} -> a == b end)
    |> Enum.map(fn {a, _} -> a end)
    |> Enum.join()
  end
end

defmodule LcpProofTest do
  # Proof suite for the article "Solving LeetCode's Longest Common Prefix in
  # Elixir" (Elixir 1.20.1 / OTP 29). Same convention.
  use ExUnit.Case, async: true

  @cases [
    {["flower", "flow", "flight"], "fl"},
    {["dog", "racecar", "car"], ""},
    {["abc", ""], ""},
    {["a"], "a"},
    {["abc"], "abc"},
    {["abab", "aba", "abc"], "ab"},
    {["prefix", "pre", "prepare"], "pre"},
    {["interspecies", "interstellar", "interstate"], "inters"},
    {["abc", "abc", "abc"], "abc"},
    {[], ""}
  ]

  describe "LCP: correct versions" do
    # 5W1H | Who: reader. What: all three scans pass the LeetCode examples plus singletons, trailing empties, full-overlap and no-overlap batteries. When/Where: article examples + edges. How: equality asserts per version. Why: baseline scanning contract.
    # STAR | Situation: ten inputs. Task: lock outputs. Action: longest_common_prefix each on all three. Result: identical correct values everywhere.
    # FLOW (["flower","flow","flight"], prefix starts "flower")
    # vs "flow": "flower"→"flowe"→"flow" ✓ → vs "flight": "flow"→"flo"→"fl" ✓
    #          ▼ "fl"
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | longest_common_prefix(["flower","flow","flight"])   (LcpHoriz)
    #        prefix "flower" ; "flow"   starts_with? → no
    #          slice(0..-2) → "flowe" → no → "flow" → yes        → prefix = "flow"
    #        prefix "flow"   ; "flight" starts_with? → no
    #          "flo" → no → "fl" → yes                            → prefix = "fl"
    #        ▼ "fl"
    #
    # FLOW | longest_common_prefix(["flower","flow","flight"])   (LcpVert)
    #        first = "flower", rest = ["flow","flight"], chars = [f,l,o,w,e,r]
    #        | i | char | rest[0][i] | rest[1][i] | action            |
    #        | 0 | f    | f          | f          | cont              |
    #        | 1 | l    | l          | l          | cont              |
    #        | 2 | o    | o          | i          | halt → slice(0,2) |
    #        ▼ "fl"
    #
    # FLOW | longest_common_prefix(["flower","flow","flight"])   (LcpSort)
    #        sorted = ["flight","flow","flower"] ; first = "flight", last = "flower"
    #        zip graphemes → [f,f],[l,l],[i,o],[g,w],[h,e],[t,r]
    #        take_while equal → [f,f],[l,l]
    #        ▼ "fl"
    test "all versions pass examples and battery" do
      for {strs, expected} <- @cases do
        assert LcpHoriz.longest_common_prefix(strs) == expected
        assert LcpVert.longest_common_prefix(strs) == expected
        assert LcpSort.longest_common_prefix(strs) == expected
      end
    end

    # 5W1H | Who: prover. What: empty FIRST string is correct ("") on all three; vertical scanning builds 0..-1 (decreasing range, warns in plain scripts — silent under ExUnit's logger) before halting at column 0. When/Where: article never covers empty-first input. How: direct asserts for horiz/sort; stderr-captured asserts for vertical. Why: range edge + suite-output hygiene.
    # STAR | Situation: [""], ["", "abc"]. Task: prove "" everywhere. Action: run all three (vertical captured). Result: "" always.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | longest_common_prefix([""])
    #        LcpHoriz → prefix "" ; shrink "" → "" → returns ""
    #        LcpVert  → chars = [], n = 0 → 0..-1 (decreasing range) → reduce_while returns first
    #        LcpSort  → sorted [""] ; zip [] → take_while [] → ""
    #        ▼ ""   (LcpVert's 0..-1 warns — test captures stderr)
    test "empty first string returns empty" do
      for strs <- [[""], ["", "abc"]] do
        assert LcpHoriz.longest_common_prefix(strs) == ""
        assert LcpSort.longest_common_prefix(strs) == ""

        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          send(self(), {:res, LcpVert.longest_common_prefix(strs)})
        end)

        receive do
          {:res, result} -> assert result == ""
        end
      end
    end
  end
end

# 3Sum article code, inlined here (this repo never uses /lib).
# NOTE: the article names every version `Solution`; renamed here so all three
# can coexist in one file.
defmodule Sum3Brute do
  @spec three_sum(nums :: [integer]) :: [[integer]]
  def three_sum(nums) do
    n = length(nums)
    nums = List.to_tuple(nums)

    0..(n - 3)
    |> Enum.reduce(MapSet.new(), fn i, acc ->
      (i + 1)..(n - 2)
      |> Enum.reduce(acc, fn j, acc2 ->
        (j + 1)..(n - 1)
        |> Enum.reduce(acc2, fn k, acc3 ->
          if elem(nums, i) + elem(nums, j) + elem(nums, k) == 0 do
            triplet = [elem(nums, i), elem(nums, j), elem(nums, k)] |> Enum.sort()
            MapSet.put(acc3, triplet)
          else
            acc3
          end
        end)
      end)
    end)
    |> MapSet.to_list()
  end
end

defmodule Sum3Rec do
  @spec three_sum(nums :: [integer]) :: [[integer]]
  def three_sum(nums) do
    nums |> Enum.sort() |> List.to_tuple() |> find_triplets(0, [])
  end

  defp find_triplets(nums, i, acc) when i >= tuple_size(nums) - 2, do: Enum.reverse(acc)

  defp find_triplets(nums, i, acc) do
    x = elem(nums, i)

    if x > 0 do
      Enum.reverse(acc)
    else
      if i > 0 and elem(nums, i - 1) == x do
        find_triplets(nums, i + 1, acc)
      else
        acc = two_pointers(nums, i, i + 1, tuple_size(nums) - 1, x, acc)
        find_triplets(nums, i + 1, acc)
      end
    end
  end

  defp two_pointers(_nums, _i, left, right, _x, acc) when left >= right, do: acc

  defp two_pointers(nums, i, left, right, x, acc) do
    y = elem(nums, left)
    z = elem(nums, right)
    sum = x + y + z

    cond do
      sum == 0 ->
        acc = [[x, y, z] | acc]
        new_left = skip_duplicates_left(nums, left, right)
        new_right = skip_duplicates_right(nums, new_left, right)
        two_pointers(nums, i, new_left, new_right, x, acc)

      sum < 0 ->
        two_pointers(nums, i, left + 1, right, x, acc)

      true ->
        two_pointers(nums, i, left, right - 1, x, acc)
    end
  end

  defp skip_duplicates_left(nums, left, right) do
    if left + 1 < right and elem(nums, left) == elem(nums, left + 1) do
      skip_duplicates_left(nums, left + 1, right)
    else
      left + 1
    end
  end

  defp skip_duplicates_right(nums, left, right) do
    if right - 1 > left and elem(nums, right) == elem(nums, right - 1) do
      skip_duplicates_right(nums, left, right - 1)
    else
      right - 1
    end
  end
end

defmodule Sum3Rw do
  @spec three_sum(nums :: [integer]) :: [[integer]]
  def three_sum(nums) do
    sorted = Enum.sort(nums)
    tuple = List.to_tuple(sorted)
    n = tuple_size(tuple)

    Enum.reduce_while(0..(n - 3), [], fn i, acc ->
      x = elem(tuple, i)

      if x > 0 do
        {:halt, acc}
      else
        if i > 0 and elem(tuple, i - 1) == x do
          {:cont, acc}
        else
          {:cont, two_sum(tuple, i, x, acc)}
        end
      end
    end)
    |> Enum.reverse()
  end

  defp two_sum(tuple, i, x, acc) do
    do_two_sum(tuple, i, i + 1, tuple_size(tuple) - 1, x, acc)
  end

  defp do_two_sum(_tuple, _i, left, right, _x, acc) when left >= right, do: acc

  defp do_two_sum(tuple, i, left, right, x, acc) do
    y = elem(tuple, left)
    z = elem(tuple, right)
    sum = x + y + z

    cond do
      sum == 0 ->
        new_acc = [[x, y, z] | acc]
        new_left = skip_left(tuple, left, right)
        new_right = skip_right(tuple, new_left, right)
        do_two_sum(tuple, i, new_left, new_right, x, new_acc)

      sum < 0 ->
        do_two_sum(tuple, i, left + 1, right, x, acc)

      true ->
        do_two_sum(tuple, i, left, right - 1, x, acc)
    end
  end

  defp skip_left(tuple, left, right) do
    if left + 1 < right and elem(tuple, left) == elem(tuple, left + 1) do
      skip_left(tuple, left + 1, right)
    else
      left + 1
    end
  end

  defp skip_right(tuple, left, right) do
    if right - 1 > left and elem(tuple, right) == elem(tuple, right - 1) do
      skip_right(tuple, left, right - 1)
    else
      right - 1
    end
  end
end

defmodule Sum3ProofTest do
  # Proof suite for the article "Solving LeetCode's 3Sum in Elixir"
  # (Elixir 1.20.1 / OTP 29). Same convention.
  use ExUnit.Case, async: true

  @examples [
    {[-1, 0, 1, 2, -1, -4], [[-1, -1, 2], [-1, 0, 1]]},
    {[0, 1, 1], []},
    {[0, 0, 0], [[0, 0, 0]]}
  ]

  @battery [
    [0, 0, 0, 0],
    [-2, -2, 0, 0, 2, 2],
    [-5, -4, -3],
    [1, 2, 3],
    [3, -2, 1, 0, -1, -4, 2],
    [-1, -1, 2]
  ]

  describe "3Sum: correct versions" do
    # 5W1H | Who: reader. What: all three versions pass the LeetCode examples (brute compared as a set — MapSet order is unspecified; two-pointer versions compared exactly, incl. article order). When/Where: article examples 1-3. How: set + exact asserts. Why: baseline correctness with order discipline.
    # STAR | Situation: three example inputs. Task: lock outputs. Action: three_sum each on all three. Result: article outputs everywhere.
    # FLOW ([-1,0,1,2,-1,-4] sorted [-4,-1,-1,0,1,2])
    # i=0,x=-4: no pair sums to 4 → i=1,x=-1: (l=2,r=5) -1-1+2=0 → [-1,-1,2]
    #   skip → (l=3,r=4) -1+0+1=0 → [-1,0,1] → halt
    # i=2 dup skip; i=3,x=0: 0+1+2>0 → halt; i>=4 stop
    #          ▼ [[-1,-1,2],[-1,0,1]]
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | three_sum([-1,0,1,2,-1,-4])   (Sum3Rec / Sum3Rw)
    #        sorted = [-4,-1,-1,0,1,2]
    #        | i | x  | skip?            | left,right walk                                        | acc so far                  |
    #        | 0 | -4 | no               | 1,5: -3<0→2; 2,5: -3<0→3; 3,5: -2<0→4; 4,5: -1<0→5; l>=r | []                          |
    #        | 1 | -1 | no (prev -4 ≠ -1)| 2,5: -1-1+2=0 → [-1,-1,2]; skip_l→3, skip_r→4           | [[-1,-1,2]]                 |
    #        |   |    |                  | 3,4: -1+0+1=0 → [-1,0,1];  skip_l→4, skip_r→3; l>=r    | [[-1,0,1],[-1,-1,2]]        |
    #        | 2 | -1 | YES (prev -1)    | skip                                                   | unchanged                   |
    #        | 3 | 0  | no               | 4,5: 0+1+2=3>0 → right-- → l>=r                         | unchanged                   |
    #        | 4 | —  | i >= n-2 → base  |                                                        | Enum.reverse → article order|
    #        ▼ [[-1,-1,2],[-1,0,1]]
    test "all versions pass the three examples" do
      for {nums, expected} <- @examples do
        assert Sum3Brute.three_sum(nums) |> MapSet.new() == MapSet.new(expected)
        assert Sum3Rec.three_sum(nums) == expected
        assert Sum3Rw.three_sum(nums) == expected
      end
    end

    # 5W1H | Who: reader. What: all three agree (as sets) on duplicate-heavy, all-negative, all-positive and multi-triplet batteries. When/Where: beyond-article robustness incl. dup-skipping and early-break paths. How: set-equality asserts. Why: proves same solution set, not just same examples.
    # STAR | Situation: six batteries. Task: prove agreement. Action: three_sum each on all three, compare sets. Result: equal everywhere.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "all versions agree on the battery" do
      for nums <- @battery do
        assert Sum3Brute.three_sum(nums) |> MapSet.new() ==
                 Sum3Rec.three_sum(nums) |> MapSet.new()

        assert Sum3Rec.three_sum(nums) |> MapSet.new() ==
                 Sum3Rw.three_sum(nums) |> MapSet.new()
      end
    end

    # 5W1H | Who: prover. What: duplicate-heavy [0,0,0,0] yields exactly one triplet on all three — dup-skipping works without relying on the brute-force set. When/Where: article duplicate-skipping logic. How: exact asserts. Why: dedup is the core 3Sum difficulty.
    # STAR | Situation: [0,0,0,0]. Task: prove single triplet. Action: three_sum on all three. Result: [[0,0,0]] thrice.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    # FLOW | three_sum([0,0,0,0])   (dup collapse)
    #        sorted [0,0,0,0]
    #        i=0: x=0, walk 1,3: 0+0+0=0 → [0,0,0]; skip_l: nums[1]==nums[2] → 2; skip_r: nums[3]==nums[2] → 2; l>=r
    #        i=1: prev 0 == 0 → skip | i=2: skip | i >= 2 → base
    #        ▼ [[0,0,0]]   ← exactly one, on all three versions
    test "duplicates collapse to one triplet" do
      assert Sum3Brute.three_sum([0, 0, 0, 0]) |> MapSet.new() == MapSet.new([[0, 0, 0]])
      assert Sum3Rec.three_sum([0, 0, 0, 0]) == [[0, 0, 0]]
      assert Sum3Rw.three_sum([0, 0, 0, 0]) == [[0, 0, 0]]
    end
  end
end

defmodule HallucinationGuardTest do
  # Invented-function guard: AIs hallucinate plausible stdlib names.
  # Every refute below was verified by running function_exported?/3 on
  # Elixir 1.20.1/OTP29 — including the near-misses we almost asserted
  # (Map.update!/3, List.first/2, String.splitter/3 and Enum.find_index/2
  # all EXIST). Same convention: 5W1H + STAR + Author.
  use ExUnit.Case, async: true

  defp loaded!(mod) do
    assert {:module, ^mod} = :code.ensure_loaded(mod)
  end

  describe "hallucinated stdlib functions do not exist" do
    # 5W1H | Who: prover + future AI reader. What: String.reverse_string/1 does not exist (real: reverse/1); calling it raises UndefinedFunctionError. When/Where: Elixir 1.20.1/OTP29 stdlib surface. How: ensure_loaded + refute/assert + apply-raise. Why: kills the most plausible invented name in this corpus (reverse appears everywhere).
    # STAR | Situation: String.reverse_string("ab") vs String.reverse("ab"). Task: prove absent vs present. Action: function_exported? both + apply the fake. Result: false, true, UndefinedFunctionError.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "String.reverse_string/1 is invented" do
      loaded!(String)
      refute function_exported?(String, :reverse_string, 1)
      assert function_exported?(String, :reverse, 1)

      assert_raise UndefinedFunctionError, fn ->
        apply(String, :reverse_string, ["ab"])
      end
    end

    # 5W1H | Who: prover. What: List.index/2 does not exist (real: Enum.find_index/2). When/Where: Elixir 1.20.1/OTP29. How: ensure_loaded + refute/assert. Why: List vs Enum namespace confusion.
    # STAR | Situation: List.index vs Enum.find_index. Task: prove absent vs present. Action: function_exported? both. Result: false, true.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "List.index/2 is invented" do
      loaded!(List)
      loaded!(Enum)
      refute function_exported?(List, :index, 2)
      assert function_exported?(Enum, :find_index, 2)
    end

    # 5W1H | Who: prover. What: Enum.member?/3 does not exist (real: member?/2). When/Where: Elixir 1.20.1/OTP29. How: ensure_loaded + refute/assert. Why: arity hallucination on a real function.
    # STAR | Situation: Enum.member?/3 vs /2. Task: prove absent vs present. Action: function_exported? both. Result: false, true.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "Enum.member?/3 is invented" do
      loaded!(Enum)
      refute function_exported?(Enum, :member?, 3)
      assert function_exported?(Enum, :member?, 2)
    end

    # 5W1H | Who: prover. What: String.split_once/2 does not exist (real: splitter/2,3 and split/2,3). When/Where: Elixir 1.20.1/OTP29. How: ensure_loaded + refute/assert. Why: plausible name stitched from split + once.
    # STAR | Situation: split_once vs splitter/split. Task: prove absent vs present. Action: function_exported? all. Result: false, true, true.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "String.split_once/2 is invented" do
      loaded!(String)
      refute function_exported?(String, :split_once, 2)
      assert function_exported?(String, :splitter, 3)
      assert function_exported?(String, :split, 3)
    end

    # 5W1H | Who: prover. What: Map.merge!/2 does not exist (real: merge/2); Kernel.is_non_empty_list/1 does not exist (real: is_list/1). When/Where: Elixir 1.20.1/OTP29. How: ensure_loaded + refute/assert pairs. Why: bang-suffix and guard-name inventions.
    # STAR | Situation: merge! vs merge, is_non_empty_list vs is_list. Task: prove absent vs present. Action: function_exported? all four. Result: false, true, false, true.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "Map.merge!/2 and Kernel.is_non_empty_list/1 are invented" do
      loaded!(Map)
      loaded!(Kernel)
      refute function_exported?(Map, :merge!, 2)
      assert function_exported?(Map, :merge, 2)
      refute function_exported?(Kernel, :is_non_empty_list, 1)
      assert function_exported?(Kernel, :is_list, 1)
    end

    # 5W1H | Who: prover. What: String.at/3 does not exist (real: at/2). When/Where: Elixir 1.20.1/OTP29. How: ensure_loaded + refute/assert. Why: arity hallucination (a default arg that isn't there).
    # STAR | Situation: String.at/3 vs at/2. Task: prove absent vs present. Action: function_exported? both. Result: false, true.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "String.at/3 is invented" do
      loaded!(String)
      refute function_exported?(String, :at, 3)
      assert function_exported?(String, :at, 2)
    end
  end
end

# Letter Combinations article code, inlined here (this repo never uses /lib).
# NOTE: the article names every version `Solution`; renamed here so all three
# can coexist in one file.
defmodule PhoneIter do
  @keypad %{
    "2" => ["a", "b", "c"],
    "3" => ["d", "e", "f"],
    "4" => ["g", "h", "i"],
    "5" => ["j", "k", "l"],
    "6" => ["m", "n", "o"],
    "7" => ["p", "q", "r", "s"],
    "8" => ["t", "u", "v"],
    "9" => ["w", "x", "y", "z"]
  }

  @spec letter_combinations(digits :: String.t()) :: [String.t()]
  def letter_combinations(""), do: []

  def letter_combinations(digits) do
    digits
    |> String.graphemes()
    |> Enum.reduce([""], fn digit, acc ->
      letters = Map.get(@keypad, digit)

      for combo <- acc, letter <- letters do
        combo <> letter
      end
    end)
  end
end

defmodule PhoneRec do
  @keypad %{
    "2" => ["a", "b", "c"],
    "3" => ["d", "e", "f"],
    "4" => ["g", "h", "i"],
    "5" => ["j", "k", "l"],
    "6" => ["m", "n", "o"],
    "7" => ["p", "q", "r", "s"],
    "8" => ["t", "u", "v"],
    "9" => ["w", "x", "y", "z"]
  }

  @spec letter_combinations(digits :: String.t()) :: [String.t()]
  def letter_combinations(""), do: []

  def letter_combinations(digits) do
    digits
    |> String.graphemes()
    |> build_combinations("")
  end

  defp build_combinations([], current), do: [current]

  defp build_combinations([digit | rest], current) do
    @keypad
    |> Map.get(digit)
    |> Enum.flat_map(fn letter ->
      build_combinations(rest, current <> letter)
    end)
  end
end

defmodule PhoneComp do
  @keypad %{
    "2" => ["a", "b", "c"],
    "3" => ["d", "e", "f"],
    "4" => ["g", "h", "i"],
    "5" => ["j", "k", "l"],
    "6" => ["m", "n", "o"],
    "7" => ["p", "q", "r", "s"],
    "8" => ["t", "u", "v"],
    "9" => ["w", "x", "y", "z"]
  }

  @spec letter_combinations(digits :: String.t()) :: [String.t()]
  def letter_combinations(""), do: []

  def letter_combinations(digits) do
    do_combine(String.graphemes(digits))
  end

  defp do_combine([]), do: [""]

  defp do_combine([digit | rest]) do
    for letter <- Map.get(@keypad, digit),
        tail <- do_combine(rest) do
      letter <> tail
    end
  end
end

defmodule PhoneProofTest do
  # Proof suite for the article "Solving LeetCode's Letter Combinations of a
  # Phone Number in Elixir" (Elixir 1.20.1 / OTP 29). Same convention.
  use ExUnit.Case, async: true

  describe "Phone: correct versions" do
    # 5W1H | Who: reader. What: all three versions pass the LeetCode examples in identical order (order is deterministic though the problem allows any). When/Where: article examples 1-3. How: equality asserts per version. Why: baseline cartesian correctness.
    # STAR | Situation: "23", "", "2". Task: lock outputs. Action: letter_combinations each on all three. Result: 9 combos, [], ["a","b","c"] everywhere.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "all versions pass the three examples" do
      expected_23 = ["ad", "ae", "af", "bd", "be", "bf", "cd", "ce", "cf"]

      assert PhoneIter.letter_combinations("23") == expected_23
      assert PhoneRec.letter_combinations("23") == expected_23
      assert PhoneComp.letter_combinations("23") == expected_23

      assert PhoneIter.letter_combinations("") == []
      assert PhoneRec.letter_combinations("") == []
      assert PhoneComp.letter_combinations("") == []

      assert PhoneIter.letter_combinations("2") == ["a", "b", "c"]
      assert PhoneRec.letter_combinations("2") == ["a", "b", "c"]
      assert PhoneComp.letter_combinations("2") == ["a", "b", "c"]
    end

    # 5W1H | Who: reader. What: all three agree exactly (order included) on repeats, 4-letter digits and longer inputs. When/Where: beyond-article robustness. How: equality asserts + count/ends spot checks on "234". Why: proves same traversal, not just same examples.
    # STAR | Situation: "22", "79", "234", "29". Task: lock agreement. Action: letter_combinations each on all three. Result: identical lists; "234" has 27 combos from "adg" to "cfi".
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "all versions agree on extended battery" do
      for s <- ["22", "79", "29", "7777"] do
        assert PhoneRec.letter_combinations(s) == PhoneIter.letter_combinations(s)
        assert PhoneComp.letter_combinations(s) == PhoneIter.letter_combinations(s)
      end

      combos_234 = PhoneIter.letter_combinations("234")
      assert length(combos_234) == 27
      assert hd(combos_234) == "adg"
      assert List.last(combos_234) == "cfi"
      assert PhoneRec.letter_combinations("234") == combos_234
      assert PhoneComp.letter_combinations("234") == combos_234
    end
  end

  describe "Phone: invalid digits (edge documented)" do
    # 5W1H | Who: prover. What: digits outside 2-9 (and non-digits) crash ALL versions identically: Map.get returns nil, which is not enumerable. When/Where: outside article constraints (digits are 2-9). How: assert_raise per version. Why: keypad-miss contract is a crash, not [].
    # STAR | Situation: "1", "12", "*", "2a3". Task: prove the crash. Action: letter_combinations each on all three. Result: Protocol.UndefinedError everywhere.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "unmapped digits raise on all versions" do
      for s <- ["1", "12", "*", "2a3"] do
        assert_raise Protocol.UndefinedError, fn ->
          PhoneIter.letter_combinations(s)
        end

        assert_raise Protocol.UndefinedError, fn ->
          PhoneRec.letter_combinations(s)
        end

        assert_raise Protocol.UndefinedError, fn ->
          PhoneComp.letter_combinations(s)
        end
      end
    end
  end
end

# 4Sum article code, inlined here (this repo never uses /lib).
# NOTE: the article names every version `Solution`; renamed here so all four
# can coexist in one file.
defmodule FourBrute do
  @spec four_sum(nums :: [integer], target :: integer) :: [[integer]]
  def four_sum(nums, target) do
    n = length(nums)
    tuple = List.to_tuple(nums)

    0..(n - 4)
    |> Enum.reduce(MapSet.new(), fn i, acc ->
      (i + 1)..(n - 3)
      |> Enum.reduce(acc, fn j, acc2 ->
        (j + 1)..(n - 2)
        |> Enum.reduce(acc2, fn k, acc3 ->
          (k + 1)..(n - 1)
          |> Enum.reduce(acc3, fn l, acc4 ->
            if elem(tuple, i) + elem(tuple, j) + elem(tuple, k) + elem(tuple, l) == target do
              quad =
                [elem(tuple, i), elem(tuple, j), elem(tuple, k), elem(tuple, l)]
                |> Enum.sort()

              MapSet.put(acc4, quad)
            else
              acc4
            end
          end)
        end)
      end)
    end)
    |> MapSet.to_list()
  end
end

defmodule FourHash do
  # NOTE: `k` below is unused in the article too (renamed to _k here:
  # verbatim emits an unused-variable warning).
  @spec four_sum(nums :: [integer], target :: integer) :: [[integer]]
  def four_sum(nums, target) do
    sorted = Enum.sort(nums)
    freq = Enum.frequencies(sorted)

    sorted
    |> Enum.with_index()
    |> Enum.reduce(MapSet.new(), fn {num1, i}, acc ->
      freq1 = Map.update!(freq, num1, &(&1 - 1))

      sorted
      |> Enum.drop(i + 1)
      |> Enum.with_index(i + 1)
      |> Enum.reduce(acc, fn {num2, j}, acc2 ->
        freq2 = Map.update!(freq1, num2, &(&1 - 1))

      sorted
      |> Enum.drop(j + 1)
      |> Enum.with_index(j + 1)
      |> Enum.reduce(acc2, fn {num3, _k}, acc3 ->
          freq3 = Map.update!(freq2, num3, &(&1 - 1))
          fourth = target - num1 - num2 - num3

          if Map.get(freq3, fourth, 0) > 0 do
            MapSet.put(acc3, [num1, num2, num3, fourth])
          else
            acc3
          end
        end)
      end)
    end)
    |> MapSet.to_list()
  end
end

defmodule FourRec do
  @spec four_sum(nums :: [integer], target :: integer) :: [[integer]]
  def four_sum(nums, target) do
    nums
    |> Enum.sort()
    |> List.to_tuple()
    |> find_quadruplets(0, target, [])
    |> Enum.reverse()
  end

  defp find_quadruplets(nums, i, _target, acc) when i > tuple_size(nums) - 4, do: acc

  defp find_quadruplets(nums, i, target, acc) do
    x = elem(nums, i)

    if i > 0 and elem(nums, i - 1) == x do
      find_quadruplets(nums, i + 1, target, acc)
    else
      acc = find_second(nums, i, i + 1, target, acc)
      find_quadruplets(nums, i + 1, target, acc)
    end
  end

  # NOTE: `i` is unused in the article's base clause too (renamed to _i: verbatim emits a warning).
  defp find_second(nums, _i, j, _target, acc) when j > tuple_size(nums) - 3, do: acc

  defp find_second(nums, i, j, target, acc) do
    y = elem(nums, j)

    if j > i + 1 and elem(nums, j - 1) == y do
      find_second(nums, i, j + 1, target, acc)
    else
      acc = two_pointers(nums, i, j, j + 1, tuple_size(nums) - 1, target, acc)
      find_second(nums, i, j + 1, target, acc)
    end
  end

  defp two_pointers(_nums, _i, _j, left, right, _target, acc) when left >= right, do: acc

  defp two_pointers(nums, i, j, left, right, target, acc) do
    sum = elem(nums, i) + elem(nums, j) + elem(nums, left) + elem(nums, right)

    cond do
      sum == target ->
        quad = [elem(nums, i), elem(nums, j), elem(nums, left), elem(nums, right)]
        new_acc = [quad | acc]
        new_left = skip_left(nums, left, right)
        new_right = skip_right(nums, new_left, right)
        two_pointers(nums, i, j, new_left, new_right, target, new_acc)

      sum < target ->
        two_pointers(nums, i, j, left + 1, right, target, acc)

      true ->
        two_pointers(nums, i, j, left, right - 1, target, acc)
    end
  end

  defp skip_left(nums, left, right) do
    if left + 1 < right and elem(nums, left) == elem(nums, left + 1) do
      skip_left(nums, left + 1, right)
    else
      left + 1
    end
  end

  defp skip_right(nums, left, right) do
    if right - 1 > left and elem(nums, right) == elem(nums, right - 1) do
      skip_right(nums, left, right - 1)
    else
      right - 1
    end
  end
end

defmodule FourRw do
  @spec four_sum(nums :: [integer], target :: integer) :: [[integer]]
  def four_sum(nums, target) do
    sorted = Enum.sort(nums)
    tuple = List.to_tuple(sorted)
    n = tuple_size(tuple)

    result =
      Enum.reduce_while(0..(n - 4), [], fn i, acc ->
        x = elem(tuple, i)

        if i > 0 and elem(tuple, i - 1) == x do
          {:cont, acc}
        else
          {:cont, process_j(tuple, i, i + 1, n, target, acc)}
        end
      end)

    Enum.reverse(result)
  end

  defp process_j(_tuple, _i, j, n, _target, acc) when j > n - 3, do: acc

  defp process_j(tuple, i, j, n, target, acc) do
    y = elem(tuple, j)

    if j > i + 1 and elem(tuple, j - 1) == y do
      process_j(tuple, i, j + 1, n, target, acc)
    else
      acc = process_two_pointers(tuple, i, j, j + 1, n - 1, target, acc)
      process_j(tuple, i, j + 1, n, target, acc)
    end
  end

  defp process_two_pointers(_tuple, _i, _j, left, right, _target, acc) when left >= right, do: acc

  defp process_two_pointers(tuple, i, j, left, right, target, acc) do
    sum = elem(tuple, i) + elem(tuple, j) + elem(tuple, left) + elem(tuple, right)

    cond do
      sum == target ->
        quad = [elem(tuple, i), elem(tuple, j), elem(tuple, left), elem(tuple, right)]
        new_left = skip_left(tuple, left, right)
        new_right = skip_right(tuple, new_left, right)
        process_two_pointers(tuple, i, j, new_left, new_right, target, [quad | acc])

      sum < target ->
        process_two_pointers(tuple, i, j, left + 1, right, target, acc)

      true ->
        process_two_pointers(tuple, i, j, left, right - 1, target, acc)
    end
  end

  defp skip_left(tuple, left, right) do
    if left + 1 < right and elem(tuple, left) == elem(tuple, left + 1) do
      skip_left(tuple, left + 1, right)
    else
      left + 1
    end
  end

  defp skip_right(tuple, left, right) do
    if right - 1 > left and elem(tuple, right) == elem(tuple, right - 1) do
      skip_right(tuple, left, right - 1)
    else
      right - 1
    end
  end
end

defmodule FourSumProofTest do
  # Proof suite for the article "Solving LeetCode's 4Sum in Elixir"
  # (Elixir 1.20.1 / OTP 29). Same convention.
  use ExUnit.Case, async: true

  @ex1 {[1, 0, -1, 0, -2, 2], 0, [[-2, -1, 1, 2], [-2, 0, 0, 2], [-1, 0, 0, 1]]}
  @ex2 {[2, 2, 2, 2, 2], 8, [[2, 2, 2, 2]]}

  describe "4Sum: correct versions" do
    # 5W1H | Who: reader. What: brute force (as a set), recursive and reduce_while two-pointers (exact order) pass both LeetCode examples. When/Where: article examples 1-2. How: set + exact asserts. Why: baseline correctness with order discipline.
    # STAR | Situation: ex1 (3 quads) and ex2 (dup collapse). Task: lock outputs. Action: four_sum each on all versions but hash. Result: article outputs everywhere.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "examples pass except hash version" do
      for {nums, target, expected} <- [@ex1, @ex2] do
        assert FourBrute.four_sum(nums, target) |> MapSet.new() == MapSet.new(expected)
        assert FourRec.four_sum(nums, target) == expected
        assert FourRw.four_sum(nums, target) == expected
      end
    end

    # 5W1H | Who: reader. What: recursive and reduce_while agree exactly on dup-heavy, negative-target, multi-quad and no-solution batteries. When/Where: beyond-article robustness. How: equality asserts. Why: proves same solution set and order.
    # STAR | Situation: five batteries. Task: lock agreement. Action: four_sum each on both. Result: identical outputs.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "two-pointer versions agree on battery" do
      for {nums, target, expected} <- [
            {[2, 2, 2, 2, 2, 2], 8, [[2, 2, 2, 2]]},
            {[-1, -1, 0, 0, 1, 1, 2, 2], 0, [[-1, -1, 0, 2], [-1, -1, 1, 1], [-1, 0, 0, 1]]},
            {[-5, -4, -3, -2, -1], -14, [[-5, -4, -3, -2]]},
            {[1, 2, 3, 4], 100, []},
            {[1, 0, -1, 0, -2, 2], 0, [[-2, -1, 1, 2], [-2, 0, 0, 2], [-1, 0, 0, 1]]}
          ] do
        assert FourRec.four_sum(nums, target) == expected
        assert FourRw.four_sum(nums, target) == expected
      end
    end
  end

  describe "4Sum: hash version pollutes output (article error documented)" do
    # 5W1H | Who: prover + future AI reader. What: CRITICAL — the frequency-map version appends `fourth` UNSORTED, so MapSet dedup fails and the result contains wrong-order duplicates ([-2,-1,2,1], [0,0,1,-1]…): 10 entries instead of 3. When/Where: article Solution 2 (brute force sorts each triplet; this one forgot). How: size + member asserts. Why: normalize-before-dedup is the whole trick.
    # STAR | Situation: ex1 through the hash version. Task: prove pollution. Action: four_sum, count + check a dupe. Result: 10 entries incl. [-2,-1,2,1].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "hash version returns unsorted duplicates" do
      {nums, target, _} = @ex1
      result = FourHash.four_sum(nums, target)

      assert length(result) == 10
      assert [-2, -1, 2, 1] in result
      refute MapSet.new(result) == MapSet.new([[-2, -1, 1, 2], [-2, 0, 0, 2], [-1, 0, 0, 1]])
    end
  end

  describe "4Sum: short inputs (edge documented)" do
    # 5W1H | Who: prover. What: inputs shorter than 4 elements are IN the constraints (n >= 1): brute force and reduce_while crash (decreasing ranges + out-of-range elem → ArgumentError, warnings captured), while hash and recursive return [] gracefully. When/Where: article never covers n < 4. How: assert_raise with stderr captured + equality asserts. Why: range/edge contract per implementation.
    # STAR | Situation: [], [5], [1,2], [1,2,3]. Task: prove each behavior. Action: four_sum each on all four. Result: ArgumentError, ArgumentError, [], [].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "short inputs diverge per implementation" do
      for {nums, target} <- [{[], 0}, {[5], 5}, {[1, 2], 3}, {[1, 2, 3], 6}] do
        for mod <- [FourBrute, FourRw] do
          err =
            ExUnit.CaptureIO.capture_io(:stderr, fn ->
              send(self(), {:err, try do
                apply(mod, :four_sum, [nums, target])
              rescue
                e -> e
              end})
            end)
            |> then(fn _ ->
              receive do
                {:err, e} -> e
              end
            end)

          assert %ArgumentError{} = err
        end

        assert FourHash.four_sum(nums, target) == []
        assert FourRec.four_sum(nums, target) == []
      end
    end
  end
end

# Remove Nth Node article code, inlined here (this repo never uses /lib).
# NOTE: the article names every version `Solution`; renamed here.
# RemTwoPass is verbatim Solution 1. RemFixedOnePass is a FIX by the prover:
# the article's one-pass idea (n-gap + rebuild) is sound, but both printed
# versions mutate (`slow.next = …`), which does not exist in Elixir.
defmodule RemTwoPass do
  @spec remove_nth_from_end(head :: ListNode.t() | nil, n :: integer) :: ListNode.t() | nil
  def remove_nth_from_end(head, n) do
    remove_at(head, list_length(head) - n)
  end

  defp list_length(nil), do: 0
  defp list_length(%ListNode{next: next}), do: 1 + list_length(next)

  defp remove_at(nil, _pos), do: nil
  defp remove_at(%ListNode{next: next}, 0), do: next

  defp remove_at(%ListNode{val: val, next: next}, pos) do
    %ListNode{val: val, next: remove_at(next, pos - 1)}
  end
end

defmodule RemFixedOnePass do
  @spec remove_nth_from_end(head :: ListNode.t() | nil, n :: integer) :: ListNode.t() | nil
  def remove_nth_from_end(head, n) do
    case advance(head, n) do
      nil -> head.next
      fast -> remove_with_gap(head, fast)
    end
  end

  defp advance(node, 0), do: node
  defp advance(nil, _n), do: nil
  defp advance(%ListNode{next: next}, n), do: advance(next, n - 1)

  defp remove_with_gap(%ListNode{val: v, next: nxt}, %ListNode{next: nil}) do
    %ListNode{val: v, next: nxt.next}
  end

  defp remove_with_gap(%ListNode{val: v, next: nxt}, %ListNode{next: fast_next}) do
    %ListNode{val: v, next: remove_with_gap(nxt, fast_next)}
  end
end

defmodule RemNthProofTest do
  # Proof suite for the article "Solving LeetCode's Remove Nth Node From End
  # of List in Elixir" (Elixir 1.20.1 / OTP 29). Same convention.
  # ListNode is shared with the Add Two Numbers section (same struct).
  use ExUnit.Case, async: true

  defp from_list([]), do: nil
  defp from_list([h | t]), do: %ListNode{val: h, next: from_list(t)}

  defp to_list(nil), do: []
  defp to_list(%ListNode{val: v, next: n}), do: [v | to_list(n)]

  # Solutions 2 and 3 VERBATIM (renamed modules only): both mutate via
  # `slow.next = slow.next.next`, which is not valid Elixir.
  @verbatim_two_ptr_src """
  defmodule CkVerbatimTwoPtr do
    def remove_nth_from_end(head, n) do
      fast = advance(head, n)
      if fast == nil do
        head.next
      else
        slow = move_together(head, fast)
        slow.next = slow.next.next
        head
      end
    end
  end
  """

  @verbatim_dummy_src """
  defmodule CkVerbatimDummy do
    def remove_nth_from_end(head, n) do
      dummy = %ListNode{val: 0, next: head}
      fast = advance(dummy, n + 1)
      slow = move_together(dummy, fast)
      slow.next = slow.next.next
      dummy.next
    end
  end
  """

  describe "Remove Nth: correct versions" do
    # 5W1H | Who: reader. What: two-pass version passes the LeetCode examples plus head/last/middle removals. When/Where: article Solution 1. How: struct→list asserts. Why: baseline count-then-remove correctness.
    # STAR | Situation: [1..5]/2, [1]/1, [1,2]/1, head/middle removals. Task: lock outputs. Action: remove_nth_from_end each. Result: [1,2,3,5], [], [1], [2,3], [1,3].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "two-pass version passes examples and edges" do
      assert RemTwoPass.remove_nth_from_end(from_list([1, 2, 3, 4, 5]), 2) |> to_list() == [1, 2, 3, 5]
      assert RemTwoPass.remove_nth_from_end(from_list([1]), 1) |> to_list() == []
      assert RemTwoPass.remove_nth_from_end(from_list([1, 2]), 1) |> to_list() == [1]
      assert RemTwoPass.remove_nth_from_end(from_list([1, 2, 3]), 3) |> to_list() == [2, 3]
      assert RemTwoPass.remove_nth_from_end(from_list([1, 2, 3]), 2) |> to_list() == [1, 3]
    end

    # 5W1H | Who: reader. What: fixed one-pass (gap + immutable rebuild) matches two-pass everywhere incl. a 10-long list. When/Where: prover fix for the article's mutation syntax. How: equality asserts. Why: proves the one-pass IDEA is sound, only the mutation isn't.
    # STAR | Situation: six inputs incl. Enum 1..10. Task: lock agreement. Action: remove_nth_from_end each on both. Result: identical outputs.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "fixed one-pass matches two-pass" do
      for {l, n} <- [
            {[1, 2, 3, 4, 5], 2},
            {[1], 1},
            {[1, 2], 1},
            {[1, 2, 3], 3},
            {[1, 2, 3], 1},
            {Enum.to_list(1..10), 7}
          ] do
        assert RemFixedOnePass.remove_nth_from_end(from_list(l), n) |> to_list() ==
                 RemTwoPass.remove_nth_from_end(from_list(l), n) |> to_list()
      end
    end

    # 5W1H | Who: prover. What: 10k-node list completes on both (practical robustness at scale). When/Where: beyond-article scale check. How: length + spot asserts. Why: recursion depth behaves at realistic sizes.
    # STAR | Situation: 1..10000, remove 5000th from end (=5001). Task: prove completion. Action: remove_nth_from_end both. Result: 9999 nodes, 5001 gone, 5000/5002 present.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "long list completes on both" do
      for mod <- [RemTwoPass, RemFixedOnePass] do
        result = apply(mod, :remove_nth_from_end, [from_list(Enum.to_list(1..10_000)), 5000]) |> to_list()
        assert length(result) == 9999
        refute 5001 in result
        assert 5000 in result
        assert 5002 in result
      end
    end
  end

  describe "Remove Nth: mutation syntax (article errors documented)" do
    # 5W1H | Who: prover + future AI reader. What: CRITICAL — verbatim one-pass version does not compile: `slow.next = slow.next.next` is imperative mutation smuggled into Elixir (remote call on match left side). When/Where: article Solution 2. How: assert_raise CompileError on verbatim source, stderr captured. Why: assignment is rebinding/matching, never field mutation.
    # STAR | Situation: verbatim two-pointer source. Task: prove it fails. Action: Code.compile_string. Result: CompileError (cannot invoke remote slow.next/0 inside match).
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "verbatim two-pointer does not compile" do
      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        send(self(), {:raised, assert_raise(CompileError, fn -> Code.compile_string(@verbatim_two_ptr_src) end)})
      end)

      receive do
        {:raised, _} -> :ok
      end
    end

    # 5W1H | Who: prover + future AI reader. What: CRITICAL — verbatim dummy-node version has the identical mutation flaw (`slow.next = …`), so the "most elegant" solution is equally uncompilable as printed. When/Where: article Solution 3. How: assert_raise CompileError on verbatim source, stderr captured. Why: same lesson, fancier wrapper.
    # STAR | Situation: verbatim dummy source. Task: prove it fails. Action: Code.compile_string. Result: CompileError (cannot invoke remote slow.next/0 inside match).
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "verbatim dummy version does not compile" do
      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        send(self(), {:raised, assert_raise(CompileError, fn -> Code.compile_string(@verbatim_dummy_src) end)})
      end)

      receive do
        {:raised, _} -> :ok
      end
    end
  end

  describe "Remove Nth: out-of-contract divergence (documented)" do
    # 5W1H | Who: prover. What: n beyond length / nil head are outside constraints (1 <= n <= sz, sz >= 1) and the versions diverge: two-pass degrades gracefully (unchanged list / nil), fixed one-pass hits nil.next → BadMapError. When/Where: article never covers invalid input. How: asserts + assert_raise. Why: graceful-vs-crash contract off-spec.
    # STAR | Situation: ([1], 5) and ([], 1). Task: prove each behavior. Action: remove_nth_from_end on both. Result: [1] vs nil; [] vs BadMapError.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "invalid inputs diverge per implementation" do
      assert RemTwoPass.remove_nth_from_end(from_list([1]), 5) |> to_list() == [1]
      assert RemFixedOnePass.remove_nth_from_end(from_list([1]), 5) == nil

      assert RemTwoPass.remove_nth_from_end(nil, 1) == nil

      assert_raise BadMapError, fn ->
        RemFixedOnePass.remove_nth_from_end(nil, 1)
      end
    end
  end
end
