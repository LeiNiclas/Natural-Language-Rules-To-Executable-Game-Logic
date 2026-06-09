import streamlit as st
import src.engine.prolog_engine as engine
import src.pipeline.prolog_generator as prolog_gen


def _handle_move(move : str):
    pl_file = st.session_state["pl_file"]
    state = st.session_state["state"]
    
    player = engine.get_current_player(pl_file, state) or "?"
    new_state = engine.apply_move(pl_file, state, move)
    
    if new_state is None:
        st.error(f"Illegal move: {move}")
        return
    
    st.session_state["move_history"].append({
        "player": player,
        "move": move
    })
    
    winner = engine.check_game_over(pl_file, new_state)
    st.session_state["state"] = new_state
    
    if winner:
        st.session_state["winner"] = winner
        st.session_state["phase"] = "game_over"
    else:
        st.session_state["legal_moves"] = engine.get_legal_moves(pl_file, new_state)
    
    st.rerun()


def _render_history():
    history = st.session_state.get("move_history", [])
    
    if not history:
        st.caption("No moves yet.")
        return
    
    for i, entry in enumerate(reversed(history)):
        st.markdown(
            f"<div style='font-size:13px; padding:4px 0; border-bottom:0.5px solid var(--color-border-tertiary);'>"
            f"<span style='color:var(--color-text-secondary);'>#{len(history) - i}&nbsp;&nbsp;{entry['player']}</span>"
            f"&nbsp;&nbsp;{entry['move']}"
            f"</div>",
            unsafe_allow_html=True
        )


def _render_save_buttons():
    col1, col2 = st.columns(2)
    
    with col1:
        if st.button("Save .pl", width="stretch"):
            path = prolog_gen.save_prolog(
                st.session_state["prolog_code"],
                st.session_state["game_name"]
            )
            st.success(f"Saved to '{path}'")
    
    with col2:
        if st.button("Save .pl + config", width="stretch"):
            pl_path = prolog_gen.save_prolog(
                st.session_state["prolog_code"],
                st.session_state["game_name"]
            )
            cfg_path = prolog_gen.save_config(
                st.session_state["structured_json"],
                st.session_state["design_plan"],
                st.session_state["game_name"]
            )
            
            st.success(f"Saved to '{pl_path}'\nand '{cfg_path}'")


def render():
    pl_file = st.session_state["pl_file"]
    state = st.session_state["state"]
    
    col_title, _ = st.columns([6, 1])
    
    with col_title:
        st.title("ProloGame")
    
    st.divider()
    
    col_history, col_board, col_moves = st.columns([1, 2, 1])
    
    with col_history:
        st.caption("Move history")
        _render_history()
    
    with col_board:
        st.subheader(st.session_state["game_name"])
        st.code(engine.render_state(pl_file, state), language=None)
    
        player = engine.get_current_player(pl_file, state)
        
        if player:
            st.caption(f"Current player: {player}")
        
        st.divider()
        _render_save_buttons()
    
    with col_moves:
        st.caption("Legal moves")
        moves = st.session_state.get("legal_moves", [])
        
        if moves:
            if "chosen_move" not in st.session_state or st.session_state["chosen_move"] not in moves:
                st.session_state["chosen_moves"] = moves[0]
            
            st.radio(
                "Legal moves",
                moves,
                key="chosen_move",
                label_visibility="collapsed"
            )
            
            if st.button("Make move", width="content"):
                _handle_move(st.session_state["chosen_move"])
        else:
            st.caption("No legal moves available.")