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
| D1-009 | CronJob concurrency, missed schedules và time zone | [Bài 009](labs/009-cronjob-concurrency/README.md) |
| D1-010 | DaemonSet node telemetry agents, scheduling và rolling update | [Bài 010](labs/010-daemonset-node-agents/README.md) |
| D1-011 | Image digest pinning và reproducible Deployment | [Bài 011](labs/011-image-digest-pinning/README.md) |
| D1-012 | Mini mock exam tổng hợp 5 nhiệm vụ | [Bài 012](labs/012-domain1-mock-exam/README.md) |

**Domain 1: 12/12 lab đã có mã nguồn.** Bài tiếp theo: D2-001 (Application Deployment). Chưa xác nhận end-to-end trên kind.

Run: `./env/kind/up.sh`, `./ckad domain start D1-012`, `./ckad domain check D1-012`, `./ckad domain solve D1-012`, `./ckad domain reset D1-012`.

Trạng thái: [STATUS.json](../STATUS.json).
