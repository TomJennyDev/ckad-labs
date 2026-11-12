# Domain 1 — Application Design and Build (20%)

Bám các năng lực: build images, workload controllers, init/sidecar patterns, ephemeral/persistent/projected volumes.

| Lab | Nội dung | Tài liệu |
|---|---|---|
| D1-001 | Build image + load kind | [Bài 001](labs/001-image-build/README.md) |
| D1-002 | Deployment vs Job vs CronJob | [Bài 002](labs/002-workload-choice/README.md) |
| D1-003 | Init container | [Bài 003](labs/003-init-container/README.md) |
| D1-004 | Sidecar logs | [Bài 004](labs/004-sidecar-logs/README.md) |
| D1-005 | emptyDir + PVC | [Bài 005](labs/005-volumes/README.md) |
| D1-006 | Native sidecar lifecycle + Job | [Bài 006](labs/006-native-sidecar/README.md) |
| D1-007 | Projected Volumes + bound token | [Bài 007](labs/007-projected-volumes/README.md) |
| D1-008 | Job retry, backoffLimit và failure handling | [Bài 008](labs/008-job-retry-backoff/README.md) |

D1-009–D1-012 (planned): CronJob concurrency, DaemonSet, image digest, mock exam.

Run: `./env/kind/up.sh`, `./ckad domain start D1-008`, `./ckad domain check D1-008`, `./ckad domain solve D1-008`, `./ckad domain reset D1-008`.

Trạng thái: [STATUS.json](../STATUS.json). Chưa xác nhận end-to-end trên kind.

