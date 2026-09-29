"""Check that the active MoonBit compiler meets the repository minimum."""
from __future__ import annotations
import argparse
import re
import subprocess
import sys

def parse_version(text: str) -> tuple[int, int, int] | None:
    match = re.search(r"(?:^|\s)v(\d+)\.(\d+)\.(\d+)", text)
    return tuple(int(part) for part in match.groups()) if match else None

parser = argparse.ArgumentParser()
parser.add_argument("--minimum", default="0.10.14")
args = parser.parse_args()
minimum = tuple(int(part) for part in args.minimum.split("."))
result = subprocess.run(["moonc", "-v"], capture_output=True, text=True)
output = (result.stdout + "\n" + result.stderr).strip()
actual = parse_version(output)
if actual is None:
    print("Unable to parse moonc version:", output, file=sys.stderr)
    raise SystemExit(1)
if actual < minimum:
    print(f"moonc {actual} is below required {minimum}", file=sys.stderr)
    raise SystemExit(1)
print(f"moonc {actual[0]}.{actual[1]}.{actual[2]} meets minimum {args.minimum}")
