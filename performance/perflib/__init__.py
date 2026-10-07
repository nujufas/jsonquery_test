"""The tooling of the performance suite (see ../README.md): builds the harness against a revision of
the app, makes the datasets, runs the scenarios, keeps the results and compares them. Standard
library only."""

#: What the JSON files this writes are called, and which version of their layout this is.
SCHEMA = "jsonquery-perf/1"


def say(text: str = "") -> None:
    """Print a line of progress at once (a log that is a file is otherwise written in blocks)."""
    print(text, flush=True)
