import streamlit as st
import src.pipeline.rule_generator as rule_gen
import src.pipeline.prolog_generator as prolog_gen
import src.engine.prolog_engine as engine
import config
import os
import tempfile


def _run_pipeline(user_input : str, skip_rulebook : bool = False) -> None:
    st.session_state["phase"] = "generating"
    st.session_state["pipeline_outputs"] = {}
    
    with st.status("Generating game...", expanded=True) as status:
        if skip_rulebook:
            rulebook = user_input
        else:
            st.write("Generating rulebook...")
            rulebook = rule_gen.generate_rulebook(user_input)
            st.session_state["pipeline_outputs"]["rulebook"] = rulebook
            status.update(label="Validating the rules...")
            
            st.write("Verifying rulebook...")
            verification = rule_gen.verify_rulebook(user_input, rulebook)
            st.session_state["pipeline_outputs"]["verification"] = verification
            
            if not verification:
                status.update(label="Rulebook verification failed.", state="error")
                st.session_state["phase"] = "input"
                return
        
        status.update(label="Rules are looking good...")
        st.write("Structuring rules as JSON...")
        ok, structured = rule_gen.rulebook_to_json(rulebook)
        st.session_state["pipeline_outputs"]["structured_json"] = structured
        
        if not ok:
            status.update(label="Could not parse structured JSON.", state="error")
            st.session_state["phase"] = "input"
            return
        
        status.update(label="Making a design plan for the game...")
        st.write("Generating prolog code...")
        code, design_plan = prolog_gen.generate_prolog(structured)
        st.session_state["pipeline_outputs"]["design_plan"] = design_plan
        st.session_state["pipeline_outputs"]["prolog_code"] = code
        
        if code is None:
            status.update(label="Prolog generation failed after all retries.", state="error")
            st.session_state["phase"] = "input"
            return
        
        status.update(label="Game code is being generated...")
        game_name = structured.get("game_name", user_input)
        safe_name = game_name.lower().replace(" ", "_")
        tmp_dir = tempfile.mkdtemp()
        pl_file = os.path.join(tmp_dir, f"{safe_name}.pl")
        
        with open(pl_file, "w", encoding="utf-8") as f:
            f.write(code)
        
        st.session_state["prolog_code"] = code
        st.session_state["structured_json"] = structured
        st.session_state["design_plan"] = design_plan
        
        status.update(label="Game ready!", state="complete")
        
    initial = engine.get_initial_state(pl_file)
    
    if initial is None:
        st.error("Could not retrieve initial game state from Prolog")
        st.session_state["phase"] = "input"
        return

    st.session_state["pl_file"] = pl_file
    st.session_state["game_name"] = game_name
    st.session_state["state"] = initial
    st.session_state["legal_moves"] = engine.get_legal_moves(pl_file, initial)
    st.session_state["move_history"] = []
    st.session_state["winner"] = None
    
    if st.session_state.get("show_pipeline_output"):
        st.session_state["phase"] = "pipeline_review"
    else:
        st.session_state["phase"] = "playing"
    
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

    st.session_state["pl_file"] = filepath
    st.session_state["game_name"] = game_name
    st.session_state["state"] = initial
    st.session_state["legal_moves"] = engine.get_legal_moves(filepath, initial)
    st.session_state["move_history"] = []
    st.session_state["winner"] = None
    st.rerun()


def _render_settings_popover():
    rule_gen_models = ["gemma4:31b-cloud", "gpt-4o", "gpt-4o-mini", "o4-mini"]
    prolog_gen_models = ["gemma4:31b-cloud", "gpt-4o", "gpt-4o-mini", "o4-mini"]

    with st.popover("Settings"):
        st.markdown("**Models**")

        col1, col2 = st.columns([2, 3])
        
        with col1:
            st.caption("Rule generator")
        with col2:
            selected = st.selectbox(
                "rule_gen_model",
                rule_gen_models,
                index=rule_gen_models.index(config.MODEL_RULE_GENERATOR) if config.MODEL_RULE_GENERATOR in rule_gen_models else 0,
                label_visibility="collapsed"
            )
            config.MODEL_RULE_GENERATOR = selected

        col1, col2 = st.columns([2, 3])
        
        with col1:
            st.caption("Prolog generator")
        with col2:
            selected = st.selectbox(
                "prolog_gen_model",
                prolog_gen_models,
                index=prolog_gen_models.index(config.MODEL_PROLOG_GENERATOR) if config.MODEL_PROLOG_GENERATOR in prolog_gen_models else 0,
                label_visibility="collapsed"
            )
            config.MODEL_PROLOG_GENERATOR = selected

        st.divider()
        st.markdown("**Debug**")

        st.session_state["show_pipeline_output"] = st.checkbox(
            "Show pipeline output",
            value=st.session_state.get("show_pipeline_output", False)
        )
        st.session_state["use_design_plan"] = st.checkbox(
            "Use design plan",
            value=st.session_state.get("use_design_plan", config.PROLOG_USE_DESIGN_PLAN)
        )


def render():
    col_title, col_settings = st.columns([6, 1])
    
    with col_title:
        col_title.title("ProloGame")
        st.caption("Enter a game name or describe your own rules. ProloGame tries to generate a playable Prolog implementation!")
    with col_settings:
        st.write("")
        st.write("")
        _render_settings_popover()
    
    st.divider()
    
    tab_name, tab_rules = st.tabs(["By name", "By rules"])
    
    with tab_name:
        user_input = st.text_input(
            label="game_input",
            label_visibility="hidden",
            placeholder="e.g. Tic-Tac-Toe"
        )
        
        if st.button("Generate", disabled=not user_input, key="btn_by_name"):
            _run_pipeline(user_input, skip_rulebook=False)
    
    with tab_rules:
        custom_rules = st.text_area(
            label="custom_rules",
            label_visibility="hidden",
            placeholder="Describe your game rules here...",
            height=150
        )
        
        if st.button("Generate", disabled=not custom_rules, key="btn_by_rules"):
            _run_pipeline(custom_rules, skip_rulebook=True)
    
    st.divider()
    
    st.caption("Or upload an existing Prolog file")
    col_upload, col_name, col_btn = st.columns([3, 2, 1])
    
    with col_upload:
        uploaded_file = st.file_uploader("Upload .pl file", type=["pl"], label_visibility="collapsed")
    with col_name:
        upload_name = st.text_input("Game name", label_visibility="collapsed")
    with col_btn:
        st.write("")
        
        if st.button("Load", disabled=not (uploaded_file and upload_name)):
            _load_from_file(uploaded_file, upload_name)
