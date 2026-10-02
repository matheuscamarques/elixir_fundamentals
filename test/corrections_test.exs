# CORRECTIONS SPLIT — frozen snapshot for Elixir fine-tuning.
# Every test below documents something a published article got WRONG
# (or left as a gap/divergence): the claim, the proof, and the actual values.
# SELF-CONTAINED by design: every solution module it needs is duplicated here
# under Ck* names (Ck = corrections; byte-identical logic to proof_test.exs).
# The renames exist so the full suite stays warning-free (no double-defined
# modules) and this file runs standalone via `mix test test/corrections_test.exs`.
# Source of truth for all rows: test/proof_test.exs.
# Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>

defmodule CkTokenizer do
  def tokenize(text) do
    text
    |> String.downcase()
    |> String.split(~r/[^\p{L}\p{N}]+/u, trim: true)
  end
end

defmodule CkInvertedIndex do
  alias CkTokenizer

  def build(documents) do
    documents
    |> Enum.flat_map(fn {doc_id, text} ->
      text
      |> CkTokenizer.tokenize()
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
      |> CkTokenizer.tokenize()
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

defmodule CkTFIDF do
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

defmodule CkTwoSumBrute do
  def two_sum(nums, target) do
    Enum.find_value(0..(length(nums) - 2), fn i ->
      Enum.find_value((i + 1)..(length(nums) - 1), fn j ->
        if Enum.at(nums, i) + Enum.at(nums, j) == target, do: [i, j]
      end)
    end)
  end
end

defmodule CkTwoSumRec do
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

defmodule CkTwoSumReduceWhile do
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

defmodule CkTwoSumPattern do
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

defmodule CkMedianBrute do
  def find_median_sorted_arrays(nums1, nums2) do
    merged = Enum.sort(nums1 ++ nums2)
    len = length(merged)

    if rem(len, 2) == 1 do
      Enum.at(merged, div(len, 2)) * 1.0
    else
      (Enum.at(merged, div(len, 2) - 1) + Enum.at(merged, div(len, 2))) / 2
    end
  end
end

defmodule CkMedianAtomBS do
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

defmodule CkMedianFloatBS do
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

defmodule CkListNode do
  @type t :: %__MODULE__{val: integer, next: CkListNode.t() | nil}
  defstruct val: 0, next: nil
end

defmodule CkAddTwoNumbersConvert do
  def add_two_numbers(l1, l2) do
    num1 = list_to_integer(l1, 0, 1)
    num2 = list_to_integer(l2, 0, 1)
    integer_to_list(num1 + num2)
  end

  defp list_to_integer(nil, acc, _multiplier), do: acc

  defp list_to_integer(%CkListNode{val: val, next: next}, acc, multiplier) do
    list_to_integer(next, acc + val * multiplier, multiplier * 10)
  end

  defp integer_to_list(0), do: %CkListNode{val: 0}

  defp integer_to_list(num) do
    build_list(num, nil)
  end

  defp build_list(0, acc), do: acc

  defp build_list(num, acc) do
    digit = rem(num, 10)
    build_list(div(num, 10), %CkListNode{val: digit, next: acc})
  end
end

defmodule CkAddTwoNumbersAcc do
  def add_two_numbers(l1, l2) do
    add_lists(l1, l2, 0, nil)
  end

  defp add_lists(nil, nil, 0, acc), do: acc
  defp add_lists(nil, nil, carry, acc), do: %CkListNode{val: carry, next: acc}

  defp add_lists(nil, %CkListNode{val: val, next: next}, carry, acc) do
    sum = val + carry
    add_lists(nil, next, div(sum, 10), %CkListNode{val: rem(sum, 10), next: acc})
  end

  defp add_lists(%CkListNode{val: val, next: next}, nil, carry, acc) do
    sum = val + carry
    add_lists(next, nil, div(sum, 10), %CkListNode{val: rem(sum, 10), next: acc})
  end

  defp add_lists(%CkListNode{val: v1, next: n1}, %CkListNode{val: v2, next: n2}, carry, acc) do
    sum = v1 + v2 + carry
    add_lists(n1, n2, div(sum, 10), %CkListNode{val: rem(sum, 10), next: acc})
  end
end

defmodule CkAddTwoNumbersLists do
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

defmodule CkSubstrBrute do
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

defmodule CkWaterRwVerbatim do
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

defmodule CkPalTwoPtr do
  def is_palindrome(x) do
    chars = x |> Integer.to_string() |> String.graphemes()
    n = length(chars)

    0..(div(n, 2) - 1)
    |> Enum.all?(fn i -> Enum.at(chars, i) == Enum.at(chars, n - 1 - i) end)
  end
end

defmodule CkPalHalfBroken do
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

defmodule CkRevMath do
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

defmodule CkRevSafe do
  @max 2_147_483_647
  @min -2_147_483_648

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

defmodule CkAtoiRegex do
  @max 2_147_483_647
  @min -2_147_483_648

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

defmodule CkAtoiRec do
  @max 2_147_483_647
  @min -2_147_483_648

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

defmodule CkAtoiParse do
  @max 2_147_483_647
  @min -2_147_483_648

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

defmodule CorrectionsProofTest do
  use ExUnit.Case, async: true

  @docs %{
    "doc1" => "Elixir is a functional language",
    "doc2" => "Elixir runs on the BEAM virtual machine",
    "doc3" => "Functional programming is powerful"
  }

  defp from_list([]), do: nil
  defp from_list([h | t]), do: %CkListNode{val: h, next: from_list(t)}

  defp to_list(nil), do: []
  defp to_list(%CkListNode{val: v, next: n}), do: [v | to_list(n)]

  @verbatim_expand_src """
  defmodule CkVerbatimExpand2 do
    defp expand(chars, left, right, n) when left >= 0 and right < n and Enum.at(chars, left) == Enum.at(chars, right) do
      expand(chars, left - 1, right + 1, n)
    end
    defp expand(_chars, left, right, _n), do: {left + 1, right - left - 1}
  end
  """

  @verbatim_manacher_src """
  defmodule CkVerbatimManacher2 do
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

  @verbatim_math_src """
  defmodule CkVerbatimZigzagMath2 do
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

  @verbatim_dp_src """
  defmodule CkVerbatimRegexDP2 do
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

  describe "corrections: pipe operator" do
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

  describe "corrections: fundamentals v1 errors" do
    # 5W1H | Who: prover + future AI reader. What: v1 article error — trim:true removes ALL empties, not edges only. When/Where: article sec.4, Elixir 1.20. How: asserts on real outputs. Why: this exact myth corrupts tokenizers.
    # STAR | Situation: v1 claimed ["a","","b"] and ["a","b","","c"]. Task: prove actual. Action: split with trim:true and without. Result: ["a","b"], ["a","b","c"], full empties list.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "trim: true removes ALL empties, not only edges (article error documented)" do
      # Article claims ["a", "", "b"] and ["a","b","","c"] — actually:
      assert String.split("  a  b  ", " ", trim: true) == ["a", "b"]
      assert String.split("a,b,,c", ",", trim: true) == ["a", "b", "c"]
      assert String.split("  a  b  ", " ") == ["", "", "a", "", "b", "", ""]
    end

    # 5W1H | Who: prover + future AI reader. What: v1 error — \p without /u does NOT raise on OTP 29. When/Where: article sec.6, Elixir 1.20.1/OTP 29. How: direct =~ asserts. Why: keeps the /u rule while fixing the claimed error type.
    # STAR | Situation: v1 claimed Regex.CompileError for "é". Task: prove actual. Action: match with and without /u. Result: true both times, no raise.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "\\p without /u does NOT raise on Elixir 1.20/OTP29 (article error documented)" do
      # Article claims ** (Regex.CompileError) for "é" =~ ~r/\p{L}/
      assert ("cat" =~ ~r/\p{L}/) == true
      assert ("é" =~ ~r/\p{L}/) == true
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

    # 5W1H | Who: prover + future AI reader. What: v1 error — mixed-type sort does NOT raise; Erlang term order applies. When/Where: article sec.11. How: single assert. Why: AIs invent ArgumentError here.
    # STAR | Situation: v1 claimed ArgumentError. Task: prove actual. Action: sort [1, "a", :ok]. Result: [1, :ok, "a"].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "sort of mixed types does NOT raise (article error documented)" do
      # Article claims ** (ArgumentError); term ordering applies instead:
      # number < atom < binary
      assert Enum.sort([1, "a", :ok]) == [1, :ok, "a"]
    end

    # 5W1H | Who: prover + future AI reader. What: v1 error — reduce/2 EXISTS and sums with first elem as acc. When/Where: article sec.13. How: single assert. Why: prefer explicit reduce/3 but know /2 works.
    # STAR | Situation: v1 claimed FunctionClauseError. Task: prove actual. Action: reduce without initial. Result: 6.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "reduce/2 exists and does NOT raise (article error documented)" do
      # Article claims FunctionClauseError; actually uses first elem as acc:
      assert Enum.reduce([1, 2, 3], fn x, acc -> acc + x end) == 6
    end

    # 5W1H | Who: prover + future AI reader. What: v1 error — with_index/2 integer offset EXISTS since Elixir 1.12. When/Where: article sec.14. How: single assert. Why: outdated "no offset" knowledge.
    # STAR | Situation: v1 claimed UndefinedFunctionError. Task: prove actual. Action: with_index(["a","b"], 1). Result: [{"a",1},{"b",2}].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "with_index/2 with offset EXISTS (article error documented)" do
      # Article claims UndefinedFunctionError; since Elixir 1.12 offset works:
      assert Enum.with_index(["a", "b"], 1) == [{"a", 1}, {"b", 2}]
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

  describe "corrections: inverted index" do
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

    # 5W1H | Who: prover + future AI reader. What: ARTICLE ERROR — doc1 scores 2*log(3/2)=0.8109, NOT log(3)=1.0986; order [doc1,doc2,doc3] is right. When/Where: article Step 5 final ranking. How: exact-list assert. Why: the article's headline number is wrong.
    # STAR | Situation: article claims [{"doc1",1.098...},...]. Task: prove actual. Action: rank ["elixir","functional"]. Result: [{"doc1",0.8109...},{"doc2",0.405...},{"doc3",0.405...}].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "rank numbers (article doc1 value corrected)" do
      index = CkInvertedIndex.build_with_tf(@docs)

      assert CkTFIDF.rank(index, 3, ["elixir", "functional"]) == [
               {"doc1", 2 * :math.log(3 / 2)},
               {"doc2", :math.log(3 / 2)},
               {"doc3", :math.log(3 / 2)}
             ]
    end

    # 5W1H | Who: prover + future AI reader. What: ARTICLE GAP — empty AND query crashes (reduce/2 on []). When/Where: article Step 3 never covers []. How: assert_raise. Why: reduce/2 needs ≥1 element; OR [] is fine.
    # STAR | Situation: search(index, [], :and). Task: prove the crash. Action: run inside assert_raise; contrast OR []. Result: Enum.EmptyError; OR gives [].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "empty AND terms raise Enum.EmptyError (article gap documented)" do
      index = CkInvertedIndex.build(@docs)

      assert_raise Enum.EmptyError, fn ->
        CkInvertedIndex.search(index, [], :and)
      end

      assert CkInvertedIndex.search(index, [], :or) == []
    end

    # 5W1H | Who: prover. What: ARTICLE GAP — bare `def search` blocks belong to InvertedIndex. When/Where: article Step 3 prints defs with no defmodule. How: function_exported? asserts. Why: as printed, the code does not compile standalone.
    # STAR | Situation: usage calls InvertedIndex.search/3. Task: pin the home module. Action: assert exports. Result: search/3, build/1, build_with_tf/1 all exported.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "search lives in InvertedIndex (article gap documented)" do
      assert function_exported?(CkInvertedIndex, :search, 3)
      assert function_exported?(CkInvertedIndex, :build, 1)
      assert function_exported?(CkInvertedIndex, :build_with_tf, 1)
    end
  end

  describe "corrections: Two Sum divergences" do
    # 5W1H | Who: prover + future AI reader. What: reduce_while finds the SAME pair but REVERSED ([later, earlier]) — article shows no outputs, hiding this. When/Where: article Solution 2 (reduce_while). How: equality asserts on reversed lists. Why: order differs across "equivalent" solutions.
    # STAR | Situation: same three examples. Task: prove reversed order. Action: two_sum each. Result: [1,0], [2,1], [1,0] (LeetCode accepts either order).
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "reduce_while passes examples reversed (behavioral difference documented)" do
      assert CkTwoSumReduceWhile.two_sum([2, 7, 11, 15], 9) == [1, 0]
      assert CkTwoSumReduceWhile.two_sum([3, 2, 4], 6) == [2, 1]
      assert CkTwoSumReduceWhile.two_sum([3, 3], 6) == [1, 0]
    end

    # 5W1H | Who: prover + future AI reader. What: the three "equivalent" solutions DISAGREE with no solution — brute nil, rec [], reduce_while leaks the map, pattern crashes (missing [] clause). When/Where: article assumes exactly one solution, never covers miss. How: asserts + assert_raise. Why: hidden contract divergence.
    # STAR | Situation: [1,2,3]/100 has no pair. Task: prove each behavior. Action: call all four. Result: nil, [], %{1=>0,2=>1,3=>2}, FunctionClauseError.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "no-solution inputs diverge per implementation" do
      assert CkTwoSumBrute.two_sum([1, 2, 3], 100) == nil
      assert CkTwoSumRec.two_sum([1, 2, 3], 100) == []
      assert CkTwoSumReduceWhile.two_sum([1, 2, 3], 100) == %{1 => 0, 2 => 1, 3 => 2}

      assert_raise FunctionClauseError, fn ->
        CkTwoSumPattern.two_sum([1, 2, 3], 100)
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
              apply(CkTwoSumBrute, :two_sum, args)
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

  describe "corrections: Median divergences" do
    # 5W1H | Who: prover + future AI reader. What: BEHAVIORAL DIFFERENCE — float sentinels assume inputs within ±1e308; beyond that the partition logic corrupts and raises RuntimeError, while atom sentinels stay exact (only float conversion can overflow). When/Where: article never bounds its inputs. How: assert_raise on 10^400. Why: sentinel choice is a hidden precondition.
    # STAR | Situation: [10^400]/[]. Task: prove divergence. Action: run both versions. Result: float raises RuntimeError("No valid partition found"); atom raises ArithmeticError (honest 1.0e400 overflow).
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "sentinels diverge beyond float range" do
      big = 10 ** 400

      assert_raise RuntimeError, "No valid partition found", fn ->
        CkMedianFloatBS.find_median_sorted_arrays([big], [])
      end

      assert_raise ArithmeticError, fn ->
        CkMedianAtomBS.find_median_sorted_arrays([big], [])
      end
    end

    # 5W1H | Who: prover. What: both-empty inputs diverge — brute/atom raise ArithmeticError (nil+nil, :neg_infinity+:infinity), float version silently returns 0.0. When/Where: article never covers degenerate input. How: asserts + assert_raise. Why: undefined-median handling differs.
    # STAR | Situation: ([], []). Task: prove each behavior. Action: run all three. Result: ArithmeticError, ArithmeticError, 0.0.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "both-empty inputs diverge per implementation" do
      assert_raise ArithmeticError, fn ->
        CkMedianBrute.find_median_sorted_arrays([], [])
      end

      assert_raise ArithmeticError, fn ->
        CkMedianAtomBS.find_median_sorted_arrays([], [])
      end

      assert CkMedianFloatBS.find_median_sorted_arrays([], []) == 0.0
    end
  end

  describe "corrections: Add Two Numbers bugs" do
    # 5W1H | Who: prover + future AI reader. What: ARTICLE ERROR — integer-conversion returns digits FORWARD ([8,0,7]) because build_list prepends least-significant-first. When/Where: article Solution 1. How: assert actual + refute expected. Why: prepend-direction confusion.
    # STAR | Situation: 342+465=807, article implies [7,0,8]. Task: prove actual. Action: add_two_numbers. Result: [8,0,7], refutes [7,0,8].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "conversion version returns forward order" do
      assert CkAddTwoNumbersConvert.add_two_numbers(from_list([2, 4, 3]), from_list([5, 6, 4])) |> to_list() == [8, 0, 7]
      refute CkAddTwoNumbersConvert.add_two_numbers(from_list([2, 4, 3]), from_list([5, 6, 4])) |> to_list() == [7, 0, 8]
    end

    # 5W1H | Who: prover + future AI reader. What: ARTICLE ERROR — accumulator version returns [8,0,7], contradicting the "built in the correct order" claim; prepending LSB-first yields MSB-first. When/Where: article Solution 3. How: assert actual + refute expected. Why: same prepend-direction confusion, plus a false correctness claim.
    # STAR | Situation: [2,4,3]+[5,6,4]. Task: prove actual. Action: add_two_numbers. Result: [8,0,7], refutes [7,0,8].
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "accumulator version returns forward order" do
      assert CkAddTwoNumbersAcc.add_two_numbers(from_list([2, 4, 3]), from_list([5, 6, 4])) |> to_list() == [8, 0, 7]
      refute CkAddTwoNumbersAcc.add_two_numbers(from_list([2, 4, 3]), from_list([5, 6, 4])) |> to_list() == [7, 0, 8]
    end

    # 5W1H | Who: prover + future AI reader. What: ARTICLE ERROR — plain-list version misaligns place values on UNEVEN lengths: reversing then pairing head-to-head aligns MSB-with-MSB, but addition needs LSB-with-LSB; 81+0 yields [8,1] (=18). When/Where: article Solution 4, never tested uneven. How: assert actual wrong value. Why: reverse-then-zip only works for equal lengths.
    # STAR | Situation: [1,8]+[0] is 81+0=81, expect [1,8]. Task: prove actual. Action: add_two_numbers. Result: [8,1] (wrong value, not just order).
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "plain-list version misaligns uneven lengths" do
      assert CkAddTwoNumbersLists.add_two_numbers([1, 8], [0]) == [8, 1]
      refute CkAddTwoNumbersLists.add_two_numbers([1, 8], [0]) == [1, 8]
    end
  end

  describe "corrections: sliding-window wart" do
    # 5W1H | Who: prover + future AI reader. What: MINOR WART — brute force on "" still returns 0 but emits TWO decreasing-Range warnings (0..-1 and inner (i+1)..n); the article credits Enum.max(fn->0 end) yet omits this noise. When/Where: article Solution 1 on empty input, Elixir 1.20. How: capture stderr, assert result + warning text. Why: keeps suite output clean and documents the wart.
    # STAR | Situation: length_of_longest_substring(""). Task: prove 0 AND the warnings. Action: run with stderr captured. Result: 0 with "Range" warnings present.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "brute force on empty string warns but returns zero" do
      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          send(self(), {:res, CkSubstrBrute.length_of_longest_substring("")})
        end)

      receive do
        {:res, result} -> assert result == 0
      end

      assert output =~ "Range"
    end
  end

  describe "corrections: palindrome critical errors" do
    # 5W1H | Who: prover + future AI reader. What: CRITICAL — the printed expand/4 guard calls Enum.at/2, which is NOT guard-safe: the flagship solution does not compile as printed. When/Where: article Solution 2. How: assert_raise CompileError on verbatim source, stderr captured. Why: guard-safe boundary every Elixir dev must know.
    # STAR | Situation: verbatim guard with Enum.at. Task: prove it fails. Action: Code.compile_string. Result: CompileError (cannot invoke remote Enum.at/2 inside guard).
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
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

    # 5W1H | Who: prover + future AI reader. What: ARTICLE ERROR — two-pointer on a SINGLE digit builds 0..-1 (decreasing range, warns) and compares the char against out-of-range nil, returning false for true palindromes 0-9. When/Where: article Solution 2, n = 1. How: assert false with stderr captured. Why: single-element range edge.
    # STAR | Situation: is_palindrome(5). Task: prove the wrong answer. Action: run with stderr captured. Result: false (plus Range warning).
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "two-pointer fails single digits" do
      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        send(self(), {:res, CkPalTwoPtr.is_palindrome(5)})
      end)

      receive do
        {:res, result} -> assert result == false
      end
    end

    # 5W1H | Who: prover + future AI reader. What: ARTICLE'S OWN TRACE ADMITS IT — first half-reversal compares the ORIGINAL x against the reversed half (121 vs 12), so every multi-digit palindrome returns false. When/Where: article Solution 4 before its self-correction. How: assert false on known palindromes. Why: compares wrong halves.
    # STAR | Situation: 121, 1221, 12321, 1001. Task: prove the failure. Action: is_palindrome each. Result: false, false, false, false.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "first half-reversal rejects real palindromes" do
      for x <- [121, 1221, 12321, 1001] do
        assert CkPalHalfBroken.is_palindrome(x) == false
      end
    end

    # 5W1H | Who: prover + future AI reader. What: FACTUAL ERROR — article claims div(-121, 10) returns -13; Elixir div truncates toward zero, so it is -12 (floor_div would give -13). rem(-121, 10) == -1 is correct. When/Where: article pitfalls on negative rem/div. How: equality asserts. Why: truncated vs floored division.
    # STAR | Situation: div(-121, 10), rem(-121, 10). Task: prove actual values. Action: evaluate both. Result: -12 (refutes -13), -1.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "negative div truncates toward zero" do
      assert div(-121, 10) == -12
      refute div(-121, 10) == -13
      assert rem(-121, 10) == -1
    end
  end

  describe "corrections: zigzag stub" do
    # 5W1H | Who: prover + future AI reader. What: CRITICAL — Solution 3 is an unfinished STUB: the unfold step body is only comments, so it halts immediately and every row is ""; both examples return "". When/Where: article "Mathematical Pattern". How: runtime-compile verbatim source (stderr captured for its unused-var warnings), assert "". Why: sketches presented as implementations.
    # STAR | Situation: verbatim math solution on both LeetCode examples. Task: prove empty results. Action: compile source, convert each. Result: "", "".
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
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

  describe "corrections: reverse-integer asymmetry" do
    # 5W1H | Who: prover + future AI reader. What: SUBTLE — the safe-math `digit > 7` threshold encodes only MAX (…847); a reversal of exactly 2147483648 with negative sign is the valid MIN, but the pre-check returns 0. Unreachable under LeetCode constraints (it needs abs(x) = 8463847412), provable only with out-of-range input since Elixir has big ints. When/Where: article Solution 4. How: assert divergence on x = -8463847412. Why: thresholds copied from editorials carry hidden asymmetry.
    # STAR | Situation: x = -8463847412 (outside constraints). Task: expose asymmetry. Action: reverse with math vs safe versions. Result: -2147483648 vs 0.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "safe pre-check is exact only within constraints" do
      assert CkRevMath.reverse(-8_463_847_412) == -2_147_483_648
      assert CkRevSafe.reverse(-8_463_847_412) == 0
    end
  end

  describe "corrections: atoi whitespace fork" do
    # 5W1H | Who: prover + future AI reader. What: INTERNAL CONTRADICTION — the regex version skips ALL whitespace (\s: tab, newline), while the article's own pitfall rule says only ' ' counts and Solutions 2/3 enforce exactly that. When/Where: article Solution 1 vs its pitfalls + Solutions 2/3. How: assert divergence on "\t42" and "\n-42". Why: \s vs " " is a real spec fork.
    # STAR | Situation: leading tab/newline inputs. Task: prove the split. Action: my_atoi on all three. Result: regex 42/-42 vs 0/0 on the other two.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "tab and newline split the implementations" do
      assert CkAtoiRegex.my_atoi("\t42") == 42
      assert CkAtoiRec.my_atoi("\t42") == 0
      assert CkAtoiParse.my_atoi("\t42") == 0

      assert CkAtoiRegex.my_atoi("\n-42") == -42
      assert CkAtoiRec.my_atoi("\n-42") == 0
      assert CkAtoiParse.my_atoi("\n-42") == 0
    end
  end

  describe "corrections: water destructure" do
    # 5W1H | Who: prover + future AI reader. What: CRITICAL — verbatim reduce_while destructures `{_, max_area}` but the accumulator is always the 3-tuple {left, right, best}, so EVERY input raises MatchError. When/Where: article Solution 2 alternative. How: assert_raise on three inputs. Why: acc shape must match the pattern.
    # STAR | Situation: verbatim version on [1,1], the big example, [4,3,2,1,4]. Task: prove the crash. Action: max_area each. Result: MatchError thrice.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
    test "verbatim reduce_while raises MatchError on any input" do
      for h <- [[1, 1], [1, 8, 6, 2, 5, 4, 8, 3, 7], [4, 3, 2, 1, 4]] do
        assert_raise MatchError, fn ->
          CkWaterRwVerbatim.max_area(h)
        end
      end
    end
  end

  describe "corrections: regex table init" do
    # 5W1H | Who: prover + future AI reader. What: CRITICAL — verbatim bottom-up DP crashes on ANY input: nested `for i <- 0..m, into: %{} do <map>` tries to collect maps as entries (`:maps.from_list` gets maps, not tuples) → ArgumentError before any matching. When/Where: article Solution 3 table init. How: runtime-compile verbatim source, assert_raise on apply. Why: for-into shape must yield entries, not collections. Fix: `for i <- 0..m, j <- 0..n, into: %{}, do: {{i, j}, false}`.
    # STAR | Situation: verbatim DP on ("aa", "a"). Task: prove the crash. Action: compile source, is_match. Result: ArgumentError.
    # Author: Matheus de Camargo Marques <matheuscamarques@gmail.com>
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
