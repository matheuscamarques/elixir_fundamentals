defmodule ArticleProofTest do
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
    test "basic examples" do
      assert "hello" |> String.upcase() == "HELLO"
      assert "hello" |> String.upcase() |> String.reverse() == "OLLEH"
      assert String.replace("hello world", "world", "elixir") == "hello elixir"
      # pipe passes as first arg, so this is identical to the line above
      assert "hello world" |> String.replace("world", "elixir") == "hello elixir"
    end

    test "exercises 1-4" do
      assert ("abc" |> String.upcase() |> String.length()) == 3
      assert String.upcase("abc") |> String.reverse() == "CBA"
      assert ("abc" |> String.reverse() |> String.upcase() |> String.slice(0, 2)) == "CB"
    end

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
    test "examples" do
      assert String.downcase("CAT") == "cat"
      assert String.downcase("The Cat Climbed The Roof") == "the cat climbed the roof"
      assert String.downcase("AÇÃO") == "ação"
    end

    test "counterexamples raise" do
      assert_raise FunctionClauseError, fn -> String.downcase(opaque(42)) end
      assert_raise FunctionClauseError, fn -> String.downcase(opaque(nil)) end
    end

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
    test "examples" do
      assert String.replace("good morning", "morning", "night") == "good night"
      assert String.replace("a-a-a", "a", "b") == "b-b-b"
      assert String.replace("a1b2c3", ~r/\d/, "*") == "a*b*c*"
      assert String.replace("end.start", ".", "") == "endstart"
      assert String.replace("end.start", ".", " ") == "end start"
      assert String.replace("a,b;c.d", ~r/[,;.]/, "") == "abcd"
      assert String.replace("a,b;c.d", ~r/[,;.]/, " ") == "a b c d"
    end

    test "exercises 9-13" do
      assert String.replace("banana", "a", "o") == "bonono"
      assert String.replace("a b c", " ", "") == "abc"
      assert String.replace("a b c", " ", "_") == "a_b_c"
      assert String.replace("ssn: 123.456.789-00", ~r/\D/, "") == "12345678900"
      assert String.replace("pineapple", "a", "") == "pinepple"
    end

    test "replace is global + case sensitive" do
      assert String.replace("aaa", "a", "b") == "bbb"
      assert String.replace("Aaa", "a", "b") == "Abb"
    end
  end

  # ============================================================
  # 4. String.split/2,3
  # ============================================================
  describe "section 4: split" do
    test "examples (correct claims)" do
      assert String.split("cat dog") == ["cat", "dog"]
      assert String.split("a,b,c", ",") == ["a", "b", "c"]
      assert String.split("cat   dog", ~r/\s+/) == ["cat", "dog"]
      assert String.split("cat   dog", " ") == ["cat", "", "", "dog"]
      assert String.split("a   b   c", ~r/\s+/) == ["a", "b", "c"]
      assert String.split("a   b   c", " ") == ["a", "", "", "b", "", "", "c"]
    end

    test "exercises 14,15,17,18 (correct)" do
      assert String.split("a b c") == ["a", "b", "c"]
      assert String.split("a,b,,c", ",") == ["a", "b", "", "c"]
      assert String.split("a   b   c", ~r/\s+/) == ["a", "b", "c"]
      assert String.split("a   b   c", " ") == ["a", "", "", "b", "", "", "c"]
    end

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

    test "exercises 23-29" do
      assert ("abc" =~ ~r/[^\p{L}\p{N}\s]/u) == false
      assert ("abc!" =~ ~r/[^\p{L}\p{N}\s]/u) == true
      assert ("123" =~ ~r/[^\p{L}\p{N}\s]/u) == false
      assert ("a b" =~ ~r/[^\p{L}\p{N}\s]/u) == false
      assert ("a.b" =~ ~r/[^\p{L}\p{N}\s]/u) == true
      assert ("" =~ ~r/[^\p{L}\p{N}\s]/u) == false
      assert ("a  b" =~ ~r/[^\p{L}\p{N}\s]/u) == false
    end

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
    test "examples + exercises (correct claims)" do
      assert Enum.flat_map([[1, 2], [3, 4]], fn l -> l end) == [1, 2, 3, 4]
      assert Enum.flat_map(["a b", "c d"], fn s -> String.split(s) end) == ["a", "b", "c", "d"]
      assert Enum.flat_map([[[1]], [[2]]], fn l -> l end) == [[1], [2]]
      assert Enum.flat_map([1, 2, 3], fn x -> [x, x] end) == [1, 1, 2, 2, 3, 3]
      assert Enum.flat_map(["ab", "cd"], fn s -> String.graphemes(s) end) == ["a", "b", "c", "d"]
      assert Enum.flat_map([1, 2], fn _ -> [] end) == []
      assert Enum.flat_map([1, 2], fn x -> [[x]] end) == [[1], [2]]
    end

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
    test "exercises 45-48" do
      assert Enum.uniq([1, 1, 1]) == [1]
      assert Enum.uniq([3, 1, 3, 2, 1]) == [3, 1, 2]
      assert Enum.uniq(["a", "A", "a"]) == ["a", "A"]
      assert ([1, 2, 2, 3] |> Enum.uniq() |> Enum.sort()) == [1, 2, 3]
      assert Enum.uniq([3, 1, 2, 1, 3]) == [3, 1, 2]
      assert ([3, 1, 2, 1, 3] |> Enum.uniq() |> Enum.sort()) == [1, 2, 3]
    end

    test "uniq uses strict === comparison" do
      # 1 == 1.0 but not 1 === 1.0, and uniq keeps both => proves ===
      assert Enum.uniq([1, 1.0]) == [1, 1.0]
    end
  end

  # ============================================================
  # 11. Enum.sort/sort_by
  # ============================================================
  describe "section 11: sort" do
    test "correct claims + exercises 49-53" do
      assert Enum.sort([3, 1, 2]) == [1, 2, 3]
      assert Enum.sort(["c", "a", "b"]) == ["a", "b", "c"]
      assert Enum.sort_by([3, 1, 2], fn x -> -x end) == [3, 2, 1]
      assert Enum.sort_by(["banana", "grape", "apple"], fn s -> String.length(s) end) == ["grape", "apple", "banana"]
      assert Enum.sort_by([{2, "a"}, {1, "b"}], fn {n, _} -> n end) == [{1, "b"}, {2, "a"}]
      assert Enum.sort(["banana", "Apple", "grape"]) == ["Apple", "banana", "grape"]
      assert Enum.sort_by([{1, "b"}, {2, "a"}], fn {_, l} -> l end) == [{2, "a"}, {1, "b"}]
    end

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

    test "reduce/2 exists and does NOT raise (article error documented)" do
      # Article claims FunctionClauseError; actually uses first elem as acc:
      assert Enum.reduce([1, 2, 3], fn x, acc -> acc + x end) == 6
    end
  end

  # ============================================================
  # 14. Enum.with_index
  # ============================================================
  describe "section 14: with_index" do
    test "correct claims + exercises 63-66" do
      assert Enum.with_index(["a", "b", "c"]) == [{"a", 0}, {"b", 1}, {"c", 2}]
      assert Enum.with_index(["x", "y"]) == [{"x", 0}, {"y", 1}]
      assert Enum.with_index([10, 20, 30]) == [{10, 0}, {20, 1}, {30, 2}]
      assert Enum.with_index(["a", "b"], fn el, i -> {el, i * 2} end) == [{"a", 0}, {"b", 2}]
      assert Enum.with_index(["a", "b"], fn el, i -> {el, i + 100} end) == [{"a", 100}, {"b", 101}]

      assert ([10, 20, 30] |> Enum.with_index() |> Enum.map(fn {v, _} -> v end)) == [10, 20, 30]
    end

    test "with_index/2 with offset EXISTS (article error documented)" do
      # Article claims UndefinedFunctionError; since Elixir 1.12 offset works:
      assert Enum.with_index(["a", "b"], 1) == [{"a", 1}, {"b", 2}]
    end
  end

  # ============================================================
  # 15. Map.new
  # ============================================================
  describe "section 15: Map.new" do
    test "examples + exercises 67-70" do
      assert Map.new([{:a, 1}, {:b, 2}]) == %{a: 1, b: 2}
      assert Map.new([1, 2, 3], fn x -> {x, x * x} end) == %{1 => 1, 2 => 4, 3 => 9}
      assert Map.new([{:a, 1}, {:a, 2}]) == %{a: 2}
      assert Map.new(["a", "bb"], fn s -> {s, String.length(s)} end) == %{"a" => 1, "bb" => 2}
      assert (Map.new([1, 2], fn x -> {x, x} end) |> Map.get(1)) == 1
      assert Map.new([{:a, 1}, {:a, 2}])[:a] == 2
    end

    test "bad list raises ArgumentError" do
      assert_raise ArgumentError, fn -> Map.new(opaque([1, 2, 3])) end
    end
  end

  # ============================================================
  # 16. Map.get
  # ============================================================
  describe "section 16: Map.get" do
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
    test "examples + exercises 79-82" do
      assert Enum.map([1, 2, 3], &(&1 * 2)) == [2, 4, 6]
      assert Enum.map(["a", "b"], &String.upcase/1) == ["A", "B"]
      assert Enum.map([1, 2], &(&1 + 1)) == Enum.map([1, 2], fn x -> x + 1 end)
      assert Enum.filter([1, 2, 3], &(&1 > 1)) == Enum.filter([1, 2, 3], fn x -> x > 1 end)
      assert Enum.map(["a"], &String.upcase/1) == Enum.map(["a"], fn s -> String.upcase(s) end)

      assert Enum.reject(~w(a the cat), &(&1 in ~w(a the))) ==
               Enum.reject(~w(a the cat), fn t -> t in ~w(a the) end)
    end

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

    test "mismatches raise MatchError" do
      assert_raise MatchError, fn -> Code.eval_string("{a, b} = {1, 2, 3}") end
      assert_raise MatchError, fn -> Code.eval_string("%{x: n} = %{a: 1}") end
    end
  end

  # ============================================================
  # 22. in operator
  # ============================================================
  describe "section 22: in" do
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
    test "exercises 96-98" do
      assert (:math.log(3) > :math.log(2)) == true
      assert (:math.log(3) / :math.log(3)) == 1.0
      assert (:math.log(1) == 0.0) == true
      assert :math.log(1) == 0.0
      assert :math.log(:math.exp(1)) == 1.0
    end

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

    test "D2 word count" do
      result =
        ~w(cat dog cat fish cat)
        |> Enum.reduce(%{}, fn w, acc -> Map.update(acc, w, 1, &(&1 + 1)) end)

      assert result == %{"cat" => 3, "dog" => 1, "fish" => 1}
    end

    test "D3 group word -> sorted doc_ids" do
      result =
        [{"cat", 1}, {"cat", 2}, {"fish", 3}, {"cat", 1}]
        |> Enum.uniq()
        |> Enum.group_by(fn {w, _} -> w end, fn {_, id} -> id end)
        |> Map.new(fn {w, ids} -> {w, Enum.sort(ids)} end)

      assert result == %{"cat" => [1, 2], "fish" => [3]}
    end

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
    test "1 + 2 |> IO.puts() is (1+2) |> puts, prints 3, no error" do
      # Article claims it parses as 1 + (2 |> puts) and raises ArithmeticError.
      # AST proof: left side of |> is (1+2):
      assert {:|>, _, [{:+, _, [1, 2]}, _]} = quote(do: 1 + 2 |> IO.puts())

      assert ExUnit.CaptureIO.capture_io(fn -> assert (1 + 2 |> IO.puts()) == :ok end) == "3\n"
    end

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
