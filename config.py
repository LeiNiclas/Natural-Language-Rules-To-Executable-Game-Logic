import os

# Model selection
MODEL_RULE_GENERATOR    = "gemma4:31b-cloud"
MODEL_RULE_VERIFIER     = "gpt-5"  # Now using GPT-5
MODEL_RULE_REPAIRER     = "gpt-5"  # Also use GPT-5 for repairs
MODEL_JSON_STRUCTURER   = "gemma4:31b-cloud"
MODEL_PROLOG_GENERATOR  = "nemotron-3-super:cloud"
MODEL_MANUAL_RULES_TO_JSON = "gpt-5"  # For manual rules conversion

# API settings
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")  # Set your OpenAI API key
USE_OPENAI_FOR_VERIFIER = True  # Use OpenAI for verifier and repairer
USE_OPENAI_FOR_REPAIRER = True
USE_OPENAI_FOR_MANUAL_RULES = True

# Pipeline settings
PROLOG_MAX_RETRIES  = 3  # How many times to retry Prolog generation on validation failure
RULEBOOK_MAX_RETRIES = 3  # How many times to retry rulebook verification/repair
SWIPL_TIMEOUT       = 10 # Seconds before a Prolog validation call is killed

# Paths
PROJECT_ROOT        = os.path.dirname(os.path.abspath(__file__))
PROLOG_DIRECTORY    = os.path.join(PROJECT_ROOT, "prolog")