# Domain 1 — Application Design and Build (20%)

Bám 4 năng lực: build images; choose workload; init/sidecar patterns; ephemeral/persistent volumes.

| Lab | Nội dung | Tài liệu |
|---|---|---|
| D1-001 | Build image + load kind | [Bài 001](labs/001-image-build/README.md) |
| D1-002 | Deployment vs Job vs CronJob | [Bài 002](labs/002-workload-choice/README.md) |
| D1-003 | Init container | [Bài 003](labs/003-init-container/README.md) |
| D1-004 | Sidecar logs | [Bài 004](labs/004-sidecar-logs/README.md) |
| D1-005 | emptyDir + PVC | [Bài 005](labs/005-volumes/README.md) |
| D1-006 | Native sidecar lifecycle + Job | [Bài 006](labs/006-native-sidecar/README.md) |

Chạy `./env/kind/up.sh`, `./ckad domain start D1-006`, `./ckad domain check D1-006`, `./ckad domain solve D1-006`, `./ckad domain reset D1-006`.

D1-007–D1-012 (planned): projected volumes, Job retry, CronJob concurrency, DaemonSet, image digest, mock exam.

Trạng thái: [STATUS.json](../STATUS.json). Chưa xác nhận end-to-end trên kind.
