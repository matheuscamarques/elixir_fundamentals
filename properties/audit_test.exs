# Audit properties for the proof suites. NOT corpus: this directory is
# excluded from the tuning claim — it AUDITS the examples instead.
# Run with: mix test properties/
#
# Deterministic by design: fixed seeds, hand-rolled generators (no deps).
# If a property fails, the failure (with seed) becomes a new pinned example
# in test/proof_test.exs with 5W1H/STAR — properties discover, examples teach.
# Solution logic below mirrors test/proof_test.exs (renamed Prop* modules)
# so this file runs standalone.
defmodule PropCheck do
  @moduledoc false
  import ExUnit.Assertions, only: [flunk: 1]

  def run(name, cases, fun) do
    failures =
      for {input, seed} <- Enum.with_index(cases, 1),
          not fun.(input),
          do: {seed, input}

    case failures do
      [] ->
        :ok

      [{seed, input} | _] ->
        flunk("#{name} failed on case ##{seed}: #{inspect(input, limit: 12)}")
    end
  end

  def ints(seed, count, range) do
    :rand.seed(:exsss, {seed, seed * 31 + 7, 0x9E3779B9})
    for _ <- 1..count, do: elem(range, 0) + :rand.uniform(elem(range, 1) - elem(range, 0) + 1) - 1
  end

  @words ~w(cat dog fish elixir beam search index token the a of and Quantum BRIDGE x1 99red)
  @seps [" ", "  ", ",", ".", "!", "  THE ", ""]

  def words(seed, count) do
    :rand.seed(:exsss, {seed * 101, seed, 42})
    for _ <- 1..count, do: Enum.at(@words, :rand.uniform(length(@words)) - 1)
  end

  def texts(seed, ndocs, maxwords) do
    :rand.seed(:exsss, {seed * 17, seed * 31, 7})

    for d <- 1..ndocs do
      nw = 1 + :rand.uniform(maxwords)

      words =
        for _ <- 1..nw do
          w = Enum.at(@words, :rand.uniform(length(@words)) - 1)
          if :rand.uniform(4) == 1, do: w <> Enum.at(@seps, :rand.uniform(length(@seps)) - 1), else: w
        end

      {"doc#{d}", Enum.join(words, " ")}
    end
  end
end

defmodule PropTok do
  def tokenize(text) do
    text
    |> String.downcase()
    |> String.split(~r/[^\p{L}\p{N}]+/u, trim: true)
  end
end

defmodule PropIdx do
  def build(documents) do
    documents
    |> Enum.flat_map(fn {doc_id, text} ->
      text
      |> PropTok.tokenize()
      |> Enum.uniq()
      |> Enum.map(fn term -> {term, doc_id} end)
    end)
    |> Enum.group_by(fn {term, _doc} -> term end, fn {_term, doc} -> doc end)
    |> Map.new(fn {term, docs} -> {term, Enum.uniq(docs)} end)
  end

  def search(index, terms, :or) do
    terms |> Enum.flat_map(&Map.get(index, &1, [])) |> Enum.uniq()
  end

  def search(index, terms, :and) do
    terms
    |> Enum.map(&Map.get(index, &1, []))
    |> Enum.map(&MapSet.new/1)
    |> Enum.reduce(fn set, acc -> MapSet.intersection(acc, set) end)
    |> MapSet.to_list()
  end
end

defmodule PropTfidf do
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

  def build_with_tf(documents) do
    documents
    |> Enum.flat_map(fn {doc_id, text} ->
      text
      |> PropTok.tokenize()
      |> Enum.frequencies()
      |> Enum.map(fn {term, count} -> {term, {doc_id, count}} end)
    end)
    |> Enum.group_by(fn {term, _} -> term end, fn {_, value} -> value end)
  end
end

defmodule PropZig do
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

  defp build_rows([], _nr, _row, _dir, acc), do: acc

  defp build_rows([c | rest], nr, row, dir, acc) do
    acc = Map.update(acc, row, [c], &(&1 ++ [c]))
    {nr2, nd} = next(row, dir, nr)
    build_rows(rest, nr, nr2, nd, acc)
  end

  defp next(row, dir, nr) do
    n = row + dir
    cond do
      n < 0 -> {1, 1}
      n >= nr -> {nr - 2, -1}
      true -> {n, dir}
    end
  end

  defp rows_in_order(map, nr), do: Enum.map(0..(nr - 1), fn i -> Map.get(map, i, []) end)
end

defmodule PropertiesAuditTest do
  # Property audits: deterministic, seeded, self-contained.
  # A failure here does NOT enter the corpus — its minimal case enters
  # test/proof_test.exs as a pinned 5W1H/STAR example instead.
  use ExUnit.Case, async: false

  test "tokenizer is idempotent under re-join" do
    cases = for seed <- 1..200, do: PropCheck.texts(seed, 1, 6) |> hd() |> elem(1)

    PropCheck.run("tokenize idempotent", cases, fn s ->
      toks = PropTok.tokenize(s)
      PropTok.tokenize(Enum.join(toks, " ")) == toks
    end)
  end

  test "postings preserve first-occurrence doc order" do
    cases = for seed <- 1..150, do: PropCheck.texts(1000 + seed, 4, 5)

    PropCheck.run("first-occurrence order", cases, fn docs ->
      idx = PropIdx.build(Map.new(docs))

      Enum.all?(idx, fn {term, postings} ->
        expected =
          docs
          |> Enum.filter(fn {_id, text} -> term in PropTok.tokenize(text) end)
          |> Enum.map(fn {id, _} -> id end)

        postings == expected
      end)
    end)
  end

  test "AND results are a subset of OR results" do
    pool = ~w(cat dog fish bird catnip dogma)

    cases =
      for seed <- 1..150 do
        docs = PropCheck.texts(2000 + seed, 3, 4)
        :rand.seed(:exsss, {seed * 13, seed, 99})
        terms = for _ <- 1..3, do: Enum.at(pool, :rand.uniform(length(pool)) - 1)
        {Map.new(docs), terms}
      end

    PropCheck.run("and-subset-or", cases, fn {docs, terms} ->
      idx = PropIdx.build(docs)
      and_set = idx |> PropIdx.search(terms, :and) |> MapSet.new()
      or_set = idx |> PropIdx.search(terms, :or) |> MapSet.new()
      MapSet.subset?(and_set, or_set)
    end)
  end

  test "TFIDF score is monotonic in tf" do
    cases = for seed <- 1..120, do: PropCheck.texts(3000 + seed, 3, 5)

    PropCheck.run("tf monotonic", cases, fn docs ->
      docs = Map.new(docs)
      idx = PropTfidf.build_with_tf(docs)
      total = map_size(docs)

      Enum.all?(docs, fn {id, text} ->
        case PropTok.tokenize(text) do
          [] ->
            true

          [w | _] ->
            before = PropTfidf.score(idx, total, w, id)
            duped = Map.put(docs, id, text <> " " <> w)
            idx2 = PropTfidf.build_with_tf(duped)
            PropTfidf.score(idx2, total, w, id) >= before
        end
      end)
    end)
  end

  test "each doc is found by its own first token" do
    cases = for seed <- 1..150, do: PropCheck.texts(4000 + seed, 3, 4)

    PropCheck.run("self membership", cases, fn docs ->
      docs = Map.new(docs)
      idx = PropIdx.build(docs)

      Enum.all?(docs, fn {id, text} ->
        case PropTok.tokenize(text) do
          [] -> true
          [t | _] -> id in PropIdx.search(idx, [t], :and)
        end
      end)
    end)
  end

  test "zigzag with rows >= length is identity" do
    cases =
      for seed <- 1..150 do
        s = PropCheck.words(seed, 12) |> Enum.join(Enum.at(["", " ", ",", "."], rem(seed, 4)))
        r = String.length(s)..(String.length(s) + 3) |> Enum.to_list() |> List.first()
        {s, max(r, 1)}
      end

    PropCheck.run("zigzag identity", cases, fn {s, r} ->
      PropZig.convert(s, r) == s
    end)
  end
end
