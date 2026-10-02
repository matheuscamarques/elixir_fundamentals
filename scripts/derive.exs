# Derive tuning datasets from the proof suites without touching them.
#
#   mix run scripts/derive.exs
#
# Reads test/proof_test.exs + test/corrections_test.exs with a line-based
# parser (the files keep a strict style: 4-space `test "…" do` … `    end`,
# contiguous `#` comment block above each test) and emits:
#
#   dataset/explain.jsonl  — every test: (comments, test body) pair
#   dataset/detect.jsonl   — mistake rows only: (claim, actual behavior)
#   dataset/fix.jsonl      — known broken→fixed module pairs (curated list)
#   dataset/generate.jsonl — (5W1H+STAR+FLOW prompt, test body response)
#
# Dependency-free (minimal JSON encoder below). Re-run after editing tests.
defmodule Derive do
  @files ["test/proof_test.exs", "test/corrections_test.exs"]

  @mistake_markers [
    "(article error documented)",
    "(article gap documented)",
    "ARTICLE ERROR",
    "ARTICLE GAP",
    "CRITICAL",
    "DIVERGENCE",
    "DIVERGE",
    "WART",
    "CONTRADICTION",
    "BEHAVIORAL DIFFERENCE",
    "SUBTLE",
    "FACTUAL",
    "OWN TRACE",
    "HIDDEN",
    "STUB",
    "MISALIGN",
    "ASYMMETRY",
    "FORK",
    "MYTH",
    "PHANTOM",
    "HALLUCINATE",
    "SELF-CONTRADICT"
  ]

  @fix_pairs [
    {"PalHalfBroken", "PalHalfFixed",
     "compares original x against the reversed half instead of the first half",
     "first half-reversal rejects real palindromes"},
    {"WaterRwVerbatim", "WaterRwFixed",
     "destructures {_, max_area} but the accumulator is always a 3-tuple",
     "verbatim reduce_while raises MatchError on any input"},
    {"VerbatimRegexDP", "RegexDPFixed",
     "nested for-into-map collects maps as entries instead of tuples",
     "verbatim bottom-up crashes on table init"},
    {"AddTwoNumbersAcc", "AddTwoNumbersRecursive",
     "prepending LSB-first without reversing yields MSB-first output",
     "accumulator version returns forward order"}
  ]

  def run do
    blocks = Enum.flat_map(@files, &parse_file/1)
    IO.puts("parsed #{length(blocks)} test blocks")

    File.mkdir_p!("dataset")
    write_jsonl("dataset/explain.jsonl", Enum.map(blocks, &explain_row/1))

    detect = Enum.filter(blocks, &mistake?/1)
    IO.puts("mistake rows: #{length(detect)}")
    write_jsonl("dataset/detect.jsonl", Enum.map(detect, &detect_row/1))
    write_jsonl("dataset/fix.jsonl", Enum.map(@fix_pairs, &fix_row/1))
    write_jsonl("dataset/generate.jsonl", Enum.map(blocks, &generate_row/1))
    IO.puts("wrote dataset/{explain,detect,fix,generate}.jsonl")
  end

  # --- parsing ---

  defp parse_file(path) do
    lines = File.read!(path) |> String.split("\n")

    lines
    |> Enum.with_index()
    |> Enum.filter(fn {line, _} -> Regex.match?(~r/^    test ".*" do$/, line) end)
    |> Enum.map(fn {line, idx} ->
      [_, name] = Regex.run(~r/^    test "(.*)" do$/, line)
      comments = take_comments(lines, idx - 1)
      body = take_body(lines, idx)
      %{file: path, name: name, comments: comments, body: body}
    end)
  end

  defp take_comments(lines, idx), do: take_comments(lines, idx, [])

  defp take_comments(_lines, idx, acc) when idx < 0, do: acc

  defp take_comments(lines, idx, acc) do
    line = Enum.at(lines, idx, "")

    cond do
      Regex.match?(~r/^\s*#/, line) ->
        take_comments(lines, idx - 1, [line | acc])

      # @tag/@describetag lines sit between comments and the test;
      # they are metadata, not content boundaries.
      Regex.match?(~r/^\s*@(tag|describetag)\b/, line) ->
        take_comments(lines, idx - 1, acc)

      true ->
        acc
    end
  end

  defp take_body(lines, from_idx) do
    lines
    |> Enum.drop(from_idx + 1)
    |> Enum.take_while(fn line -> line != "    end" end)
    |> Enum.join("\n")
  end

  # --- row builders ---

  defp mistake?(block) do
    haystack = block.name <> "\n" <> Enum.join(block.comments, "\n")
    Enum.any?(@mistake_markers, &String.contains?(haystack, &1))
  end

  defp explain_row(b) do
    %{
      "task" => "explain",
      "file" => b.file,
      "name" => b.name,
      "comments" => Enum.join(b.comments, "\n"),
      "has_flow" => Enum.any?(b.comments, &String.contains?(&1, "# FLOW")),
      "code" => b.body
    }
  end

  defp detect_row(b) do
    %{
      "task" => "detect",
      "file" => b.file,
      "name" => b.name,
      "comments" => Enum.join(b.comments, "\n"),
      "code" => b.body
    }
  end

  defp fix_row({broken, fixed, why, proven_by}) do
    %{
      "task" => "fix",
      "broken_module" => broken,
      "fixed_module" => fixed,
      "why" => why,
      "proven_by" => proven_by
    }
  end

  defp generate_row(b) do
    %{
      "task" => "generate",
      "prompt" => Enum.join(b.comments, "\n"),
      "response" => "test \"#{b.name}\" do\n#{b.body}\n    end"
    }
  end

  # --- output ---

  defp write_jsonl(path, rows) do
    content = rows |> Enum.map(&encode/1) |> Enum.join("\n")
    File.write!(path, content <> "\n")
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
       |> String.replace("\t", "\\t")
       |> escape_controls()) <> "\""
  end

  defp escape_controls(s) do
    Regex.replace(~r/[\x00-\x1F]/, s, fn <<c>> ->
      "\\u" <> String.pad_leading(Integer.to_string(c, 16), 4, "0")
    end)
  end
end

Derive.run()
