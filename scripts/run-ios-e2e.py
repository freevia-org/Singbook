#!/usr/bin/env python3
"""Run iOS device tests serially and capture their named screenshot checkpoints."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--device", required=True, help="Dedicated iOS simulator UUID")
parser.add_argument("--output", required=True, type=Path, help="New evidence directory")
parser.add_argument("--flutter", default=shutil.which("flutter"))
parser.add_argument("--defines", type=Path, help="Optional local build defines JSON")
parser.add_argument("--test-name", help="Run only the named Flutter test (plain-name filter)")
parser.add_argument("tests", nargs="*", help="Test paths; defaults to all iOS-compatible suites")
args = parser.parse_args()
if not args.flutter:
    parser.error("Add Flutter to PATH or pass --flutter")
root = Path(__file__).resolve().parent.parent
os.chdir(root)
devices = subprocess.run(
    ["xcrun", "simctl", "list", "devices", "--json"],
    capture_output=True, text=True, check=True, timeout=30,
)
device = next((item for group in json.loads(devices.stdout)["devices"].values()
               for item in group if item["udid"] == args.device), None)
if not device or not device.get("isAvailable") or device.get("state") != "Booted":
    parser.error("The target must be an available, booted iOS test simulator")
args.output.mkdir(parents=True, exist_ok=False)
tests = args.tests or ["integration_test/ios_full_device_test.dart"]
summary = []
for test in tests:
    name = Path(test).stem
    command = [args.flutter, "test", test, "-d", args.device,
               "--no-uninstall", "--reporter", "expanded"]
    if args.test_name:
        command.extend(["--plain-name", args.test_name])
    if args.defines:
        command.append(f"--dart-define-from-file={args.defines}")
    started = time.monotonic()
    captures = []
    skipped = []
    completed_successfully = False
    print(f"Running {test}", flush=True)
    with (args.output / f"{name}.log").open("w") as log:
        process = subprocess.Popen(command, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT, text=True, bufsize=1)
        try:
            for line in process.stdout:
                log.write(line)
                log.flush()
                if "All tests passed!" in line:
                    completed_successfully = True
                if "SKIP" in line or "skipped" in line.lower():
                    skipped.append(line.strip())
                native = re.search(r"SINGBOOK_E2E_NATIVE_CAPTURE:(\d+):([\w-]+)", line)
                if native:
                    image = args.output / f"{name}_{native.group(2)}.png"
                    try:
                        container = subprocess.run(
                            ["xcrun", "simctl", "get_app_container", args.device,
                             "org.freevia.singbook", "data"],
                            capture_output=True, text=True, check=True, timeout=60,
                        )
                        source = (Path(container.stdout.strip()) / "Library" /
                                  "Application Support" / "singbook-e2e-captures" /
                                  native.group(1) / f"{native.group(2)}.png")
                        shutil.copyfile(source, image)
                        with image.open("rb") as captured:
                            valid = captured.read(8) == b"\x89PNG\r\n\x1a\n"
                        captures.append({"file": str(image), "exitCode": 0,
                                         "valid": valid,
                                         "error": "" if valid else "Invalid PNG signature"})
                    except (OSError, subprocess.SubprocessError) as error:
                        captures.append({"file": str(image), "exitCode": -1,
                                         "valid": False, "error": str(error)})
                marker = re.search(r"SINGBOOK_E2E_CAPTURE:([\w-]+)", line)
                if marker:
                    image = args.output / f"{name}_{marker.group(1)}.png"
                    # The Duo simulator's display 1 is the active app display.
                    try:
                        result = subprocess.run(
                            ["xcrun", "simctl", "io", args.device, "screenshot",
                             "--display=1", str(image)], capture_output=True, text=True,
                            timeout=15,
                        )
                        valid = result.returncode == 0 and image.is_file() and image.stat().st_size > 0
                        captures.append({"file": str(image), "exitCode": result.returncode,
                                         "valid": valid, "error": result.stderr if not valid else ""})
                    except subprocess.TimeoutExpired:
                        captures.append({"file": str(image), "exitCode": -1,
                                         "valid": False, "error": "Screenshot timed out"})
            code = process.wait()
        except BaseException:
            process.terminate()
            process.wait(timeout=30)
            raise
    summary.append({"test": test, "exitCode": code,
                    "completedSuccessfully": completed_successfully,
                    "seconds": round(time.monotonic() - started, 1),
                    "captures": captures, "skipMessages": skipped})
    (args.output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(f"Completed {test}: exit {code}, {len(captures)} screenshots", flush=True)
failed = any(item["exitCode"] or not item["completedSuccessfully"] or any(not c["valid"] for c in item["captures"])
             for item in summary)
raise SystemExit(1 if failed else 0)
