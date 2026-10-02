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
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "D2 word count" do
      result =
        ~w(cat dog cat fish cat)
        |> Enum.reduce(%{}, fn w, acc -> Map.update(acc, w, 1, &(&1 + 1)) end)

      assert result == %{"cat" => 3, "dog" => 1, "fish" => 1}
    end

    # 5W1H | Who: trainee. What: D3 postings — uniq, group_by word, sort doc ids. When/Where: final challenge, inverted-index core shape. How: chained asserts in one pipeline. Why: exact postings construction.
    # STAR | Situation: [{word,doc}] pairs with a duplicate. Task: build %{word=>[sorted ids]}. Action: uniq→group_by→Map.new+sort. Result: %{"cat"=>[1,2],"fish"=>[3]}.
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
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
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
    # 5W1H | Who: prover + future AI reader. What: v1 precedence myth — AST shows (1+2) is the pipe's left side; runtime prints 3. When/Where: article sec.1 misconception, Elixir 1.20. How: quote-shape match plus captured IO. Why: precedence myths produce phantom ArithmeticErrors.
    # STAR | Situation: v1 claimed 1+(2|>puts) then raise. Task: prove (1+2)|>puts. Action: match AST, capture IO. Result: shape matches, output "3\n", :ok.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "1 + 2 |> IO.puts() is (1+2) |> puts, prints 3, no error" do
      # Article claims it parses as 1 + (2 |> puts) and raises ArithmeticError.
      # AST proof: left side of |> is (1+2):
      assert {:|>, _, [{:+, _, [1, 2]}, _]} = quote(do: 1 + 2 |> IO.puts())

      assert ExUnit.CaptureIO.capture_io(fn -> assert (1 + 2 |> IO.puts()) == :ok end) == "3\n"
    end

    # 5W1H | Who: prover. What: v1 self-contradiction — same replace pipe shown as both error and correct. When/Where: article sec.1 counterexamples. How: direct assert it never raises. Why: contradictory docs teach nothing.
    # STAR | Situation: identical line labeled ❌ and ✅. Task: settle it. Action: run the pipe. Result: "hello elixir", no raise.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
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
    terms
    |> Enum.flat_map(&Map.get(index, &1, []))
    |> Enum.uniq()
  end

  def search(index, terms, :and) do
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
    df = index |> Map.get(term, []) |> length()
    if df == 0, do: 0.0, else: :math.log(total_docs / df)
  end

  def score(index, total_docs, term, doc_id) do
    case Enum.find(Map.get(index, term, []), fn {id, _} -> id == doc_id end) do
      nil -> 0.0
      {_id, tf} -> tf * idf(index, total_docs, term)
    end
  end

  def rank(index, total_docs, query_terms) do
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
    test "brute force passes the three examples" do
      assert TwoSumBrute.two_sum([2, 7, 11, 15], 9) == [0, 1]
      assert TwoSumBrute.two_sum([3, 2, 4], 6) == [1, 2]
      assert TwoSumBrute.two_sum([3, 3], 6) == [0, 1]
    end

    # 5W1H | Who: reader. What: recursive hash map passes all three examples, same order as brute force. When/Where: article Solution 2 (recursion). How: equality asserts. Why: optimal O(n) correctness.
    # STAR | Situation: same three examples. Task: lock outputs. Action: two_sum each. Result: [0,1], [1,2], [0,1].
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
    # 5W1H | Who: prover + future AI reader. What: the three "equivalent" solutions DISAGREE with no solution — brute nil, rec [], reduce_while leaks the map, pattern crashes (missing [] clause). When/Where: article assumes exactly one solution, never covers miss. How: asserts + assert_raise. Why: hidden contract divergence.
    # STAR | Situation: [1,2,3]/100 has no pair. Task: prove each behavior. Action: call all four. Result: nil, [], %{1=>0,2=>1,3=>2}, FunctionClauseError.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
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
