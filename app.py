import os
import streamlit as st
import sys

sys.path.insert(0, os.path.dirname(__file__))

from src.ui import input_phase, pipeline_review_phase, playing_phase, game_over_phase


def _init_state():
    defaults = {
        "phase": "input",
        "pl_file": None,
        "game_name": None,
        "state": None,
        "legal_moves": [],
        "move_history": [],
        "winner": None,
        "prolog_code": None,
        "structured_json": None,
        "design_plan": None,
        "pipeline_outputs": {},
        "show_pipeline_output": False,
        "use_design_plan": True,
        "pipeline_failed": False
    }
    
    for k, v in defaults.items():
        if k not in st.session_state:
            st.session_state[k] = v


def main():
    st.set_page_config(page_title="ProloGame", layout="wide")
    _init_state()
    
    phase = st.session_state["phase"]
    
    if phase in ("input", "generating"):
        input_phase.render()
    elif phase == "pipeline_review":
        pipeline_review_phase.render()
    elif phase == "playing":
        playing_phase.render()
    elif phase == "game_over":
        game_over_phase.render()


main()