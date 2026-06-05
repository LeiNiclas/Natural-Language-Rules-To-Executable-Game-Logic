import os

# Model selection
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")

BACKEND_RULE_GENERATOR  = "ollama"
MODEL_RULE_GENERATOR    = "gemma4"

BACKEND_RULE_VERIFIER   = "ollama"
MODEL_RULE_VERIFIER     = "gemma4"

BACKEND_JSON_STRUCTURER = "ollama"
MODEL_JSON_STRUCTURER   = "gemma4"

BACKEND_PROLOG_GENERATOR    = "openai"
MODEL_PROLOG_GENERATOR      = "gpt-4o" # qwen3-coder:480b-cloud

# Pipeline settings
PROLOG_MAX_RETRIES  = 3  # How many times to retry Prolog generation on validation failure
SWIPL_TIMEOUT       = 10 # Seconds before a Prolog validation call is killed

# Paths
PROJECT_ROOT        = os.path.dirname(os.path.abspath(__file__))
PROLOG_DIRECTORY    = os.path.join(PROJECT_ROOT, "prolog")