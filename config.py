import os

# Model selection
MODEL_RULE_GENERATOR    = "gemma4"
MODEL_RULE_VERIFIER     = "gemma4"
MODEL_JSON_STRUCTURER   = "gemma4"
MODEL_PROLOG_GENERATOR  = "qwen3-coder:480b-cloud"

# Pipeline settings
PROLOG_MAX_RETRIES  = 3  # How many times to retry Prolog generation on validation failure
SWIPL_TIMEOUT       = 10 # Seconds before a Prolog validation call is killed

# Paths
PROJECT_ROOT        = os.path.dirname(os.path.abspath(__file__))
PROLOG_DIRECTORY    = os.path.join(PROJECT_ROOT, "prolog")