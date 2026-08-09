import streamlit as st


def _render_navigation():
    failed = st.session_state.get("pipeline_failed", False)
    col_back, col_play, _ = st.columns([1, 1, 4])

    with col_back:
        if st.button("Back to menu", key="back_to_menu"):
            st.session_state["phase"] = "input"
            st.session_state["pipeline_failed"] = False
            st.session_state["pipeline_failure_message"] = None
            st.session_state["pipeline_outputs"] = {}
            st.rerun()

    with col_play:
        if st.button("Play", disabled=failed, key="play_generated_game"):
            st.session_state["phase"] = "playing"
            st.rerun()


def render():
    col_title, col_settings = st.columns([6, 1])
    
    with col_title:
        st.title("ProloGame")
        if st.session_state.get("pipeline_failed", False):
            st.caption("Generation failed. Review the output produced before the failure.")
        else:
            st.caption("Generation complete.")
    
    st.divider()
    
    outputs = st.session_state.get("pipeline_outputs", {})

    tab_labels = []
    if "rulebook" in outputs: tab_labels.append("Rulebook")
    if "verification" in outputs: tab_labels.append("Rule validation")
    if "structured_json" in outputs: tab_labels.append("Structured JSON")
    if "design_plan" in outputs: tab_labels.append("Design plan")
    if "prolog_code" in outputs: tab_labels.append("Prolog code")
    
    if not tab_labels:
        st.info("No pipeline output available.")
        st.divider()
        _render_navigation()
        return
    
    tabs = st.tabs(tab_labels)
    tab_index = 0
    
    if "rulebook" in outputs:
        with tabs[tab_index]:
            st.text(outputs["rulebook"])
        tab_index += 1
    
    if "verification" in outputs:
        with tabs[tab_index]:
            verified = outputs["verification"]
            
            if verified:
                st.success("Rulebook verified successfully.")
            else:
                st.error("Rulebook verification failed.")

        tab_index += 1
    
    if "structured_json" in outputs:
        with tabs[tab_index]:
            st.json(outputs["structured_json"])
        tab_index += 1
    
    if "design_plan" in outputs:
        with tabs[tab_index]:
            st.text(outputs["design_plan"])
        tab_index += 1
    
    if "prolog_code" in outputs:
        with tabs[tab_index]:
            st.code(outputs["prolog_code"], language="prolog")

    st.divider()
    _render_navigation()
    