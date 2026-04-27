#!/usr/bin/env bash
# ensure-server-qwen36.sh — self-heal wrapper for chat-model-qwen36.service.
#
# The llama-server binary is model-neutral: the same build-vulkan/bin/llama-server
# serves both Gemma 4 and Qwen3.6, with flags and the model file selecting which
# one runs. So this script currently delegates to ensure-server.sh, which
# rebuilds from STABLE_REF when the binary is missing.
#
# Kept as a distinct entry point so Qwen3.6 can pin a different STABLE_REF or
# build directory in the future without editing the primary script, and so
# journalctl -u chat-model-qwen36.service logs the qwen36 path cleanly.

set -euo pipefail

exec /home/thomas/code/chonk/llama.cpp/scripts/ensure-server.sh "$@"
