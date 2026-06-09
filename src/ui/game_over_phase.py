import streamlit as st
import src.engine.prolog_engine as engine
import src.pipeline.prolog_generator as prolog_gen


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
    winner = st.session_state["winner"]
    
    col_title, _ = st.columns([6, 1])
    
    with col_title:
        st.title("ProloGame")
    
    st.divider()
    
    if winner == "draw":
        st.info("It's a draw.")
    else:
        st.success(f"Game over - {winner} wins!")
    
    col_history, col_board, col_actions = st.columns([1, 2, 1])
    
    with col_history:
        st.caption("Move history")
        _render_history()

    with col_board:
        st.subheader(st.session_state["game_name"])
        st.code(engine.render_state(pl_file, state), language=None)

        st.divider()
        _render_save_buttons()
    
    with col_actions:
        st.caption("What's next?")
        
        if st.button("Play again", width="content"):
            initial = engine.get_initial_state(pl_file)
            
            st.session_state["state"]        = initial
            st.session_state["legal_moves"]  = engine.get_legal_moves(pl_file, initial)
            st.session_state["move_history"] = []
            st.session_state["winner"]       = None
            st.session_state["phase"]        = "playing"
            
            if "chosen_move" in st.session_state:
                del st.session_state["chosen_move"]
                
            st.rerun()
        
        if st.button("Back to menu", width="content"):
            for key in list(st.session_state.keys()):
                del st.session_state[key]
            
            st.rerun()
