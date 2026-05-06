# Frozen llama.cpp builds

## Build directory inventory

| Path | Status | Backend | Git ref | Rebuilt by ensure-server.sh? | Consumers |
|---|---|---|---|---|---|
| `build-vulkan/` | Live | Vulkan (RADV, Mesa) | tracks HEAD / `STABLE_REF` in `scripts/ensure-server.sh` | **YES** — self-heal target | `chat-model.service` (prod :8085) |
| `build-vulkan/bin.b9046.bak/` | Archived 2026-05-06 | Vulkan (RADV, Mesa) | b9046 (`a290ce626`) | NO | Pre-update backup binary, kept for short-window rollback |
| `build-hip/` | Live (legacy backend) | HIP / ROCm | older ref | NO | `embedding-server.service` on :8082 (embeddinggemma-300M) — still uses HIP, do not remove |
| `build-hip/bin.audio.bak/` | Archived | HIP | pre-heretic fallback | NO | Dormant backup from earlier rollback paths |

## Policy

- **`build-vulkan/` tracks upstream.** `scripts/ensure-server.sh` rebuilds from `STABLE_REF` when the binary is missing. Production service uses this path.
- **`build-hip/` is not Gemma-specific.** Embedding server still consumes it. Leave intact until embedding backend is independently migrated.
