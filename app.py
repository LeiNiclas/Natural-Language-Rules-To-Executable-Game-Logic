import config
import os
import streamlit as st
import sys

sys.path.insert(0, os.path.dirname(__file__))

import src.pipeline.rule_generator as rule_gen
import src.pipeline.prolog_generator as prolog_gen
import src.engine.prolog_engine as engine


def _init_state():
    defaults = {
        "phase": "input",  # input | generating | playing | game_over
        "pl_file": None,
        "game_name": None,
        "state": None,  # current Prolog state term string
        "legal_moves": [],
        "move_history": [],  # list of {"move" : str, "player" : str}
        "winner": None,
        "verification_history": None  # Store verification attempts
    }

    for k, v in defaults.items():
        if k not in st.session_state:
            st.session_state[k] = v


def _run_pipeline(user_input: str):
    st.session_state["phase"] = "generating"

    with st.status("Generating game...", expanded=True) as status:
        st.write("Generating rulebook...")
        rulebook = rule_gen.generate_rulebook(user_input)

        st.write("Verifying and repairing rulebook (up to 3 attempts)...")

        is_valid, final_rulebook, verification_history = rule_gen.verify_rulebook(user_input, rulebook)

        # Store verification history for display
        st.session_state["verification_history"] = verification_history

        if not is_valid:
            status.update(label="Rulebook verification failed after all retries.", state="error")

            # Show verification details
            with st.expander("View verification details"):
                for attempt in verification_history:
                    st.markdown(f"**Attempt {attempt['attempt']}:**")
                    st.text(attempt['verification'])
                    st.divider()

            st.session_state["phase"] = "input"
            return

        st.write("Structuring rules as JSON...")
        ok, structured = rule_gen.rulebook_to_json(final_rulebook)

        if not ok:
            status.update(label="Could not parse structured JSON.", state="error")
            st.session_state["phase"] = "input"
            return

        st.write("Generating Prolog code...")
        code = prolog_gen.generate_prolog(structured)

        if code is None:
            status.update(label="Prolog generation failed after all retries.", state="error")
            st.session_state["phase"] = "input"
            return

        game_name = structured.get("game_name", user_input)
        pl_file = prolog_gen.save_prolog(code, game_name)

        status.update(label="Game ready!", state="complete")

    # Initialize engine state
    initial = engine.get_initial_state(pl_file)

    if initial is None:
        st.error("Could not retrieve initial game state from Prolog.")
        st.session_state["phase"] = "input"
        return

    st.session_state["pl_file"] = pl_file
    st.session_state["game_name"] = game_name
    st.session_state["state"] = initial
    st.session_state["legal_moves"] = engine.get_legal_moves(pl_file, initial)
    st.session_state["move_history"] = []
    st.session_state["winner"] = None
    st.session_state["phase"] = "playing"
    st.rerun()


def _run_manual_pipeline(manual_rules: str):
    """Run pipeline with manually provided rules."""
    st.session_state["phase"] = "generating"

    with st.status("Generating game from manual rules...", expanded=True) as status:
        st.write("Converting manual rules to JSON...")
        ok, structured = rule_gen.manual_rules_to_json(manual_rules)

        if not ok:
            status.update(label="Could not parse manual rules into JSON.", state="error")
            st.session_state["phase"] = "input"
            return

        st.write("Generating Prolog code...")
        code = prolog_gen.generate_prolog(structured)

        if code is None:
            status.update(label="Prolog generation failed after all retries.", state="error")
            st.session_state["phase"] = "input"
            return

        game_name = structured.get("game_name", "custom_game")
        pl_file = prolog_gen.save_prolog(code, game_name)

        status.update(label="Game ready!", state="complete")

    # Initialize engine state
    initial = engine.get_initial_state(pl_file)

    if initial is None:
        st.error("Could not retrieve initial game state from Prolog.")
        st.session_state["phase"] = "input"
        return

    st.session_state["pl_file"] = pl_file
    st.session_state["game_name"] = game_name
    st.session_state["state"] = initial
    st.session_state["legal_moves"] = engine.get_legal_moves(pl_file, initial)
    st.session_state["move_history"] = []
    st.session_state["winner"] = None
    st.session_state["phase"] = "playing"
    st.rerun()


def _load_from_file(uploaded_file, game_name: str):
    os.makedirs(config.PROLOG_DIRECTORY, exist_ok=True)
    safe_name = game_name.lower().replace(" ", "_")
    filepath = os.path.join(config.PROLOG_DIRECTORY, f"{safe_name}.pl")

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(uploaded_file.getvalue().decode("utf-8"))

    initial = engine.get_initial_state(filepath)
    if initial is None:
        st.error("Could not retrieve initial state from the uploaded file.")
        return

    st.session_state["pl_file"] = filepath
    st.session_state["game_name"] = game_name
    st.session_state["state"] = initial
    st.session_state["legal_moves"] = engine.get_legal_moves(filepath, initial)
    st.session_state["move_history"] = []
    st.session_state["winner"] = None
    st.session_state["phase"] = "playing"
    st.rerun()


def _handle_move(move: str):
    pl_file = st.session_state["pl_file"]
    state = st.session_state["state"]

    player = engine.get_current_player(pl_file, state) or "?"
    new_state = engine.apply_move(pl_file, state, move)

    if new_state is None:
        st.error(f"Illegal move: {move}")
        return

    st.session_state["move_history"].append({
        "move": move,
        "player": player
    })

    winner = engine.check_game_over(pl_file, new_state)
    st.session_state["state"] = new_state

    if winner:
        st.session_state["winner"] = winner
        st.session_state["phase"] = "game_over"
    else:
        st.session_state["legal_moves"] = engine.get_legal_moves(pl_file, new_state)


def _render_input_phase():
    # Create tabs for different input methods
    tab1, tab2, tab3 = st.tabs(["🎮 Generate from Name", "📝 Enter Manual Rules", "📁 Upload Prolog File"])

    with tab1:
        st.subheader("What game would you like to play?")

        user_input = st.text_input(
            label="game_input",
            label_visibility="hidden",
            placeholder='e.g. "Give me the rules for Tic-Tac-Toe"',
            key="game_name_input"
        )
        if st.button("Generate Game", key="generate_from_name", disabled=not user_input):
            _run_pipeline(user_input)

    with tab2:
        st.subheader("Enter Game Rules Manually")
        st.markdown("""
        Describe the game rules in plain text. Be as detailed as possible including:
        - Board/playing area description
        - Players and their roles
        - How to make moves
        - Win/loss conditions
        - Draw conditions (if any)
        """)

        manual_rules = st.text_area(
            "Game Rules",
            height=300,
            placeholder="""
Example:
Game Name: Simple Tic-Tac-Toe
Players: X and O take turns
Board: 3x3 grid, initially empty
Moves: Place your symbol in any empty cell
Win: Get 3 in a row (horizontal, vertical, or diagonal)
Draw: Board fills up with no winner
            """.strip(),
            key="manual_rules_input"
        )

        col1, col2 = st.columns([1, 5])
        with col1:
            if st.button("Generate from Rules", key="generate_from_manual", disabled=not manual_rules):
                _run_manual_pipeline(manual_rules)

    with tab3:
        st.subheader("Upload Existing Prolog File")

        col_upload, col_name = st.columns([2, 1])
        with col_upload:
            uploaded_file = st.file_uploader("Upload .pl file", type=["pl"], label_visibility="collapsed")
        with col_name:
            upload_name = st.text_input("Game name", placeholder="e.g. tic_tac_toe", label_visibility="collapsed")

        if st.button("Load File", disabled=not (uploaded_file and upload_name)):
            _load_from_file(uploaded_file, upload_name)


def _render_playing_phase():
    pl_file = st.session_state["pl_file"]
    state = st.session_state["state"]

    st.subheader(st.session_state["game_name"])

    col_board, col_moves = st.columns([2, 1])

    with col_board:
        st.markdown("**Board**")
        st.code(engine.render_state(pl_file, state), language=None)

    with col_moves:
        st.markdown("**Your move**")
        moves = st.session_state["legal_moves"]

        if moves:
            if "chosen_move" not in st.session_state or st.session_state["chosen_move"] not in moves:
                st.session_state["chosen_move"] = moves[0]

            st.radio("Legal moves", moves, key="chosen_move", label_visibility="collapsed")

            if st.button("Make move"):
                _handle_move(st.session_state["chosen_move"])
        else:
            st.write("No legal moves available.")

    if st.session_state["move_history"]:
        st.markdown("**Move history**")
        st.dataframe(
            st.session_state["move_history"],
            width='stretch',
            hide_index=False
        )


def _render_game_over_phase():
    winner = st.session_state["winner"]

    if winner == "draw":
        st.success("It's a draw!")
    else:
        st.success(f"Game over - {winner} wins!")

    pl_file = st.session_state["pl_file"]
    state = st.session_state["state"]
    st.code(engine.render_state(pl_file, state), language=None)

    if st.session_state["move_history"]:
        st.markdown("**Move history**")
        st.dataframe(st.session_state["move_history"], width='stretch')

    if st.button("Play again"):
        for key in ["phase", "pl_file", "game_name", "state", "legal_moves", "move_history", "winner", "chosen_move",
                    "verification_history"]:
            if key in st.session_state:
                del st.session_state[key]

        st.rerun()


def main():
    st.set_page_config(page_title="Text2Game", layout="wide")
    st.title("Text2Game 🎮")
    st.markdown("Generate playable games from natural language descriptions or manual rules")

    _init_state()

    phase = st.session_state["phase"]

    if phase == "input":
        _render_input_phase()
    elif phase == "generating":
        # Show a spinner while generating
        with st.spinner("Generating your game... This may take a moment."):
            st.empty()  # Keep the input phase visible
    elif phase == "playing":
        _render_playing_phase()
    elif phase == "game_over":
        _render_game_over_phase()


if __name__ == "__main__":
    main()