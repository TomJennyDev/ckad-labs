# CKAD roadmap: 60 practical labs, basic to advanced

**Hoàn thành mã nguồn:** 001–006. **Chưa triển khai:** 007–060. Tiến độ là số lab có manifest/checker, không phải số lab đã chạy được CI.

| ID | Chủ đề | Status |
|---|---|---|
| 001 | [Pod and kubectl](labs/001-pod-basics/README.md) | Implemented |
| 002 | [Deployment rollout](labs/002-deployment-rollout/README.md) | Implemented |
| 003 | [ConfigMap Secret](labs/003-configmap-secret/README.md) | Implemented |
| 004 | [Probes](labs/004-probes/README.md) | Implemented |
| 005 | [Job CronJob](labs/005-job-cronjob/README.md) | Implemented |
| 006 | [Service EndpointSlice](labs/006-service-endpoints/README.md) | Implemented |
| 007 | Init containers | Planned |
| 008 | Sidecar shared volumes | Planned |
| 009 | Resources and quota | Planned |
| 010 | Debug image pulls | Planned |
| 011 | Pod lifecycle | Planned |
| 012 | Signals termination | Planned |
| 013 | Image pull policy | Planned |
| 014 | Build and registry | Planned |
| 015 | emptyDir and projected volumes | Planned |
| 016 | Persistent volumes | Planned |
| 017 | CRD inspection | Planned |
| 018 | Scheduling constraints | Planned |
| 019 | PodDisruptionBudget | Planned |
| 020 | DaemonSet workloads | Planned |
| 021 | RollingUpdate tradeoffs | Planned |
| 022 | Rollout history | Planned |
| 023 | Canary traffic splitting | Planned |
| 024 | Blue green deployment | Planned |
| 025 | maxSurge and maxUnavailable | Planned |
| 026 | Helm values | Planned |
| 027 | Helm rollback | Planned |
| 028 | Kustomize overlays | Planned |
| 029 | Resource field ownership | Planned |
| 030 | Apply strategies | Planned |
| 031 | Config refresh | Planned |
| 032 | Secret rotation | Planned |
| 033 | Projected service account tokens | Planned |
| 034 | Role and RoleBinding | Planned |
| 035 | SecurityContext | Planned |
| 036 | ReadOnlyRootFilesystem | Planned |
| 037 | Linux capabilities | Planned |
| 038 | NetworkPolicy ingress | Planned |
| 039 | NetworkPolicy egress | Planned |
| 040 | Quota admission | Planned |
| 041 | CrashLoopBackOff | Planned |
| 042 | ImagePullBackOff | Planned |
| 043 | Probe incidents | Planned |
| 044 | OOMKilled | Planned |
| 045 | kubectl debug | Planned |
| 046 | Logs and events | Planned |
| 047 | kubectl top and metrics | Planned |
| 048 | Rollback incident | Planned |
| 049 | Kubernetes API deprecations | Planned |
| 050 | Request tracing | Planned |
| 051 | ClusterIP port mapping | Planned |
| 052 | Headless Services | Planned |
| 053 | DNS troubleshooting | Planned |
| 054 | Ingress and TLS | Planned |
| 055 | Gateway API optional | Planned |
| 056 | NetworkPolicy diagnosis | Planned |
| 057 | HPA load | Planned |
| 058 | JSONPath and speed | Planned |
| 059 | Mock exam A | Planned |
| 060 | Mock exam B | Planned |

## CKAD official domain weights

| Domain | Weight | Roadmap |
|---|---:|---|
| Application Design and Build | 20% | 001, 005, 007–020 |
| Application Deployment | 20% | 002, 021–030 |
| Application Observability and Maintenance | 15% | 004, 010, 041–050 |
| Application Environment, Configuration and Security | 25% | 003, 009, 031–040 |
| Services and Networking | 20% | 006, 051–056 |

Các lab dùng diagram giải thích từng cơ chế; một mục tiêu duy nhất mỗi bài, có negative test. Tiến độ và domain mapping có thể được cập nhật khi triển khai các bài tiếp theo.
