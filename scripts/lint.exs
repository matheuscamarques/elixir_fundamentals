# Lint the proof suites against CONTRIBUTING.md without touching them.
#
#   mix run scripts/lint.exs
#
# Errors (exit 1): test block missing 5W1H, STAR, or Author line.
# Warnings (exit 0): vague `Why: …repetition…`, mistake rows worth a look.
# Also reports FLOW coverage as information only.
defmodule Lint do
  @files ["test/proof_test.exs", "test/corrections_test.exs"]

  def run do
    blocks = Enum.flat_map(@files, &parse_file/1)
    IO.puts("checking #{length(blocks)} test blocks")

    errors =
      Enum.flat_map(blocks, fn b ->
        has_5w1h = Enum.any?(b.comments, &String.contains?(&1, "5W1H |"))
        has_star = Enum.any?(b.comments, &String.contains?(&1, "STAR |"))
        has_author = Enum.any?(b.comments, &String.contains?(&1, "Author:"))

        []
        |> then(fn e -> if has_5w1h, do: e, else: ["#{loc(b)} missing 5W1H line" | e] end)
        |> then(fn e -> if has_star, do: e, else: ["#{loc(b)} missing STAR line" | e] end)
        |> then(fn e -> if has_author, do: e, else: ["#{loc(b)} missing Author line" | e] end)
      end)

    warnings =
      for b <- blocks,
          line <- b.comments,
          String.contains?(line, "Why:") and String.contains?(line, "repetition"),
          do: "#{loc(b)} vague Why: (repetition)"

    flow = Enum.count(blocks, fn b -> Enum.any?(b.comments, &String.contains?(&1, "# FLOW")) end)
    IO.puts("FLOW coverage: #{flow}/#{length(blocks)} blocks")

    Enum.each(Enum.reverse(errors), &IO.puts("ERROR: " <> &1))
    Enum.each(warnings, &IO.puts("WARN: " <> &1))
    IO.puts("#{length(errors)} errors, #{length(warnings)} warnings")

    if errors == [] do
      IO.puts("lint OK")
    else
      System.halt(1)
    end
  end

  defp loc(b), do: "#{b.file} :: #{b.name}"

  defp parse_file(path) do
    lines = File.read!(path) |> String.split("\n")

    lines
    |> Enum.with_index()
    |> Enum.filter(fn {line, _} -> Regex.match?(~r/^    test ".*" do$/, line) end)
    |> Enum.map(fn {line, idx} ->
      [_, name] = Regex.run(~r/^    test "(.*)" do$/, line)
      %{file: path, name: name, comments: take_comments(lines, idx - 1)}
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
end

Lint.run()
