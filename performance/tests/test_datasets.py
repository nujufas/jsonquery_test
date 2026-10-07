import json
import re
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))

from perflib import datasets  # noqa: E402


def small(kind, mib=0.05):
    return datasets.Spec(f"t-{kind}", kind, int(mib * datasets.MIB), 1, "test")


class Generators(unittest.TestCase):
    def make(self, spec):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        meta = datasets.ensure(Path(tmp.name), spec)
        text = (Path(tmp.name) / f"{spec.id}.json").read_text()
        return meta, text

    def test_every_kind_makes_the_json_it_says(self):
        meta, text = self.make(small("records"))
        data = json.loads(text)
        self.assertEqual(len(data), meta["count"])
        self.assertEqual(data[meta["mid"]]["name"], meta["mid_name"])
        self.assertEqual(set(data[0]), set(meta["fields"]))

        meta, text = self.make(small("ndjson"))
        lines = text.splitlines()
        self.assertEqual(len(lines), meta["count"])
        self.assertEqual(json.loads(lines[meta["mid"]])["name"], meta["mid_name"])

        meta, text = self.make(small("wide"))
        data = json.loads(text)
        self.assertEqual(len(data), meta["members"])
        self.assertIn(meta["mid_key"], data)
        self.assertIn(meta["last_key"], data)

        meta, text = self.make(small("strings", 0.5))
        data = json.loads(text)
        self.assertEqual(len(data), meta["count"])
        self.assertIn(meta["needle"], data[meta["needle_index"]])
        self.assertEqual(sum(meta["needle"] in s for s in data), 1, "the needle is in one string")
        self.assertTrue(any("\n" in s for s in data), "some strings have escapes")

        meta, text = self.make(small("numbers"))
        data = json.loads(text)
        self.assertEqual(len(data), meta["count"])
        self.assertTrue(any(isinstance(x, float) for x in data) and any(isinstance(x, int) for x in data))

        meta, text = self.make(small("nested", 0.4))
        data = json.loads(text)
        categories = data["catalog"]["categories"]
        self.assertEqual(len(categories), meta["categories"])
        self.assertGreaterEqual(len(categories), 4, "the queries look at category 3")
        self.assertGreaterEqual(len(categories[3]["products"]), 11, "and its product 10")
        sku = meta["sku_mid"]
        found = [p for c in categories for p in c["products"] if p["sku"] == sku]
        self.assertEqual(len(found), 1)

    def test_the_same_bytes_every_time(self):
        a, _ = self.make(small("records"))
        b, _ = self.make(small("records"))
        self.assertEqual(a["sha256"], b["sha256"])

    def test_the_absent_text_is_nowhere(self):
        for kind in ("records", "wide", "numbers"):
            meta, text = self.make(small(kind))
            self.assertNotIn(meta["absent"], text)

    def test_a_dataset_is_made_again_when_its_file_is_not_the_one_in_the_sidecar(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        spec = small("records")
        datasets.ensure(Path(tmp.name), spec)
        self.assertTrue(datasets.is_current(Path(tmp.name), spec))
        (Path(tmp.name) / f"{spec.id}.json").write_text("[]")
        self.assertFalse(datasets.is_current(Path(tmp.name), spec))
        self.assertGreater(datasets.ensure(Path(tmp.name), spec)["bytes"], 1000)


class Profiles(unittest.TestCase):
    def test_every_profile_names_datasets_that_exist(self):
        for name, entries in datasets.PROFILES.items():
            for dataset_id, mode in entries:
                self.assertIn(dataset_id, datasets.SPECS, name)
                self.assertIn(mode, ("auto", "parsed", "lazy"), name)

    def test_the_big_datasets_are_past_the_size_at_which_a_file_is_kept_on_disk(self):
        for dataset_id in ("rec-300m", "nd-300m", "obj-300m", "str-300m", "num-300m", "tree-300m", "rec-1g"):
            self.assertGreaterEqual(datasets.SPECS[dataset_id].target_bytes, 256 * datasets.MIB)
        for dataset_id in ("rec-100m", "tree-100m", "rec-16m"):
            self.assertLess(datasets.SPECS[dataset_id].target_bytes, 256 * datasets.MIB)


class MetaKeysAreMade(unittest.TestCase):
    def test_every_key_a_scenario_reads_from_a_sidecar_is_written_by_a_generator(self):
        keys = set()
        for path in (HERE.parent / "bench" / "src").rglob("*.rs"):
            keys |= set(re.findall(r'\b(?:meta|m|ctx\.meta)\.(?:u|s)\("([a-z_]+)"\)', path.read_text()))
        keys -= {"kind", "id"}
        written = set()
        for kind in datasets.GENERATORS:
            tmp = tempfile.TemporaryDirectory()
            self.addCleanup(tmp.cleanup)
            written |= set(datasets.ensure(Path(tmp.name), small(kind, 0.4)))
        self.assertTrue(keys, "the pattern found no keys: has the code changed?")
        self.assertEqual(keys - written, set())


if __name__ == "__main__":
    unittest.main()
