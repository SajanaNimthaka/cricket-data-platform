import json
from pathlib import Path

path = Path("data/raw/lpl_json/1238752.json")
data = json.loads(path.read_text(encoding="utf-8"))

print("Top-level keys:", list(data.keys()))
print("Info keys:", list(data["info"].keys()))
print("Number of innings:", len(data["innings"]))
print("First innings keys:", list(data["innings"][0].keys()))
print("First over:", data["innings"][0]["overs"][0])