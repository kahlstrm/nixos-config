#!/usr/bin/env python3

import argparse
import json
import math
import random
import re
import signal
import subprocess
import time
from contextlib import ExitStack
from pathlib import Path


PING_RE = re.compile(r"^\[(?P<time>[0-9.]+)] .*icmp_seq=(?P<seq>[0-9]+).*time[=<](?P<latency>[0-9.]+) ms")
TARGETS = ("10.1.1.1", "192.168.100.1", "1.1.1.1", "8.8.8.8")


def percentile(values, quantile):
    if not values:
        return None
    ordered = sorted(values)
    position = (len(ordered) - 1) * quantile
    lower = math.floor(position)
    upper = math.ceil(position)
    if lower == upper:
        return ordered[lower]
    return ordered[lower] * (upper - position) + ordered[upper] * (position - lower)


def latency_stats(samples, start, end):
    selected = [(timestamp, latency) for timestamp, latency, _ in samples if start <= timestamp <= end]
    values = [latency for _, latency in selected]
    return {
        "samples": len(values),
        "median_ms": percentile(values, 0.5),
        "p95_ms": percentile(values, 0.95),
        "p99_ms": percentile(values, 0.99),
        "max_ms": max(values) if values else None,
    }


def parse_ping(path):
    samples = []
    for line in path.read_text(errors="replace").splitlines():
        match = PING_RE.match(line)
        if match:
            samples.append(
                (
                    float(match.group("time")),
                    float(match.group("latency")),
                    int(match.group("seq")),
                )
            )
    return samples


def iperf_result(path, direction):
    result = json.loads(path.read_text())
    section = result["end"]["sum_received"]
    return {
        f"{direction}_mbps": section["bits_per_second"] / 1_000_000,
        f"{direction}_bytes": section["bytes"],
    }


def terminate(process):
    if process.poll() is None:
        process.send_signal(signal.SIGINT)
        try:
            process.wait(timeout=3)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()


def run_trial(args, root, number, mode="both", directory_name=None):
    started = time.time()
    directory_name = directory_name or f"{number:03d}-{time.strftime('%Y%m%d-%H%M%S')}"
    trial = root / directory_name
    trial.mkdir()
    ping_processes = {}
    ping_files = {}
    for target in TARGETS:
        output = (trial / f"{target}.ping").open("w")
        ping_files[target] = output
        ping_processes[target] = subprocess.Popen(
            ["ping", "-D", "-n", "-i", "0.2", target],
            stdout=output,
            stderr=subprocess.STDOUT,
            text=True,
        )

    try:
        time.sleep(args.idle_seconds)
        load_start = time.time()
        commands = {
            "download": [args.iperf, "-c", args.host, "-p", "5201", "-P", "4", "-R", "-t", str(args.load_seconds), "-J"],
            "upload": [args.iperf, "-c", args.host, "-p", "5202", "-P", "4", "-t", str(args.load_seconds), "-J"],
        }
        directions = commands if mode == "both" else {mode: commands[mode]}
        with ExitStack() as stack:
            processes = {
                direction: subprocess.Popen(
                    command,
                    stdout=stack.enter_context((trial / f"{direction}.json").open("w")),
                    stderr=stack.enter_context((trial / f"{direction}.stderr").open("w")),
                )
                for direction, command in directions.items()
            }
            return_codes = {direction: process.wait() for direction, process in processes.items()}
        load_end = time.time()
        time.sleep(args.idle_seconds)
    finally:
        for process in ping_processes.values():
            terminate(process)
        for output in ping_files.values():
            output.close()

    ended = time.time()
    if any(return_code != 0 for return_code in return_codes.values()):
        raise RuntimeError(f"iperf3 failed with exit codes {return_codes}")

    throughput = {}
    for direction in directions:
        throughput |= iperf_result(trial / f"{direction}.json", direction)
    latency = {}
    for target in TARGETS:
        samples = parse_ping(trial / f"{target}.ping")
        before = latency_stats(samples, started + 2, load_start - 1)
        loaded = latency_stats(samples, load_start + 5, load_end - 2)
        after = latency_stats(samples, load_end + 1, ended - 2)
        idle_values = [
            latency_value
            for timestamp, latency_value, _ in samples
            if started + 2 <= timestamp <= load_start - 1 or load_end + 1 <= timestamp <= ended - 2
        ]
        idle = {
            "samples": len(idle_values),
            "median_ms": percentile(idle_values, 0.5),
            "p95_ms": percentile(idle_values, 0.95),
            "p99_ms": percentile(idle_values, 0.99),
            "max_ms": max(idle_values) if idle_values else None,
        }
        received_sequences = [sequence for _, _, sequence in samples]
        sent = max(received_sequences) - min(received_sequences) + 1 if received_sequences else 0
        loss_percent = 100 * (sent - len(received_sequences)) / sent if sent else None
        latency[target] = {
            "before": before,
            "loaded": loaded,
            "after": after,
            "idle": idle,
            "loaded_minus_idle_p95_ms": loaded["p95_ms"] - idle["p95_ms"],
            "sent": sent,
            "received": len(received_sequences),
            "loss_percent": loss_percent,
        }

    internet_delta = max(latency[target]["loaded_minus_idle_p95_ms"] for target in ("1.1.1.1", "8.8.8.8"))
    reasons = []
    if throughput.get("download_mbps", math.inf) < args.minimum_download_mbps:
        reasons.append("download_capacity")
    if throughput.get("upload_mbps", math.inf) < args.minimum_upload_mbps:
        reasons.append("upload_capacity")
    if internet_delta > args.maximum_latency_delta_ms:
        reasons.append("loaded_latency")

    measurement = {
        "trial": number,
        "mode": mode,
        "started": started,
        "ended": ended,
        "load_started": load_start,
        "load_ended": load_end,
        **throughput,
        "latency": latency,
        "drop": bool(reasons),
        "drop_reasons": reasons,
    }
    (trial / "measurement.json").write_text(json.dumps(measurement, indent=2) + "\n")
    return measurement


def diagnostic_summary(measurement):
    return {
        key: measurement[key]
        for key in (
            "trial",
            "mode",
            "started",
            "download_mbps",
            "download_bytes",
            "upload_mbps",
            "upload_bytes",
            "drop",
            "drop_reasons",
        )
        if key in measurement
    } | {
        "google_loaded_p95_ms": measurement["latency"]["8.8.8.8"]["loaded"]["p95_ms"],
        "google_delta_p95_ms": measurement["latency"]["8.8.8.8"]["loaded_minus_idle_p95_ms"],
    }


def write_summary(root, measurements, failures, diagnostics, diagnostic_failures, args):
    completed = len(measurements)
    drops = [measurement for measurement in measurements if measurement["drop"]]
    summary = {
        "updated": time.time(),
        "configuration": {
            "host": args.host,
            "load_seconds": args.load_seconds,
            "idle_seconds_each_side": args.idle_seconds,
            "interval_seconds": args.interval_seconds,
            "interval_jitter_seconds": args.interval_jitter_seconds,
            "requested_hours": args.hours,
            "minimum_download_mbps": args.minimum_download_mbps,
            "minimum_upload_mbps": args.minimum_upload_mbps,
            "maximum_latency_delta_ms": args.maximum_latency_delta_ms,
            "diagnose_drops": args.diagnose_drops,
        },
        "completed_trials": completed,
        "failed_trials": failures,
        "diagnostic_trials": len(diagnostics),
        "failed_diagnostic_trials": diagnostic_failures,
        "drop_trials": len(drops),
        "drop_fraction": len(drops) / completed if completed else None,
        "download_mbps": {
            "minimum": min((m["download_mbps"] for m in measurements), default=None),
            "median": percentile([m["download_mbps"] for m in measurements], 0.5),
            "p10": percentile([m["download_mbps"] for m in measurements], 0.1),
        },
        "upload_mbps": {
            "minimum": min((m["upload_mbps"] for m in measurements), default=None),
            "median": percentile([m["upload_mbps"] for m in measurements], 0.5),
            "p10": percentile([m["upload_mbps"] for m in measurements], 0.1),
        },
        "transferred_bytes": sum(m["download_bytes"] + m["upload_bytes"] for m in measurements),
        "diagnostic_transferred_bytes": sum(
            m.get("download_bytes", 0) + m.get("upload_bytes", 0) for m in diagnostics
        ),
        "drops": [
            {
                "trial": m["trial"],
                "started": m["started"],
                "download_mbps": m["download_mbps"],
                "upload_mbps": m["upload_mbps"],
                "reasons": m["drop_reasons"],
                "google_loaded_p95_ms": m["latency"]["8.8.8.8"]["loaded"]["p95_ms"],
                "google_delta_p95_ms": m["latency"]["8.8.8.8"]["loaded_minus_idle_p95_ms"],
            }
            for m in drops
        ],
        "diagnostics": [diagnostic_summary(measurement) for measurement in diagnostics],
    }
    (root / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--iperf", default="iperf3")
    parser.add_argument("--host", required=True)
    parser.add_argument("--hours", type=float, default=12)
    parser.add_argument("--interval-seconds", type=int, default=900)
    parser.add_argument("--interval-jitter-seconds", type=int, default=0)
    parser.add_argument("--load-seconds", type=int, default=30)
    parser.add_argument("--idle-seconds", type=int, default=15)
    parser.add_argument("--minimum-download-mbps", type=float, default=840)
    parser.add_argument("--minimum-upload-mbps", type=float, default=75)
    parser.add_argument("--maximum-latency-delta-ms", type=float, default=20)
    parser.add_argument("--diagnose-drops", action="store_true")
    args = parser.parse_args()

    if args.interval_jitter_seconds < 0 or args.interval_jitter_seconds >= args.interval_seconds:
        parser.error("interval jitter must be non-negative and shorter than the interval")

    args.output.mkdir(parents=True)
    (args.output / "config.json").write_text(json.dumps(vars(args) | {"output": str(args.output)}, indent=2) + "\n")
    deadline = time.monotonic() + args.hours * 3600
    measurements = []
    diagnostics = []
    failures = 0
    diagnostic_failures = 0
    number = 1
    while time.monotonic() < deadline:
        cycle_started = time.monotonic()
        try:
            measurement = run_trial(args, args.output, number)
            measurements.append(measurement)
            print(json.dumps({key: measurement[key] for key in ("trial", "download_mbps", "upload_mbps", "drop", "drop_reasons")}), flush=True)
            if measurement["drop"] and args.diagnose_drops:
                diagnostic_root = args.output / "diagnostics"
                diagnostic_root.mkdir(exist_ok=True)
                modes = ("upload", "download", "both") if number % 2 else ("download", "upload", "both")
                for sequence, mode in enumerate(modes, start=1):
                    try:
                        diagnostic = run_trial(
                            args,
                            diagnostic_root,
                            number,
                            mode=mode,
                            directory_name=f"{number:03d}-{sequence}-{mode}-{time.strftime('%Y%m%d-%H%M%S')}",
                        )
                        diagnostics.append(diagnostic)
                        print(json.dumps({"diagnostic_for": number, **diagnostic_summary(diagnostic)}), flush=True)
                    except Exception as error:
                        diagnostic_failures += 1
                        print(json.dumps({"diagnostic_for": number, "mode": mode, "error": str(error)}), flush=True)
        except Exception as error:
            failures += 1
            print(json.dumps({"trial": number, "error": str(error)}), flush=True)
        write_summary(args.output, measurements, failures, diagnostics, diagnostic_failures, args)
        number += 1
        interval = random.SystemRandom().uniform(
            args.interval_seconds - args.interval_jitter_seconds,
            args.interval_seconds + args.interval_jitter_seconds,
        )
        remaining = interval - (time.monotonic() - cycle_started)
        if remaining > 0 and time.monotonic() + remaining < deadline:
            time.sleep(remaining)
        else:
            break


if __name__ == "__main__":
    main()
