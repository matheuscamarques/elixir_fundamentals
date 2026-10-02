# Derive the pure-generation slice: verified solution modules as
# standalone rows, no test harness attached.
#
#   mix run scripts/derive_snippets.exs
#
# Reads the top-level `defmodule X do … end` blocks of test/proof_test.exs
# (balanced by column-0 `end`), keeps only the curated solution modules
# below, and emits dataset/snippets.jsonl rows:
# {task, module, category, verified_correct, note, code}.
# Test modules, test-local helpers and verbatim-string sources are skipped.
# Re-run after editing tests. Dependency-free.
defmodule DeriveSnippets do
  @src "test/proof_test.exs"
  @out "dataset/snippets.jsonl"

  # {module, category, verified_correct, note}
  @modules [
    {"Tokenizer", "search_index", true, ""},
    {"InvertedIndex", "search_index", true, ""},
    {"TFIDF", "search_index", true, ""},
    {"TwoSumBrute", "arrays", true, ""},
    {"TwoSumRec", "arrays", true, ""},
    {"TwoSumReduceWhile", "arrays", true, "output order is [later, earlier]"},
    {"TwoSumPattern", "arrays", true, ""},
    {"MedianBrute", "arrays", true, ""},
    {"MedianAtomBS", "arrays", true, ""},
    {"MedianFloatBS", "arrays", true, "raises beyond ±1e308 inputs"},
    {"ListNode", "linked_list", true, ""},
    {"AddTwoNumbersConvert", "linked_list", false, "digits come out forward, not reversed"},
    {"AddTwoNumbersRecursive", "linked_list", true, ""},
    {"AddTwoNumbersAcc", "linked_list", false, "accumulator never reversed"},
    {"AddTwoNumbersLists", "linked_list", false, "misaligns place values on uneven lengths"},
    {"SubstrBrute", "strings", true, ""},
    {"SubstrRec", "strings", true, ""},
    {"SubstrReduceWhile", "strings", true, ""},
    {"PalinBrute", "strings", true, ""},
    {"PalinExpandFixed", "strings", true, ""},
    {"PalTwoPtr", "strings", false, "returns false for single-digit inputs"},
    {"PalHalfBroken", "integers", false, "compares original x against the reversed half"},
    {"PalHalfFixed", "integers", true, ""},
    {"PalStr", "integers", true, ""},
    {"PalFullMath", "integers", true, ""},
    {"ZigzagMap", "strings", true, ""},
    {"ZigzagList", "strings", true, ""},
    {"RevStr", "integers", true, ""},
    {"RevMath", "integers", true, ""},
    {"RevDigits", "integers", true, ""},
    {"RevSafe", "integers", true, "digit>7 threshold inexact outside 32-bit constraints"},
    {"AtoiRegex", "parsing", true, "skips all whitespace, not just space"},
    {"AtoiRec", "parsing", true, ""},
    {"AtoiParse", "parsing", true, ""},
    {"RegexNaive", "regex", true, ""},
    {"RegexDPFixed", "regex", true, ""},
    {"WaterBrute", "arrays", true, ""},
    {"WaterRec", "arrays", true, ""},
    {"WaterRwVerbatim", "arrays", false, "destructures 2-tuple from 3-tuple acc"},
    {"WaterRwFixed", "arrays", true, ""},
    {"RomanGreedy", "numerals", true, ""},
    {"RomanTable", "numerals", true, ""},
    {"RomToIntReduce", "numerals", true, ""},
    {"RomToIntPat", "numerals", true, ""},
    {"RomToIntRtl", "numerals", true, ""},
    {"LcpHoriz", "strings", true, ""},
    {"LcpVert", "strings", true, ""},
    {"LcpSort", "strings", true, ""},
    {"Sum3Brute", "arrays", true, ""},
    {"Sum3Rec", "arrays", true, ""},
    {"Sum3Rw", "arrays", true, ""}
  ]

  def run do
    found = extract_modules(@src)
    wanted = Map.new(@modules, fn {m, c, v, n} -> {m, {c, v, n}} end)

    rows =
      for {name, code} <- found,
          config = Map.get(wanted, name),
          config != nil do
        {category, verified, note} = config

        %{
          "task" => "snippet",
          "module" => name,
          "category" => category,
          "verified_correct" => verified,
          "note" => note,
          "code" => code
        }
      end

    missing = Map.keys(wanted) -- Enum.map(rows, & &1["module"])
    IO.puts("extracted #{length(rows)} modules, missing: #{inspect(missing)}")

    File.mkdir_p!("dataset")
    content = rows |> Enum.map(&encode/1) |> Enum.join("\n")
    File.write!(@out, content <> "\n")
    IO.puts("wrote #{@out}")
  end

  defp extract_modules(path) do
    lines = File.read!(path) |> String.split("\n")
    do_extract(lines, nil, [], [])
  end

  defp do_extract([], nil, _, acc), do: Enum.reverse(acc)
  defp do_extract([], _name, _buf, acc), do: Enum.reverse(acc)

  defp do_extract([line | rest], nil, _, acc) do
    case Regex.run(~r/^defmodule (\w+) do$/, line) do
      [_, name] -> do_extract(rest, name, [line], acc)
      nil -> do_extract(rest, nil, [], acc)
    end
  end

  defp do_extract([line | rest], name, buf, acc) do
    if line == "end" do
      do_extract(rest, nil, [], [{name, Enum.join([line | buf] |> Enum.reverse(), "\n")} | acc])
    else
      do_extract(rest, name, [line | buf], acc)
    end
  end

  defp encode(map) when is_map(map) do
    "{" <>
      (map
       |> Enum.map(fn {k, v} -> encode_string(k) <> ":" <> encode_value(v) end)
       |> Enum.join(",")) <> "}"
  end

  defp encode_value(true), do: "true"
  defp encode_value(false), do: "false"
  defp encode_value(v) when is_binary(v), do: encode_string(v)

  defp encode_string(s) do
    "\"" <>
      (s
       |> String.replace("\\", "\\\\")
       |> String.replace("\"", "\\\"")
       |> String.replace("\n", "\\n")
       |> String.replace("\r", "\\r")
       |> String.replace("\t", "\\t")) <> "\""
  end
end

DeriveSnippets.run()
