#!/usr/bin/env python3
"""
Debug tool for testing Prolog files for performance issues.
Run this to diagnose why a Prolog file is timing out.
"""

import subprocess
import time
import sys
import os


def test_prolog_file(pl_file: str):
    """Test a Prolog file for performance issues."""

    if not os.path.exists(pl_file):
        print(f"Error: File '{pl_file}' not found!")
        return

    print(f"\n{'=' * 60}")
    print(f"Testing Prolog file: {pl_file}")
    print(f"{'=' * 60}\n")

    tests = [
        ("Load file", "halt"),
        ("Initial state", "initial_state(S), write(S), halt"),
        ("Current player", "initial_state(S), current_player(S, P), write(P), halt"),
        ("First legal move", "initial_state(S), legal_move(S, M), write(M), halt"),
        ("Count legal moves",
         "initial_state(S), findall(M, legal_move(S, M), Moves), length(Moves, L), write(L), halt"),
        ("Apply first move", "initial_state(S), legal_move(S, M), apply_move(S, M, New), write(New), halt"),
        ("Game over check", "initial_state(S), game_over(S, W), write(W), halt"),
        ("Render state", "initial_state(S), render_state(S), halt"),
    ]

    results = []

    for test_name, goal in tests:
        print(f"Testing: {test_name}...", end=" ", flush=True)
        start = time.time()

        try:
            result = subprocess.run(
                ["swipl", "-g", f"consult('{pl_file}'), {goal}", "-t", "halt(1)"],
                capture_output=True,
                text=True,
                timeout=30  # 30 seconds timeout per test
            )
            elapsed = time.time() - start

            if result.returncode == 0:
                print(f"✓ ({elapsed:.2f}s)")
                if result.stdout and result.stdout.strip():
                    output_preview = result.stdout.strip()[:200]
                    print(f"    Output: {output_preview}")
                results.append((test_name, True, elapsed, result.stdout))
            else:
                print(f"✗ ({elapsed:.2f}s)")
                if result.stderr:
                    error_preview = result.stderr.strip()[:200]
                    print(f"    Error: {error_preview}")
                results.append((test_name, False, elapsed, result.stderr))

        except subprocess.TimeoutExpired:
            elapsed = time.time() - start
            print(f"✗ TIMEOUT (>{30:.0f}s)")
            results.append((test_name, False, elapsed, "Timeout"))
        except Exception as e:
            elapsed = time.time() - start
            print(f"✗ ERROR ({elapsed:.2f}s)")
            print(f"    Exception: {str(e)}")
            results.append((test_name, False, elapsed, str(e)))

    # Print summary
    print(f"\n{'=' * 60}")
    print("SUMMARY")
    print(f"{'=' * 60}")
    passed = sum(1 for _, success, _, _ in results if success)
    print(f"Passed: {passed}/{len(results)} tests")

    failed_tests = [(name, err) for name, success, _, err in results if not success]
    if failed_tests:
        print(f"\nFailed tests:")
        for name, err in failed_tests:
            print(f"  - {name}: {err[:100]}")

    return results


def main():
    """Main function to run the debugger."""
    if len(sys.argv) > 1:
        # Use the provided file path
        pl_file = sys.argv[1]
    else:
        # Default to the most recent checkers file
        default_file = "prolog/standard_checkers.pl"
        if os.path.exists(default_file):
            pl_file = default_file
            print(f"No file specified. Testing default: {pl_file}")
        else:
            # List available Prolog files
            prolog_dir = "prolog"
            if os.path.exists(prolog_dir):
                files = [f for f in os.listdir(prolog_dir) if f.endswith('.pl')]
                if files:
                    print("Available Prolog files:")
                    for i, f in enumerate(files):
                        print(f"  [{i + 1}] {f}")
                    choice = input(f"\nSelect a file (1-{len(files)}): ")
                    try:
                        pl_file = os.path.join(prolog_dir, files[int(choice) - 1])
                    except:
                        print("Invalid choice. Exiting.")
                        return
                else:
                    print("No .pl files found in 'prolog' directory.")
                    return
            else:
                print("Usage: python debug_prolog.py <path_to_prolog_file>")
                return

    test_prolog_file(pl_file)


if __name__ == "__main__":
    main()