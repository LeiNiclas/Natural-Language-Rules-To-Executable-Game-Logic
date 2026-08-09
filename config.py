import os
from dotenv import load_dotenv

# Model selection
load_dotenv()
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")


BACKEND_RULE_GENERATOR  = "ollama"
MODEL_RULE_GENERATOR    = "gemma4:31b-cloud"

BACKEND_RULE_VERIFIER   = "ollama"
MODEL_RULE_VERIFIER     = "gemma4:31b-cloud"

BACKEND_JSON_STRUCTURER = "openai"
MODEL_JSON_STRUCTURER   = "o4-mini"

BACKEND_PROLOG_GENERATOR    = "openai"
MODEL_PROLOG_GENERATOR      = "o4-mini" # qwen3-coder:480b-cloud

# Add new models to the provider they belong to. The Streamlit settings UI
# builds its provider and model selectors from this catalog.
MODEL_CATALOG = {
	"ollama": [
		"gemma4:31b-cloud",
		"qwen3-coder:480b-cloud",
	],
	"openai": [
		"gpt-4o",
		"gpt-4o-mini",
		"o4-mini",
	],
}

# Pipeline settings
RULEBOOK_MAX_RETRIES    = 5 # How many times to retry rulebook generation on validation failure
PROLOG_MAX_RETRIES      = 5 # How many times to retry Prolog generation on validation failure
SWIPL_TIMEOUT           = 10 # Seconds before a Prolog validation call is killed
PROLOG_USE_DESIGN_PLAN  = True
PROLOG_USE_MULTISTAGE = True

# Paths
PROJECT_ROOT        = os.path.dirname(os.path.abspath(__file__))
PROLOG_DIRECTORY    = os.path.join(PROJECT_ROOT, "prolog")