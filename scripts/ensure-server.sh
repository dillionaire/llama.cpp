#!/usr/bin/env bash
# ensure-server.sh — rebuild llama-server from a known-stable commit if the binary is missing.
# Used as ExecStartPre in chat-model.service and embedding-server.service.
#
# The working tree may contain experimental commits (audio, conformer, etc.)
# that could produce a broken binary. This script uses a temporary git worktree
# with its own build directory, then copies the binary into the production path.

set -euo pipefail

REPO_DIR="/home/thomas/code/chonk/llama.cpp"
BUILD_DIR_NAME="build-vulkan"
BINARY="${REPO_DIR}/${BUILD_DIR_NAME}/bin/llama-server"

# Latest stable commit rebased on upstream.
# Update this when experimental work is merged or upstream moves again.
STABLE_REF="2496f9c14"

if [[ -x "$BINARY" ]]; then
    echo "ensure-server: llama-server exists, skipping build"
    exit 0
fi

echo "ensure-server: llama-server missing, rebuilding from stable ref ${STABLE_REF}..."

WORKTREE_DIR=$(mktemp -d /tmp/llama-server-rebuild.XXXXXX)
trap 'cd /; git -C "${REPO_DIR}" worktree remove --force "${WORKTREE_DIR}" 2>/dev/null || rm -rf "${WORKTREE_DIR}"' EXIT

git -C "${REPO_DIR}" worktree add --detach "${WORKTREE_DIR}" "${STABLE_REF}" 2>&1

STABLE_BUILD="${WORKTREE_DIR}/${BUILD_DIR_NAME}"

cmake -B "${STABLE_BUILD}" -S "${WORKTREE_DIR}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_VULKAN=ON \
    -DGGML_HIP=OFF \
    -DGGML_CUDA=OFF \
    -DLLAMA_CURL=ON \
    -DLLAMA_BUILD_TESTS=OFF \
    2>&1

cmake --build "${STABLE_BUILD}" --target llama-server -j16 2>&1

BUILT="${STABLE_BUILD}/bin/llama-server"
if [[ ! -x "$BUILT" ]]; then
    echo "ensure-server: rebuild FAILED — binary not produced" >&2
    exit 1
fi

# Copy binary and its shared libs into the production build dir.
mkdir -p "${REPO_DIR}/${BUILD_DIR_NAME}/bin"
cp -f "${BUILT}" "${BINARY}"
for lib in "${STABLE_BUILD}"/bin/lib*.so*; do
    [[ -e "$lib" ]] && cp -af "$lib" "${REPO_DIR}/${BUILD_DIR_NAME}/bin/"
done

if [[ -x "$BINARY" ]]; then
    echo "ensure-server: rebuild from ${STABLE_REF} succeeded, installed to ${BINARY}"
else
    echo "ensure-server: copy failed" >&2
    exit 1
fi
