import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from perflib import SCHEMA  # noqa: E402
from perflib import compare  # noqa: E402


def record(scenario="query.jq.length", dataset="rec-1m", status="ok", median=10.0, first=None, n=5,
           rel_mad=0.01, anon=100_000, fp=("query", 1, "aa"), lazy=False, error=None, mode="auto", end_anon=0,
           item_error=None):
    rec = {
        "scenario": scenario, "dataset": dataset, "mode": mode, "status": status, "error": error,
        "first_ms": first if first is not None else median, "ops": 1,
        "extra": {"doc": {"lazy": lazy}},
        "process": {"wall_s": 1.0},
    }
    if item_error:
        rec["extra"]["item_errors"] = 1
        rec["extra"]["first_item_error"] = item_error
    if status == "ok":
        rec["stats"] = None if n == 0 else {"n": n, "median": median, "min": median * 0.9, "rel_mad": rel_mad}
        rec["cpu_stats"] = None
        rec["memory_kib"] = {"start": {"anon": 400}, "after_setup": {"anon": 400}, "first_peak_anon": anon,
                             "first_peak_rss": anon, "first_peak_file": 0, "after_first": {"anon": end_anon or anon, "file": 0}}
        rec["fingerprint"] = {"basis": fp[0], "count": fp[1], "hash": fp[2]}
    return rec


def make_run(label, records, datasets=None):
    doc = {
        "schema": SCHEMA, "label": label, "revision": {"short": label}, "results": records,
        "datasets": datasets or {"rec-1m": {"kind": "records", "bytes": 1 << 20},
                                 "rec-300m": {"kind": "records", "bytes": 300 << 20},
                                 "str-2m": {"kind": "strings", "bytes": 2 << 20}},
        "system": {"machine": {"fingerprint": "x"}}, "method": {}, "harness": {},
    }
    run = compare.Run(Path(label + ".json"), doc)
    grouped = {}
    for r in records:
        grouped.setdefault((r["scenario"], r["dataset"], r["mode"]), []).append(r)
    run.index = {k: compare.aggregate(v) for k, v in grouped.items()}
    return run


class Judge(unittest.TestCase):
    def test_a_small_difference_is_not_a_change(self):
        self.assertEqual(compare._judge_time(10.0, 10.8, 0.01, 0.01, 0.10, 3.0)[0], "same")

    def test_a_big_one_is_slower_or_faster_in_both_directions(self):
        self.assertEqual(compare._judge_time(10.0, 12.0, 0.01, 0.01, 0.10, 3.0)[0], "slower")
        self.assertEqual(compare._judge_time(10.0, 8.0, 0.01, 0.01, 0.10, 3.0)[0], "faster")
        # Symmetric: 1.25x slower and 1.25x faster are both beyond 10%.
        self.assertEqual(compare._judge_time(10.0, 12.5, 0, 0, 0.10, 3.0)[0], "slower")
        self.assertEqual(compare._judge_time(12.5, 10.0, 0, 0, 0.10, 3.0)[0], "faster")

    def test_noisy_runs_need_a_bigger_difference(self):
        # 30% apart, but the runs of one scenario differ by 20% among themselves: not a change.
        self.assertEqual(compare._judge_time(10.0, 13.0, 0.20, 0.05, 0.10, 3.0)[0], "same")
        self.assertEqual(compare._judge_time(10.0, 20.0, 0.20, 0.05, 0.10, 3.0)[0], "slower")

    def test_a_difference_the_timer_cannot_see_is_not_one(self):
        self.assertEqual(compare._judge_time(0.001, 0.010, 0, 0, 0.10, 3.0)[0], "same")

    def test_memory_has_a_floor(self):
        a, b = compare.Agg(status="ok", peak_anon_kib=1000), compare.Agg(status="ok", peak_anon_kib=3000)
        self.assertEqual(compare._judge_memory(a, b, 0.10)[0], "same")
        a, b = compare.Agg(status="ok", peak_anon_kib=100_000), compare.Agg(status="ok", peak_anon_kib=200_000)
        self.assertEqual(compare._judge_memory(a, b, 0.10)[0], "heavier")
        self.assertEqual(compare._judge_memory(b, a, 0.10)[0], "lighter")


class Aggregate(unittest.TestCase):
    def test_passes_are_summarized_by_their_median(self):
        agg = compare.aggregate([record(median=10), record(median=30), record(median=11)])
        self.assertEqual(agg.median_ms, 11)
        self.assertEqual(agg.passes, 3)
        self.assertGreater(agg.noise, 1.0, "passes that differ widely are noise too")

    def test_a_failed_scenario_has_its_reason(self):
        agg = compare.aggregate([record(status="error", error="too big")])
        self.assertEqual((agg.status, agg.error), ("error", "too big"))

    def test_a_query_that_made_nothing_but_an_error_is_refused(self):
        agg = compare.aggregate([record(fp=("query", 0, "00"), item_error="`add` needs all of an array in memory")])
        self.assertEqual(agg.status, "refused")
        self.assertIn("needs all of an array", agg.error)
        # An error among results is not a refusal.
        agg = compare.aggregate([record(fp=("query", 5, "01"), item_error="one element was no number")])
        self.assertEqual(agg.status, "ok")
        self.assertEqual(agg.item_errors, 1)

    def test_memory_after_the_first_run_is_what_is_kept(self):
        agg = compare.aggregate([record(anon=500_000, end_anon=300_000)])
        self.assertEqual((agg.peak_anon_kib, agg.end_anon_kib), (500_000, 300_000))


class Compare(unittest.TestCase):
    def rows(self, a, b, **kw):
        result = compare.compare(make_run("a", a), make_run("b", b), **kw)
        return {r.key[0]: r for r in result.rows}, result

    def test_faster_slower_and_same(self):
        rows, result = self.rows(
            [record("s.fast", median=100), record("s.slow", median=10), record("s.same", median=10)],
            [record("s.fast", median=10), record("s.slow", median=100), record("s.same", median=10.2)],
        )
        self.assertEqual((rows["s.fast"].time, rows["s.slow"].time, rows["s.same"].time),
                         ("faster", "slower", "same"))
        self.assertEqual(result.counts(), {"faster": 1, "slower": 1, "same": 1})

    def test_something_that_stops_working_or_starts_is_said(self):
        rows, result = self.rows(
            [record("s.gone"), record("s.new", status="error", error="no")],
            [record("s.gone", status="error", error="refused"), record("s.new")],
        )
        self.assertEqual(rows["s.gone"].status, "newly failing")
        self.assertEqual(rows["s.new"].status, "newly working")
        self.assertEqual(result.counts(), {"failing": 1, "newly working": 1})

    def test_other_answers_are_found_and_a_known_difference_is_marked(self):
        rows, result = self.rows(
            [record("q.a", fp=("query", 5, "1")), record("rows.initial", dataset="str-2m", fp=("rows", 3, "1"))],
            [record("q.a", fp=("query", 5, "2")), record("rows.initial", dataset="str-2m", fp=("rows", 3, "2"))],
        )
        self.assertEqual(rows["q.a"].answers, "differs")
        self.assertEqual(rows["rows.initial"].answers, "expected")
        self.assertEqual(result.counts().get("differs"), 1)

    def test_a_refusal_is_a_query_that_stopped_working_and_a_known_one_says_why(self):
        rows, result = self.rows(
            [record("query.jq.num_add", dataset="rec-300m", fp=("query", 1, "aa"))],
            [record("query.jq.num_add", dataset="rec-300m", fp=("query", 0, "00"), item_error="too much")],
        )
        row = rows["query.jq.num_add"]
        self.assertEqual(row.status, "newly failing")
        self.assertIn("whole list", row.expected_reason)
        self.assertEqual(result.counts().get("failing"), 1)

    def test_another_kind_of_answer_is_not_compared(self):
        rows, _ = self.rows([record("rows.initial", fp=("rows/flat", 9, "1"))],
                            [record("rows.initial", fp=("rows/grouped", 3, "2"))])
        self.assertEqual(rows["rows.initial"].answers, "not comparable")

    def test_a_scenario_too_slow_to_repeat_is_compared_by_its_first_run(self):
        # `a` has samples (median 100, first run 140); `b` was too slow to repeat (first run 150). Compared
        # by medians 100 -> 150 would be "slower"; by the first runs 140 -> 150 it is not.
        rows, _ = self.rows([record("s.big", median=100, first=140, n=5)],
                            [record("s.big", median=0, first=150, n=0)])
        row = rows["s.big"]
        self.assertTrue(row.single_run)
        self.assertAlmostEqual(row.time_ratio, 150 / 140)
        self.assertEqual(row.time, "same")
        # And a real difference between first runs is still found.
        rows, _ = self.rows([record("s.big", median=100, first=140, n=5)],
                            [record("s.big", median=0, first=400, n=0)])
        self.assertEqual(rows["s.big"].time, "slower")

    def test_a_scenario_only_one_run_has_is_left_alone(self):
        rows, result = self.rows([record("s.a")], [record("s.a"), record("s.b")])
        self.assertIsNone(rows["s.b"].a)
        self.assertEqual(rows["s.b"].time, "")

    def test_the_comparison_makes_json(self):
        a, b = make_run("a", [record()]), make_run("b", [record(median=2)])
        out = compare.to_json(a, b, compare.compare(a, b))
        self.assertEqual(out["kind"], "comparison")
        self.assertEqual(out["rows"][0]["time"], "faster")


if __name__ == "__main__":
    unittest.main()
