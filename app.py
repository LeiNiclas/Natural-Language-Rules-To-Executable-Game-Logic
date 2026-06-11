import config
import os
import streamlit as st
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(__file__))

import src.pipeline.rule_generator   as rule_gen
import src.pipeline.prolog_generator as prolog_gen
import src.pipeline.test_generator   as test_gen
import src.engine.prolog_engine       as engine


# ---------------------------------------------------------------------------
# Session-state schema
# ---------------------------------------------------------------------------
_STATE_DEFAULTS: dict = {
    "phase":                "input",  # input | preview | playing | game_over
    "pl_file":              None,     # path on disk — only set after Save
    "game_name":            None,
    "xml_str":              None,     # structured XML (kept for tests)
    "prolog_code":          None,     # validated code held in memory until saved
    "state":                None,     # current Prolog state term string
    "legal_moves":          [],
    "move_history":         [],       # list of {player: str, move: str}
    "winner":               None,
    "verification_history": None,
    "prolog_attempts":      None,     # list[dict] from generate_prolog
    "test_cases":           None,
    "test_results":         None,
}


def _init_state() -> None:
    for k, v in _STATE_DEFAULTS.items():
        if k not in st.session_state:
            st.session_state[k] = v


def _reset_state() -> None:
    for key in list(_STATE_DEFAULTS.keys()) + ["chosen_move"]:
        st.session_state.pop(key, None)


# ---------------------------------------------------------------------------
# Shared pipeline tail
# ---------------------------------------------------------------------------
def _launch_from_file(pl_file: str, game_name: str, xml_str: str) -> None:
    """Start playing from an already-saved .pl file."""
    initial = engine.get_initial_state(pl_file)
    if initial is None:
        st.error("Could not retrieve initial game state from Prolog.")
        return

    st.session_state.update(
        pl_file=pl_file,
        game_name=game_name,
        xml_str=xml_str,
        prolog_code=None,   # already on disk, no pending save
        state=initial,
        legal_moves=engine.get_legal_moves(pl_file, initial),
        move_history=[],
        winner=None,
        phase="playing",
        test_cases=None,
        test_results=None,
    )
    st.rerun()


def _preview_game(code: str, game_name: str, xml_str: str, attempts: list[dict]) -> None:
    """
    Hold generated code in session state for user review before saving.
    Transitions to the 'preview' phase where the Save button is shown.
    """
    st.session_state.update(
        prolog_code=code,
        game_name=game_name,
        xml_str=xml_str,
        prolog_attempts=attempts,
        phase="preview",
        pl_file=None,
    )
    st.rerun()


# ---------------------------------------------------------------------------
# Pipelines
# ---------------------------------------------------------------------------
def _run_pipeline(user_input: str) -> None:
    with st.status("Generating game…", expanded=True) as status:
        st.write("Generating rulebook…")
        rulebook = rule_gen.generate_rulebook(user_input)

        st.write(f"Verifying rulebook (up to {config.RULEBOOK_MAX_RETRIES} attempts)…")
        is_valid, final_rulebook, verification_history = rule_gen.verify_rulebook(
            user_input, rulebook
        )
        st.session_state["verification_history"] = verification_history

        if not is_valid:
            status.update(label="Rulebook verification failed.", state="error")
            with st.expander("Verification details"):
                for a in verification_history:
                    st.markdown(f"**Attempt {a['attempt']}**")
                    st.text(a["verification"])
                    st.divider()
            return

        st.write("Structuring rules as XML…")
        ok, xml_str = rule_gen.rulebook_to_xml(final_rulebook)
        if not ok:
            status.update(label="Could not structure rules as XML.", state="error")
            return

        st.write(f"Generating Prolog (up to {config.PROLOG_MAX_RETRIES} attempts)…")
        code, attempts = prolog_gen.generate_prolog(xml_str)
        if code is None:
            status.update(label="Prolog generation failed after all retries.", state="error")
            _show_prolog_attempts(attempts)
            return

        game_name = ET.fromstring(xml_str).findtext("game_name") or user_input
        status.update(label="Generation complete — review and save below.", state="complete")

    _preview_game(code, game_name, xml_str, attempts)


def _run_manual_pipeline(manual_rules: str) -> None:
    with st.status("Generating game from manual rules…", expanded=True) as status:
        st.write("Structuring rules as XML…")
        ok, xml_str = rule_gen.manual_rules_to_xml(manual_rules)
        if not ok:
            status.update(label="Could not structure manual rules as XML.", state="error")
            return

        st.write(f"Generating Prolog (up to {config.PROLOG_MAX_RETRIES} attempts)…")
        code, attempts = prolog_gen.generate_prolog(xml_str)
        if code is None:
            status.update(label="Prolog generation failed after all retries.", state="error")
            _show_prolog_attempts(attempts)
            return

        game_name = ET.fromstring(xml_str).findtext("game_name") or "custom_game"
        status.update(label="Generation complete — review and save below.", state="complete")

    _preview_game(code, game_name, xml_str, attempts)


def _load_from_file(uploaded_file, game_name: str) -> None:
    os.makedirs(config.PROLOG_DIRECTORY, exist_ok=True)
    safe_name = game_name.lower().replace(" ", "_")
    filepath = os.path.join(config.PROLOG_DIRECTORY, f"{safe_name}.pl")
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(uploaded_file.getvalue().decode("utf-8"))
    _launch_from_file(filepath, game_name, "")


def _show_prolog_attempts(attempts: list[dict]) -> None:
    """Show a collapsible breakdown of every failed Prolog attempt."""
    if not attempts:
        return
    with st.expander("Prolog generation details"):
        for a in attempts:
            icon = "✅" if a["passed"] else "❌"
            st.markdown(f"**{icon} Attempt {a['attempt']}**")
            if a["errors"]:
                for e in a["errors"]:
                    st.error(e)
            st.code(a["code"], language="prolog")
            st.divider()


# ---------------------------------------------------------------------------
# Move handler
# ---------------------------------------------------------------------------
def _handle_move(move: str) -> None:
    pl_file = st.session_state["pl_file"]
    state   = st.session_state["state"]

    player    = engine.get_current_player(pl_file, state) or "?"
    new_state = engine.apply_move(pl_file, state, move)

    if new_state is None:
        st.error(f"Move failed (engine returned no state): {move}")
        return

    st.session_state["move_history"].append({"player": player, "move": move})
    winner = engine.check_game_over(pl_file, new_state)
    st.session_state["state"] = new_state

    if winner:
        st.session_state["winner"] = winner
        st.session_state["phase"]  = "game_over"
    else:
        new_moves = engine.get_legal_moves(pl_file, new_state)
        st.session_state["legal_moves"] = new_moves
        if st.session_state.get("chosen_move") not in new_moves:
            st.session_state.pop("chosen_move", None)


# ---------------------------------------------------------------------------
# Test runner
# ---------------------------------------------------------------------------
def _run_tests() -> None:
    xml_str = st.session_state.get("xml_str", "")
    pl_file = st.session_state["pl_file"]

    if not xml_str:
        st.warning("No XML spec available (game was loaded from a file). Cannot auto-generate tests.")
        return

    with st.spinner("Generating and running tests…"):
        test_cases, results = test_gen.generate_and_run(xml_str, pl_file)

    st.session_state["test_cases"]   = test_cases
    st.session_state["test_results"] = results


# ---------------------------------------------------------------------------
# UI – input phase
# ---------------------------------------------------------------------------
def _render_input_phase() -> None:
    tab1, tab2, tab3 = st.tabs([
        "🎮 Generate from Name",
        "📝 Enter Manual Rules",
        "📁 Upload Prolog File",
    ])

    with tab1:
        st.subheader("What game would you like to play?")
        user_input = st.text_input(
            label="game_input",
            label_visibility="hidden",
            placeholder='e.g. "Tic-Tac-Toe" or "Connect Four"',
            key="game_name_input",
        )
        if st.button("Generate Game", key="gen_from_name", disabled=not user_input):
            _run_pipeline(user_input)

    with tab2:
        st.subheader("Enter Game Rules Manually")
        st.markdown(
            "Describe the game rules in plain text. Include board layout, "
            "players, how to move, win/draw conditions."
        )
        manual_rules = st.text_area(
            "Game Rules",
            height=300,
            placeholder=(
                "Game Name: Simple Tic-Tac-Toe\n"
                "Players: X and O take turns\n"
                "Board: 3x3 grid, initially empty\n"
                "Moves: Place your symbol in any empty cell\n"
                "Win: Get 3 in a row (horizontal, vertical, or diagonal)\n"
                "Draw: Board fills up with no winner"
            ),
            key="manual_rules_input",
        )
        if st.button("Generate from Rules", key="gen_from_manual", disabled=not manual_rules):
            _run_manual_pipeline(manual_rules)

    with tab3:
        st.subheader("Upload Existing Prolog File")
        col_upload, col_name = st.columns([2, 1])
        with col_upload:
            uploaded_file = st.file_uploader(
                "Upload .pl file", type=["pl"], label_visibility="collapsed"
            )
        with col_name:
            upload_name = st.text_input(
                "Game name",
                placeholder="e.g. tic_tac_toe",
                label_visibility="collapsed",
            )
        if st.button("Load File", disabled=not (uploaded_file and upload_name)):
            _load_from_file(uploaded_file, upload_name)


# ---------------------------------------------------------------------------
# UI – preview phase (generated, not yet saved)
# ---------------------------------------------------------------------------
def _render_preview_phase() -> None:
    game_name = st.session_state["game_name"]
    code      = st.session_state["prolog_code"]
    attempts  = st.session_state.get("prolog_attempts") or []

    st.subheader(f"Review: {game_name}")
    st.info(
        "The game was generated successfully. "
        "Review the code below, then **Save & Play** to persist it, "
        "or **Discard** to go back."
    )

    col_save, col_discard, _ = st.columns([1, 1, 4])
    with col_save:
        if st.button("💾 Save & Play", type="primary"):
            pl_file = prolog_gen.save_prolog(code, game_name)
            _launch_from_file(pl_file, game_name, st.session_state["xml_str"])
    with col_discard:
        if st.button("🗑 Discard"):
            _reset_state()
            st.rerun()

    st.markdown("**Generated Prolog code**")
    st.code(code, language="prolog")

    if attempts:
        _show_prolog_attempts(attempts)


# ---------------------------------------------------------------------------
# UI – playing phase
# ---------------------------------------------------------------------------
def _render_playing_phase() -> None:
    pl_file = st.session_state["pl_file"]
    state   = st.session_state["state"]

    st.subheader(st.session_state["game_name"])

    play_tab, tests_tab = st.tabs(["▶ Play", "🧪 Tests"])

    with play_tab:
        col_board, col_moves = st.columns([2, 1])

        with col_board:
            st.markdown("**Board**")
            st.code(engine.render_state(pl_file, state), language=None)

        with col_moves:
            st.markdown("**Your move**")
            moves = st.session_state["legal_moves"]
            if moves:
                if st.session_state.get("chosen_move") not in moves:
                    st.session_state["chosen_move"] = moves[0]
                st.radio("Legal moves", moves, key="chosen_move", label_visibility="collapsed")
                if st.button("Make move"):
                    _handle_move(st.session_state["chosen_move"])
                    st.rerun()
            else:
                st.write("No legal moves available.")

        if st.session_state["move_history"]:
            st.markdown("**Move history**")
            st.dataframe(
                st.session_state["move_history"],
                use_container_width=True,
                hide_index=False,
            )

    with tests_tab:
        _render_tests_tab()


def _render_tests_tab() -> None:
    st.markdown(
        "Run an auto-generated test suite against the current Prolog implementation. "
        "Tests are derived from the game's XML specification."
    )

    if not st.session_state.get("xml_str", ""):
        st.info("Tests are only available for games generated by this app (not uploaded files).")
        return

    if st.button("Generate & Run Tests"):
        _run_tests()

    results = st.session_state.get("test_results")
    if results is None:
        return

    passed = sum(1 for r in results if r["passed"])
    total  = len(results)
    st.metric("Tests passed", f"{passed} / {total}")

    for r in results:
        icon = "✅" if r["passed"] else "❌"
        with st.expander(f"{icon} {r['name']}"):
            st.write(f"**Description:** {r['description']}")
            st.code(r["goal"], language="prolog")
            if not r["passed"] and r["error"]:
                st.error(r["error"])


# ---------------------------------------------------------------------------
# UI – game over phase
# ---------------------------------------------------------------------------
def _render_game_over_phase() -> None:
    winner = st.session_state["winner"]
    if winner == "draw":
        st.success("It's a draw!")
    else:
        st.success(f"Game over — {winner} wins!")

    pl_file = st.session_state["pl_file"]
    state   = st.session_state["state"]
    st.code(engine.render_state(pl_file, state), language=None)

    if st.session_state["move_history"]:
        st.markdown("**Move history**")
        st.dataframe(st.session_state["move_history"], use_container_width=True)

    if st.button("Play again"):
        _reset_state()
        st.rerun()


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
def main() -> None:
    st.set_page_config(page_title="Text2Game", layout="wide")
    st.title("Text2Game 🎮")
    st.markdown("Generate playable games from natural language descriptions or manual rules.")

    _init_state()

    phase = st.session_state["phase"]
    if phase == "input":
        _render_input_phase()
    elif phase == "preview":
        _render_preview_phase()
    elif phase == "playing":
        _render_playing_phase()
    elif phase == "game_over":
        _render_game_over_phase()


if __name__ == "__main__":
    main()