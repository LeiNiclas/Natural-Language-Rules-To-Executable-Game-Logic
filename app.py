import config
import os
import streamlit as st
import sys
import tempfile

sys.path.insert(0, os.path.dirname(__file__))

import src.pipeline.rule_generator as rule_gen
import src.pipeline.prolog_generator as prolog_gen
import src.engine.prolog_engine as engine


def _init_state():
    defaults = {
        "phase":            "input",    # input | generating | playing | game_over
        "pl_file":          None,
        "game_name":        None,
        "state":            None,       # current Prolog state term string
        "legal_moves":      [],
        "move_history":     [],         # list of {"move" : str, "player" : str}
        "winner":           None,
        "prolog_code":      None,
        "structured_json":  None,
        "design_plan":      None
    }
    
    for k, v in defaults.items():
        if k not in st.session_state:
            st.session_state[k] = v


def _run_pipeline(user_input : str, skip_rulebook : bool = False):
    st.session_state["phase"] = "generating"
    
    with st.status("Generating game...", expanded=True) as status:
        if skip_rulebook:
            rulebook = user_input
        else:
            st.write("Generating rulebook...")
            rulebook = rule_gen.generate_rulebook(user_input)
        
            st.write("Verifying rulebook...")
        
            if not rule_gen.verify_rulebook(user_input, rulebook):
                status.update(label="Rulebook verification failed.", state="error")
                st.session_state["phase"] = "input"
                return

        st.write("Structuring rules as JSON...")
        ok, structured = rule_gen.rulebook_to_json(rulebook)
        
        if not ok:
            status.update(label="Could not parse structured JSON.", state="error")
            st.session_state["phase"] = "input"
            return
        
        st.write("Generating Prolog code...")
        code, design_plan = prolog_gen.generate_prolog(structured)
        
        if code is None:
            status.update(label="Prolog generation failed after all retries.", state="error")
            st.session_state["phase"] = "input"
            return
        
        tmp_dir = tempfile.mkdtemp()
        game_name = structured.get("game_name", user_input)
        safe_name = game_name.lower().replace(" ", "_")
        pl_file = os.path.join(tmp_dir, f"{safe_name}.pl")
        
        with open(pl_file, "w", encoding="utf-8") as f:
            f.write(code)
        
        st.session_state["prolog_code"] = code
        st.session_state["structured_json"] = structured
        st.session_state["design_plan"] = design_plan
        
        status.update(label="Game ready!", state="complete")
    
    # Initialize engine state
    initial = engine.get_initial_state(pl_file)
    
    if initial is None:
        st.error("Could not retrieve initial game state from Prolog.")
        st.session_state["phase"] = "input"
        return
    
    st.session_state["pl_file"]         = pl_file
    st.session_state["game_name"]       = game_name
    st.session_state["state"]           = initial
    st.session_state["legal_moves"]     = engine.get_legal_moves(pl_file, initial)
    st.session_state["move_history"]    = []
    st.session_state["winner"]          = None
    st.session_state["phase"]           = "playing"
    st.rerun()


def _load_from_file(uploaded_file, game_name : str):
    os.makedirs(config.PROLOG_DIRECTORY, exist_ok=True)
    safe_name = game_name.lower().replace(" ", "_")
    filepath = os.path.join(config.PROLOG_DIRECTORY, f"{safe_name}.pl")
    
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(uploaded_file.getvalue().decode("utf-8"))
    
    initial = engine.get_initial_state(filepath)
    if initial is None:
        st.error("Could not retrieve initial state from the uploaded file.")
        return
    
    st.session_state["pl_file"]      = filepath
    st.session_state["game_name"]    = game_name
    st.session_state["state"]        = initial
    st.session_state["legal_moves"]  = engine.get_legal_moves(filepath, initial)
    st.session_state["move_history"] = []
    st.session_state["winner"]       = None
    st.session_state["phase"]        = "playing"
    st.rerun()



def _handle_move(move : str):
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
    
    st.rerun()



def _render_input_phase():
    st.subheader("What game would you like to play?")
    
    tab_name, tab_rules = st.tabs(["By Name", "By Rules"])
    
    with tab_name:
        user_input = st.text_input(
            label="game_input",
            label_visibility="hidden",
            placeholder="e.g. Tic-Tac-Toe"
        )
        
        if st.button("Generate Game", disabled=not user_input):
            _run_pipeline(user_input, skip_rulebook=False)
            
    with tab_rules:
        custom_rules = st.text_area(
            label="custom_rules",
            label_visibility="hidden",
            placeholder="How do you play your game?",
            height=300
        )
        
        if st.button("Generate from Rules", disabled=not custom_rules):
            _run_pipeline(custom_rules, skip_rulebook=True)
    

    st.divider()
    st.markdown("**Or upload an existing Prolog file**")

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
            use_container_width=True,
            hide_index=False
        )
    
    st.divider()
    col_save1, col_save2 = st.columns(2)
    
    with col_save1:
        if st.button("Save Prolog File"):
            path = prolog_gen.save_prolog(
                st.session_state["prolog_code"],
                st.session_state["game_name"]
            )
            st.success(f"Saved to '{path}'")
    
    with col_save2:
        if st.button("Save Prolog + Config"):
            pl_path = prolog_gen.save_prolog(
                st.session_state["prolog_code"],
                st.session_state["game_name"]
            )
            cfg_path = prolog_gen.save_config(
                st.session_state["structured_json"],
                st.session_state["design_plan"],
                st.session_state["game_name"]
            )
            st.success(f"Saved to '{pl_path}' and '{cfg_path}'")


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
        st.dataframe(st.session_state["move_history"], use_container_width=True)
    
    if st.button("Play again"):
        for key in ["phase", "pl_file", "game_name", "state", "legal_moves", "move_history", "winner", "chosen_move"]:
            if key in st.session_state:
                del st.session_state[key]

        st.rerun()


def main():
    st.set_page_config(page_title="Text2Game", layout="wide")
    st.title("Text2Game")
    _init_state()
    
    phase = st.session_state["phase"]
    
    if phase == "input":
        _render_input_phase()
    elif phase == "generating":
        _render_input_phase()
    elif phase == "playing":
        _render_playing_phase()
    elif phase == "game_over":
        _render_game_over_phase()


main()
