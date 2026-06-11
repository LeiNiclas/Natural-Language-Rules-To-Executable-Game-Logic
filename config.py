import os

# ---------------------------------------------------------------------------
# Model selection
# ---------------------------------------------------------------------------
MODEL_RULE_GENERATOR        = "gemma4:31b-cloud"
MODEL_RULE_VERIFIER         = "gpt-5"
MODEL_RULE_REPAIRER         = "gpt-5"
MODEL_XML_STRUCTURER        = "gemma4:31b-cloud"
MODEL_PROLOG_GENERATOR      = "gemma4:31b-cloud"
MODEL_MANUAL_RULES_TO_XML   = "gpt-5"
MODEL_TEST_GENERATOR        = "gpt-5"   # GPT-5 produces more reliable Prolog goals

# ---------------------------------------------------------------------------
# API keys & backend flags
# ---------------------------------------------------------------------------
OPENAI_API_KEY              = os.getenv("OPENAI_API_KEY", "")

USE_OPENAI_FOR_VERIFIER          = True
USE_OPENAI_FOR_REPAIRER          = True
USE_OPENAI_FOR_MANUAL_RULES      = True
USE_OPENAI_FOR_TEST_GENERATOR    = True

# ---------------------------------------------------------------------------
# Pipeline settings
# ---------------------------------------------------------------------------
PROLOG_MAX_RETRIES   = 3    # Max attempts to generate valid Prolog
RULEBOOK_MAX_RETRIES = 3    # Max verify/repair cycles for the rulebook
SWIPL_TIMEOUT        = 10   # Seconds before a swipl call is killed

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
PROJECT_ROOT       = os.path.dirname(os.path.abspath(__file__))
PROLOG_DIRECTORY   = os.path.join(PROJECT_ROOT, "prolog")