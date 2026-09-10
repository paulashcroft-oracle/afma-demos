import argparse
import csv
import hashlib
import json
from collections import Counter
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description="Profile a CAAB CSV into a new task-owned JSON file.")
    parser.add_argument("csv_path", type=Path)
    parser.add_argument("profile_path", type=Path)
    args = parser.parse_args()
    with args.csv_path.open("rb") as handle:
        sha256 = hashlib.sha256(handle.read()).hexdigest()

    with args.csv_path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        headers = reader.fieldnames or []
        rows = list(reader)

    max_lengths = {header: 0 for header in headers}
    blank_counts = {header: 0 for header in headers}
    counters = {
        "KINGDOM": Counter(),
        "CLASS": Counter(),
        "RANK": Counter(),
        "HABITAT_CODE": Counter(),
        "LIST_STATUS_CODE": Counter(),
        "NON_CURRENT_FLAG": Counter(),
        "DATE_EXTRACTED": Counter(),
    }
    spcodes = []

    for row in rows:
        spcodes.append(row.get("SPCODE", "").strip())
        for header in headers:
            value = row.get(header, "")
            max_lengths[header] = max(max_lengths[header], len(value))
            if not value.strip():
                blank_counts[header] += 1
        for column, counter in counters.items():
            counter[row.get(column, "")] += 1

    profile = {
        "csvPath": str(args.csv_path),
        "sha256": sha256,
        "rows": len(rows),
        "columns": headers,
        "duplicateSpcode": len(spcodes) - len(set(spcodes)),
        "blankSpcode": sum(1 for value in spcodes if not value),
        "maxLengths": max_lengths,
        "blankCounts": blank_counts,
        "topValues": {
            column: dict(counter.most_common(20))
            for column, counter in counters.items()
        },
        "sampleRows": rows[:5],
    }

    with args.profile_path.open("x", encoding="utf-8") as handle:
        handle.write(json.dumps(profile, indent=2))
    print(json.dumps({
        "rows": profile["rows"],
        "duplicateSpcode": profile["duplicateSpcode"],
        "blankSpcode": profile["blankSpcode"],
        "sha256": sha256,
    }, indent=2))


if __name__ == "__main__":
    main()
