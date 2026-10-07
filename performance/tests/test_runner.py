import json
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from perflib import plancheck, report, runner  # noqa: E402


def scenario(id, kinds=("records",), min_mib=0, max_mib=None, group=None, needs_lazy=False):
    return {"id": id, "group": group or id.split(".")[0], "kinds": list(kinds), "min_mib": min_mib,
            "max_mib": max_mib, "needs_lazy": needs_lazy, "title": id}


CATALOGUE = [
    scenario("load.open", ("records", "wide", "tiny")),
    scenario("load.open_cold", ("records",), min_mib=100),
    scenario("query.jq.length", ("records",)),
    scenario("tools.format_parsed", ("records",), max_mib=128),
    scenario("tools.format_stream", ("records",), min_mib=256, needs_lazy=True),
    scenario("search.key_once", ("wide",)),
]


class Plan(unittest.TestCase):
    def ids(self, profile, **kw):
        return {(i.dataset, i.mode, i.scenario["id"]) for i in runner.plan(profile, CATALOGUE, kw.get("only"), kw.get("exclude"))}

    def test_a_scenario_runs_on_the_kinds_and_sizes_it_is_for(self):
        got = self.ids("standard")
        self.assertIn(("rec-1m", "auto", "load.open"), got)
        self.assertIn(("tiny", "auto", "load.open"), got)
        self.assertNotIn(("rec-1m", "auto", "load.open_cold"), got, "too small to be read cold")
        self.assertIn(("rec-100m", "auto", "load.open_cold"), got)
        self.assertNotIn(("rec-300m", "auto", "tools.format_parsed"), got, "the Tools refuse over 128 MB")
        self.assertIn(("rec-300m", "auto", "tools.format_stream"), got)
        self.assertNotIn(("rec-16m", "auto", "tools.format_stream"), got)
        self.assertIn(("obj-300m", "auto", "search.key_once"), got)
        self.assertNotIn(("rec-300m", "auto", "search.key_once"), got, "no such kind")

    def test_filters(self):
        only = self.ids("standard", only=r"^load\.open$")
        self.assertTrue(only and all(s == "load.open" for _, _, s in only))
        small = self.ids("standard", only="rec-1m")
        self.assertTrue(all(d == "rec-1m" for d, _, _ in small))
        skipped = self.ids("standard", exclude="300m")
        self.assertTrue(all("300m" not in d for d, _, _ in skipped))

    def test_the_threshold_profile_runs_the_same_files_both_ways(self):
        got = self.ids("threshold")
        self.assertIn(("rec-16m", "parsed", "load.open"), got)
        self.assertIn(("rec-16m", "lazy", "load.open"), got)
        self.assertNotIn(("rec-16m", "lazy", "tools.format_parsed"), got, "a tool does not depend on how a file is kept")

    def test_a_profile_that_does_not_exist_is_an_error(self):
        with self.assertRaises(SystemExit):
            runner.plan("nope", CATALOGUE, None, None)


class Estimate(unittest.TestCase):
    def build(self, lazy):
        return SimpleNamespace(info={"lazy_documents": lazy})

    def test_a_parsed_gigabyte_is_heavy_and_a_kept_one_is_not(self):
        meta = {"bytes": 1024 * runner.MIB, "parsed_factor": 17}
        parsed = runner.estimate_mib(self.build(False), meta, "auto", scenario("query.jq.length"))
        kept = runner.estimate_mib(self.build(True), meta, "auto", scenario("query.jq.length"))
        self.assertGreater(parsed, 20_000)
        self.assertLess(kept, 1500)

    def test_below_the_threshold_both_parse(self):
        meta = {"bytes": 100 * runner.MIB, "parsed_factor": 17}
        self.assertEqual(runner.estimate_mib(self.build(True), meta, "auto", scenario("load.open")),
                         runner.estimate_mib(self.build(False), meta, "auto", scenario("load.open")))
        # ... unless told to keep it on disk.
        self.assertLess(runner.estimate_mib(self.build(True), meta, "lazy", scenario("load.open")), 1000)


class Cgroup(unittest.TestCase):
    def test_the_command_is_run_under_a_ceiling(self):
        cmd = runner.cgroup_command(2048, ["prog", "run"])
        if cmd[0] == "systemd-run":
            self.assertIn("MemoryMax=2048M", cmd)
            self.assertEqual(cmd[-2:], ["prog", "run"])
        else:
            self.assertEqual(cmd, ["prog", "run"])
        self.assertEqual(runner.cgroup_command(None, ["prog"]), ["prog"])


class Writer(unittest.TestCase):
    def test_what_is_done_is_kept_and_can_be_resumed(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "run.json"
            w = runner.RunWriter(path, {"schema": "x", "label": "a"})
            w.add({"scenario": "s", "dataset": "d", "mode": "auto", "pass": 1, "status": "ok"})
            w.add({"scenario": "t", "dataset": "d", "mode": "auto", "pass": 1, "status": "error"})
            saved = json.loads(path.read_text())
            self.assertFalse(saved["complete"])
            self.assertEqual(saved["summary"], {"ok": 1, "error": 1, "total": 2})
            again = runner.RunWriter(path, {"schema": "x"})
            again.load_existing()
            self.assertTrue(again.has("s", "d", "auto", 1))
            self.assertFalse(again.has("s", "d", "auto", 2))
            w.save(complete=True)
            self.assertTrue(json.loads(path.read_text())["complete"])


    def test_a_finished_run_can_be_added_to_and_says_so(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "run.json"
            w = runner.RunWriter(path, {"schema": "x", "label": "a", "system": {"old": 1}, "method": {"profile": "standard"}})
            w.add({"scenario": "s", "dataset": "d", "mode": "auto", "pass": 1, "status": "ok"})
            w.save(complete=True)
            again = runner.RunWriter(path, {"schema": "x", "label": "a", "system": {"new": 1},
                                            "method": {"profile": "standard", "filters": {"only": "cancel"}},
                                            "harness": {"source_hash": "h2"}})
            again.load_existing(keep_header=True)
            self.assertEqual(again.header["system"], {"old": 1}, "the machine it was measured on is kept")
            self.assertEqual(again.header["extensions"][0]["harness"], {"source_hash": "h2"})
            self.assertEqual(again.header["extensions"][0]["method"]["filters"], {"only": "cancel"})
            self.assertIn("added_utc", again.header["extensions"][0])
            self.assertTrue(again.has("s", "d", "auto", 1))
            again.add({"scenario": "t", "dataset": "d", "mode": "auto", "pass": 1, "status": "ok"})
            again.save(complete=True)
            saved = json.loads(path.read_text())
            self.assertEqual(saved["summary"]["total"], 2)
            self.assertEqual(len(saved["extensions"]), 1)


class Scrub(unittest.TestCase):
    def test_paths_of_this_machine_are_not_kept(self):
        from perflib.paths import work_dir

        home = str(Path.home())
        record = {"error": f"opening {work_dir()}/data/x.json failed; see {home}/notes",
                  "notes": [f"{home}/a"], "n": 3, "nested": {"p": f"{work_dir()}"}}
        out = runner.scrub(record)
        self.assertEqual(out["error"], "opening $JQ_PERF_WORK/data/x.json failed; see ~/notes")
        self.assertEqual(out["notes"], ["~/a"])
        self.assertEqual(out["nested"]["p"], "$JQ_PERF_WORK")
        self.assertEqual(out["n"], 3)
        self.assertEqual(runner.scrub({"t": 13.163021999999999, "xs": [0.1 + 0.2]}), {"t": 13.163022, "xs": [0.3]})


class Formatting(unittest.TestCase):
    def test_times_are_in_the_unit_a_person_reads(self):
        self.assertEqual(report.fmt_ms(0.0004), "400 ns")
        self.assertEqual(report.fmt_ms(0.052), "52 µs")
        self.assertEqual(report.fmt_ms(3.456), "3.46 ms")
        self.assertEqual(report.fmt_ms(120.4), "120 ms")
        self.assertEqual(report.fmt_ms(1234), "1.23 s")
        self.assertEqual(report.fmt_ms(35_000), "35.0 s")

    def test_changes(self):
        self.assertEqual(report.fmt_change(0.5, "faster"), "**2.0× faster**")
        self.assertEqual(report.fmt_change(1 / 1870, "faster"), "**1,870× faster**")
        self.assertEqual(report.fmt_change(0.08, "faster"), "**12× faster**")
        self.assertEqual(report.fmt_mem_change(1 / 6330, "lighter"), "6,330× less")
        self.assertEqual(report.fmt_mem_change(3.0, "heavier"), "3.0× more")
        self.assertEqual(report.fmt_change(1.3, "slower"), "1.30× slower")
        self.assertEqual(report.fmt_change(1.02, "same"), "≈")

    def test_sizes(self):
        self.assertEqual(report.fmt_size(68), "68 B")
        self.assertEqual(report.fmt_size(300 * 1024 * 1024), "300.0 MiB")
        self.assertEqual(report.fmt_mib(2048 * 1024), "2.0 GiB")


class PlanCheck(unittest.TestCase):
    def test_ids_in_backticks_are_found_and_prose_is_not(self):
        text = "Use `load.open` and `query.jq.*`; the file `jq-perf` and `Document::load` are not ids, nor is `x.y`."
        self.assertEqual(plancheck.mentioned(text, {"load", "query"}), {"load.open"})

    def test_what_is_missing_or_unknown_is_said(self):
        old = plancheck.PLAN
        with tempfile.TemporaryDirectory() as tmp:
            plancheck.PLAN = Path(tmp) / "PLAN.md"
            plancheck.PLAN.write_text("`load.open` `load.gone`")
            try:
                problems = plancheck.check([scenario("load.open"), scenario("load.new")])
            finally:
                plancheck.PLAN = old
        self.assertEqual(len(problems), 2)
        self.assertTrue(any("load.new" in p for p in problems) and any("load.gone" in p for p in problems))


if __name__ == "__main__":
    unittest.main()


class JsonIo(unittest.TestCase):
    def test_a_long_list_is_one_item_to_a_line_and_reads_back_the_same(self):
        from perflib import jsonio

        doc = {"schema": "x", "label": "é", "system": {"a": [1, 2]},
               "results": [{"scenario": "s", "samples_ms": [1.5, 2.5], "n": 1}, {"scenario": "t", "samples_ms": [], "n": 2}]}
        text = jsonio.dumps(doc, "results")
        self.assertEqual(json.loads(text), doc)
        self.assertEqual(sum(1 for line in text.splitlines() if '"scenario"' in line), 2)
        self.assertTrue(text.index('"results"') > text.index('"system"'), "the list is written last")
        self.assertEqual(json.loads(jsonio.dumps({"a": 1, "results": []}, "results")), {"a": 1, "results": []})
