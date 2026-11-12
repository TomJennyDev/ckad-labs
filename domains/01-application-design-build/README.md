# Domain 1 — Application Design and Build (20%)

Bám 4 năng lực chính thức: build images; choose workload; init/sidecar patterns; ephemeral/persistent volumes.

| Lab | Nội dung | Tài liệu |
|---|---|---|
| D1-001 | Build image + load kind | [Bài 001](labs/001-image-build/README.md) |
| D1-002 | Deployment vs Job vs CronJob | [Bài 002](labs/002-workload-choice/README.md) |
| D1-003 | Init container | [Bài 003](labs/003-init-container/README.md) |
| D1-004 | Sidecar logs | [Bài 004](labs/004-sidecar-logs/README.md) |
| D1-005 | emptyDir + PVC | [Bài 005](labs/005-volumes/README.md) |

Chạy `./env/kind/up.sh` rồi `./ckad domain list`, `./ckad domain start D1-001`, `./ckad domain check D1-001`, `./ckad domain solve D1-001`, `./ckad domain reset D1-001`.

D1-006–D1-012: native sidecar, projected volumes, Job retry, CronJob concurrency, DaemonSet, container image digest, mock exam.

Trạng thái: [domains/STATUS.json](../STATUS.json). Các bài đã viết nhưng chưa xác nhận chạy end-to-end trên kind.
