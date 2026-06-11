"""
test_generator.py
-----------------
Generate and run a suite of behavioural tests for a Prolog game file.

The LLM reads the game XML and produces a list of test cases, each of
which is a SWI-Prolog goal that must succeed.  The runner executes every
goal in a fresh swipl session and reports pass / fail with diagnostics.

Public API
----------
generate_tests(xml_str)       -> list[dict]   # each dict: {name, goal, description}
run_tests(pl_file, test_cases) -> list[dict]  # each dict: {name, passed, error}
generate_and_run(xml_str, pl_file) -> tuple[list[dict], list[dict]]
"""

import config
import subprocess

from ollama import Client
from openai import OpenAI

# ================================================================
# Module-level client singletons (same pattern as rule_generator)
# ================================================================
_ollama_client: Client | None = None
_openai_client: OpenAI | None = None


def _get_ollama() -> Client:
    global _ollama_client
    if _ollama_client is None:
        _ollama_client = Client()
    return _ollama_client


def _get_openai() -> OpenAI:
    global _openai_client
    if _openai_client is None:
        if not config.OPENAI_API_KEY:
            raise RuntimeError("OPENAI_API_KEY is not set.")
        _openai_client = OpenAI(api_key=config.OPENAI_API_KEY)
    return _openai_client


def _llm(model: str, messages: list[dict], is_openai: bool = False) -> str:
    if is_openai:
        resp = _get_openai().chat.completions.create(model=model, messages=messages)
        return resp.choices[0].message.content
    return _get_ollama().chat(model, messages=messages).message.content


# ================================================================
# System prompt
# ================================================================
_SYSTEM_TEST_GENERATOR = """\
You are a SWI-Prolog test engineer. Given a game specification in XML and \
the required predicate signatures, you generate a test suite that exercises \
the game's logic.

OUTPUT FORMAT — output ONLY a numbered list, one test per line, in this exact format:
  N. NAME | GOAL | DESCRIPTION

Rules:
- NAME  : short snake_case label, no spaces (e.g. initial_state_succeeds)
- GOAL  : a valid SWI-Prolog goal that MUST SUCCEED for the test to pass.
          The goal may use: initial_state/1, current_player/2, legal_move/2,
          apply_move/3, game_over/2, and standard library predicates.
          Do NOT use write/1 or format/2 — goals must be purely logical.
- DESCRIPTION : one plain-English sentence describing what the test checks.

Separate NAME, GOAL, and DESCRIPTION with a pipe character ( | ).

Example line:
  1. initial_state_succeeds | initial_state(_) | initial_state/1 produces at least one solution.

Generate between 6 and 12 tests covering:
  - initial_state/1 produces a valid state
  - current_player/2 returns a known player from the initial state
  - legal_move/2 generates at least one move from the initial state
  - apply_move/3 succeeds on the first legal move
  - apply_move/3 produces a different state than the input
  - game_over/2 does NOT hold on the initial state
  - any game-specific invariants you can derive from the XML spec
    (e.g. board size, player alternation, win-condition reachability)

Do not add any text outside the numbered list.
"""


# ================================================================
# Internal helpers
# ================================================================
def _parse_test_list(raw: str) -> list[dict]:
    """
    Parse the LLM's numbered-list output into structured dicts.
    Silently skips malformed lines.
    """
    tests: list[dict] = []
    for line in raw.strip().splitlines():
        line = line.strip()
        if not line:
            continue
        # Strip leading "N. " or "N) "
        if line[0].isdigit():
            dot = line.find(".")
            paren = line.find(")")
            cut = min(x for x in (dot, paren) if x != -1) if (dot != -1 or paren != -1) else -1
            if cut != -1:
                line = line[cut + 1:].strip()

        parts = [p.strip() for p in line.split("|")]
        if len(parts) != 3:
            print(f"  [test_generator] skipping malformed line: {line!r}")
            continue
        name, goal, description = parts
        if name and goal and description:
            tests.append({"name": name, "goal": goal, "description": description})

    return tests


def _run_single_test(pl_file: str, goal: str) -> tuple[bool, str]:
    """
    Run *goal* against *pl_file* in a fresh swipl session.
    Returns (passed, error_message).
    """
    safe_path = pl_file.replace("\\", "/")
    full_goal = f"consult('{safe_path}'), ({goal} -> halt(0) ; halt(1))"
    try:
        r = subprocess.run(
            ["swipl", "-g", full_goal, "-t", "halt(1)"],
            capture_output=True,
            text=True,
            timeout=config.SWIPL_TIMEOUT,
        )
        if r.returncode == 0:
            return True, ""
        # returncode 1 can mean goal failed OR swipl error
        stderr = r.stderr.strip()
        return False, stderr if stderr else "Goal failed (returned false)."
    except subprocess.TimeoutExpired:
        return False, f"Timed out after {config.SWIPL_TIMEOUT}s."
    except FileNotFoundError:
        return False, "swipl not found on PATH."


# ================================================================
# Public endpoints
# ================================================================
def generate_tests(xml_str: str) -> list[dict]:
    """
    Ask the LLM to produce a test suite for the game described in *xml_str*.
    Returns a list of dicts: {name: str, goal: str, description: str}.
    Returns an empty list if parsing fails entirely.
    """
    messages = [
        {"role": "system", "content": _SYSTEM_TEST_GENERATOR},
        {
            "role": "user",
            "content": (
                "Generate tests for the following game specification:\n\n" + xml_str
            ),
        },
    ]
    raw = _llm(config.MODEL_TEST_GENERATOR, messages, is_openai=config.USE_OPENAI_FOR_TEST_GENERATOR)
    tests = _parse_test_list(raw)
    print(f"  [test_generator] parsed {len(tests)} test(s).")
    return tests


def run_tests(pl_file: str, test_cases: list[dict]) -> list[dict]:
    """
    Run each test case in *test_cases* against *pl_file*.
    Returns a list of result dicts:
      {name, goal, description, passed, error}
    """
    results: list[dict] = []
    for tc in test_cases:
        passed, error = _run_single_test(pl_file, tc["goal"])
        results.append(
            {
                "name":        tc["name"],
                "goal":        tc["goal"],
                "description": tc["description"],
                "passed":      passed,
                "error":       error,
            }
        )
        status = "✓" if passed else "✗"
        print(f"  [{status}] {tc['name']}")
    return results


def generate_and_run(xml_str: str, pl_file: str) -> tuple[list[dict], list[dict]]:
    """
    Convenience wrapper: generate tests from *xml_str* then run them against *pl_file*.
    Returns (test_cases, results).
    """
    test_cases = generate_tests(xml_str)
    if not test_cases:
        return [], []
    results = run_tests(pl_file, test_cases)
    return test_cases, results