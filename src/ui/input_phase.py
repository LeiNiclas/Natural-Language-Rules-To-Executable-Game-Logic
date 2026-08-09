import streamlit as st
import src.pipeline.rule_generator as rule_gen
import src.engine.prolog_engine as engine
import config
import os
import tempfile

import src.pipeline.prolog_composer as prolog_gen_multi
import src.pipeline.prolog_generator as prolog_gen_single


def _fail_pipeline(message: str, status=None) -> None:
    if status is not None:
        status.update(label=message, state="error")

    st.session_state["phase"] = "input"
    st.session_state["pipeline_failed"] = True
    st.session_state["pipeline_failure_message"] = message
    st.rerun()


def _run_pipeline(user_input : str, skip_rulebook : bool = False) -> None:
    st.session_state["phase"] = "generating"
    st.session_state["pipeline_outputs"] = {}
    st.session_state["pipeline_failed"] = False

    config.PROLOG_USE_DESIGN_PLAN = st.session_state["use_design_plan_widget"]
    config.PROLOG_USE_MULTISTAGE = st.session_state["use_multistage_widget"]
    prolog_gen = prolog_gen_multi if config.PROLOG_USE_MULTISTAGE else prolog_gen_single
    
    with st.status("Generating game...", expanded=True) as status:
        if skip_rulebook:
            rulebook = user_input
        else:
            st.write("Generating rulebook...")
            ok, rulebook = rule_gen.generate_rulebook(user_input)
            st.session_state["pipeline_outputs"]["rulebook"] = rulebook
            
            if not ok:
                _fail_pipeline("Rulebook generation failed after all retries.", status)
        
        status.update(label="Rules are looking good...", expanded=True)
        st.write("Structuring rules as JSON...")
        ok, structured = rule_gen.rulebook_to_json(rulebook)
        st.session_state["pipeline_outputs"]["structured_json"] = structured
        
        if not ok:
            _fail_pipeline("Could not parse structured JSON.", status)
        
        status.update(label="Working on the prolog code...", expanded=True)
        st.write("Generating prolog code...")
        code, design_plan = prolog_gen.generate_prolog(structured)
        st.session_state["pipeline_outputs"]["design_plan"] = design_plan
        st.session_state["pipeline_outputs"]["prolog_code"] = code
        
        if code is None:
            _fail_pipeline("Prolog generation failed after all retries.", status)
        
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
        _fail_pipeline("Could not retrieve initial game state from Prolog.")

    st.session_state["pl_file"] = pl_file
    st.session_state["game_name"] = game_name
    st.session_state["state"] = initial
    st.session_state["legal_moves"] = engine.get_legal_moves(pl_file, initial)
    st.session_state["move_history"] = []
    st.session_state["winner"] = None
    
    if st.session_state.get("show_pipeline_output_widget"):
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
    providers = list(config.MODEL_CATALOG)

    def default_provider_index(backend):
        return providers.index(backend) if backend in providers else 0

    with st.popover("Settings"):
        st.markdown("**Models**")

        col1, col2 = st.columns([2, 3])
        
        with col1:
            st.caption("Rule generator")
        with col2:
            rule_backend = st.selectbox(
                "Provider",
                providers,
                index=default_provider_index(config.BACKEND_RULE_GENERATOR),
                format_func=str.title,
                key="rule_gen_backend"
            )
            rule_models = config.MODEL_CATALOG[rule_backend]
            rule_model_index = (
                rule_models.index(config.MODEL_RULE_GENERATOR)
                if config.MODEL_RULE_GENERATOR in rule_models else 0
            )
            rule_model_key = f"rule_gen_model_{rule_backend}"
            if st.session_state.get(rule_model_key) not in rule_models:
                st.session_state[rule_model_key] = rule_models[rule_model_index]
            config.MODEL_RULE_GENERATOR = st.selectbox(
                "Model",
                rule_models,
                index=rule_model_index,
                key=rule_model_key
            )
            config.BACKEND_RULE_GENERATOR = rule_backend

        col1, col2 = st.columns([2, 3])
        
        with col1:
            st.caption("Prolog generator")
        with col2:
            prolog_backend = st.selectbox(
                "Provider",
                providers,
                index=default_provider_index(config.BACKEND_PROLOG_GENERATOR),
                format_func=str.title,
                key="prolog_gen_backend"
            )
            prolog_models = config.MODEL_CATALOG[prolog_backend]
            prolog_model_index = (
                prolog_models.index(config.MODEL_PROLOG_GENERATOR)
                if config.MODEL_PROLOG_GENERATOR in prolog_models else 0
            )
            prolog_model_key = f"prolog_gen_model_{prolog_backend}"
            if st.session_state.get(prolog_model_key) not in prolog_models:
                st.session_state[prolog_model_key] = prolog_models[prolog_model_index]
            config.MODEL_PROLOG_GENERATOR = st.selectbox(
                "Model",
                prolog_models,
                index=prolog_model_index,
                key=prolog_model_key
            )
            config.BACKEND_PROLOG_GENERATOR = prolog_backend

        st.divider()
        st.markdown("**Debug**")

        st.checkbox(
            "Show pipeline output",
            key="show_pipeline_output_widget"
        )
        st.checkbox(
            "Use design plan",
            key="use_design_plan_widget"
        )
        st.checkbox(
            "Use multi-stage generation",
            key="use_multistage_widget"
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
    
    if st.session_state["pipeline_failed"]:
        st.error(st.session_state.get(
            "pipeline_failure_message",
            "Generation failed. Inspect the generated output before trying again."
        ))
        if st.button("Show generation details", key="show_generation_details"):
            st.session_state["phase"] = "pipeline_review"
            st.rerun()
        
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
