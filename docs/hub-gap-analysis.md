# Hub Empower — Análise de Lacunas vs. Potbelly AI Hub

Comparação entre o `dti-potbelly-ai-hub` (referência, o mais completo) e o `empower` (novo hub). Lista tudo o que pode ser adicionado ao Empower, filtrado pelo contexto dele: produto mobile (`MyIsn.Android`, `MyIsn.iOS`) mais um backend mock (`Mockoon`), sem backend ou web próprios.

Data: 2026-10-01

## Resumo comparativo

| Área | Potbelly AI Hub | Empower |
|---|---|---|
| Comandos slash | 28 (`/pb-*`, `/validate-workspace`, `/sync-context`) | 7 (`speckit.*`) |
| Agentes | 16 | 1 (`product-orchestrator`) |
| Skills | 30 | 9 |
| Hooks | 2 (uso de tokens) | 2 (um-repo-por-sessão, checagem de upstream) |
| Templates | 22 | 0 |
| ADRs | 11 | 0 |
| Constituição | 441 + 463 linhas | 157 + 151 linhas |
| Camada de navegação `.ai/` | sim | não |
| Ledger de governança | sim | não |

## Referências quebradas (encontradas na análise)

> **Resolvido em 2026-10-01** — `docs/lean-artifact-policy.md` e `.claude/agents/agents.md` foram criados (ver P0).

---

## P0 — Corrigir antes de expandir (✅ concluído em 2026-10-01)

| # | Item | Origem no Potbelly |
|---|---|---|
| 1 | Criar `docs/lean-artifact-policy.md` (o CLAUDE.md já aponta para ele) | `documentation/lean-artifact-policy.md` |
| 2 | Criar o catálogo de agentes `.claude/agents/agents.md` (também já referenciado) | `.claude/agents/` |
| 3 | Criar `docs/governance/current-hub-decisions.md`: ledger de decisões de uma página; os demais docs linkam para ele em vez de repetir a regra (alinha com a regra de DRY de governança) | `documentation/governance/current-hub-decisions.md` |
| 4 | Adicionar a regra "Artifact Minimalism" no CLAUDE.md (hoje só existe a Lean Policy) | `CLAUDE.md` do Potbelly |

## P1 — Alto valor, encaixa no contexto mobile

### Comandos e fluxo

| Item | O que faz | Por que no Empower |
|---|---|---|
| `/validate-workspace` ✅ | Checa se `MyIsn.Android`, `MyIsn.iOS` e `Mockoon` estão clonados, em qual branch e se estão limpos ou sujos | O `workspace.config.json` já existe, então é barato |
| `/sync-context` ✅ | Auditoria de drift em modo audit-first entre docs, comandos e constituição; só aplica correções após aprovação | 8 docs de referência vão envelhecer |
| `/speckit.validation-plan` | Gera o `validation-plan.md` para fluxos de risco | Login/Jumio, ISN ID wallet, geolocalização, certificados, formulários |
| `/speckit.validate` | Organiza evidências (screenshots, saída de testes) em `pr-evidence.md` | O `/speckit.review` hoje mistura as duas tarefas |
| `/quick-fix` | Caminho curto para teste quebrado ou bug pequeno, sem o fluxo completo | Evita o fluxo completo de spec para trabalho trivial |
| `/bug-report` | Rascunha um Bug do Azure DevOps a partir de contexto colado no chat | Complementa o `po-work-item-publish` |

### Agentes (hoje só existe o `product-orchestrator`)

| Agente | Papel |
|---|---|
| `code-reviewer` ✅ | Sustenta a revisão de código do `/speckit.review` |
| `qa-reviewer` ✅ | Rastreia critérios de aceite até testes reais |
| `cross-platform-reviewer` ✅ | Compara Android vs iOS e aponta drift (caso real: feature flag do LMS com nome diferente em cada plataforma) |
| `current-state-analyzer` | Formaliza o que o `/document-projects` faz hoje (`technical-refinement/*/current-state.md`) |
| `documentation-maintainer` | Mantém o `docs/` alinhado com a realidade |
| `code-refactor-planner` | Planeja refactors sem mudar comportamento |

### Skills de metodologia (o Empower só tem skills de orquestração)

| Skill | Finalidade |
|---|---|
| `bdd-specification` ✅ | Critérios de aceite Given/When/Then padronizados |
| `pbi-clarification` | Poucas perguntas focadas; fecha atualizando a spec |
| `qa-review` ✅ | Rastreabilidade critério → teste real |
| `quality-gates` | Exige evidência antes de avançar |
| `safe-refactoring` | Refatorar sem mudar comportamento |
| `security-review` | Mobile: tokens, biometria, Jumio/KYC, PII |
| `cross-platform-impact` | Formalizar o núcleo do `orchestrate-feature` como skill reutilizável |
| `android-expert` / `ios-expert` | Camada de roteamento que lê o CLAUDE.md/docs de cada repo; o `speckit.implement` já delega para skills dos repos, mas falta essa camada |

### Templates — ❌ descartado (decisão do usuário, 2026-10-01: os comandos continuam apontando para a estrutura inline)

`spec`, `clarify`, `plan`, `tasks`, `pr-evidence`, `pr-summary`, `validation-plan`, `bugs`, `tech-debt`, `platform-spec`, `branch-preparation`.

> **Reavaliado em 2026-10-01:** os comandos `speckit.specify`, `plan` e `review` já definem a estrutura de títulos inline. Criar `templates/` agora duplicaria essa estrutura (contra a regra DRY). Só vale a pena se os comandos passarem a apontar para os templates em vez de embutir a estrutura.

Hoje cada comando provavelmente reinventa a estrutura de títulos. No Potbelly, o `branch-preparation` é uma pré-condição de segurança antes da implementação.

## P2 — Governança e rastreabilidade

| Item | Detalhe |
|---|---|
| `decisions/adr/` ✅ | README + `ADR-Template` para decisões que cruzam repos. Candidatos reais: split do LMS, contrato do Mockoon, estratégia de feature flag |
| Regra "código de produto nunca referencia o Hub" | Hard rule 11 do Potbelly. Nenhum comentário/string/teste em `MyIsn.*` ou `Mockoon` citando `.claude`, `specs/` etc. Falta na constituição do Empower |
| Seções que faltam na constituição ✅ | Platform Autonomy (Potbelly §13), Segurança e Privacidade (§11), Compatibilidade de API e Impacto no Cliente (§8, relevante porque apps já instalados convivem com contratos novos). Empower: 157 linhas vs 441 |
| Hard rules explícitas no CLAUDE.md | Sem deploy, sem commit/push como efeito colateral, sem mudanças em CI/signing, sem PR automático. Parte está no `deny` do `settings.json`, mas falta como regra escrita |
| Playbook de MCP ("manual, opt-in") | As skills do Empower usam o Azure DevOps MCP; documentar o que pode ser chamado automaticamente e o que exige pedido explícito |
| Cadeia de pré-requisitos por plataforma | `--platform ios\|android\|mockoon` obrigatório em plan, tasks, implement, review e PR. Hoje o `enforce-one-repo-per-session` só atua na hora de escrever |
| Camada de navegação `.ai/` | `repo.yaml`, `symbols.yaml`, `domains/`, `folders/`. Só vale a pena com mais de ~20 artefatos |

## P3 — Automação e relatórios

| Item | Detalhe |
|---|---|
| Hooks de uso de tokens | `token-log-start/stop.sh` + `generate-token-report.py`, com limite diário. Útil com vários devs |
| `docs/improvements.md` | Caixa de entrada de ideias de melhoria do hub |
| Skills de diagrama | `architecture-diagrams` (Mermaid), `drawio-diagram-generation`, `.github/instructions/mermaid.instructions.md`. Úteis para o `cross-platform-flows.md` |
| `/observability-review` | O Empower tem `docs/observability.md`, mas nenhuma revisão; cobriria logging/analytics dos apps |
| `.github/copilot-instructions.md` na raiz | Se o time usa Copilot (o Mockoon já tem um) |

## P4 — Provavelmente não se aplica

- `backend-expert`, `web-expert`, `potbelly-expert`, `cloud-observability-review`: o Empower não tem backend nem web próprios.
- `swagger-standalone-docs`, `script/aws-dashboard-pipeline`: específicos de AWS/Lambda.
- Regras de `x-channel`: específicas do Potbelly.
- Pastas `discovery/` (DISC-*) e `analysis/` (AN-*): só se discovery de arquitetura antes do PBI virar prática; o `technical-refinement` cobre parte disso hoje.
- `/pb-ado-export-feature-csv`, `/functional-ingest`: só se houver um backlog legado em CSV para converter.

---

## Status final (2026-10-01)

Implementado: todo o P0, P1 (exceto templates, descartado) e P2, mais os itens de P3 não excluídos.

| Item | Onde |
|---|---|
| Comandos | `/validate-workspace`, `/sync-context`, `/speckit.validation-plan`, `/speckit.validate`, `/quick-fix`, `/bug-report`, `/observability-review` |
| Agentes | `code-reviewer`, `qa-reviewer`, `cross-platform-reviewer`, `current-state-analyzer`, `documentation-maintainer`, `code-refactor-planner` |
| Skills | `bdd-specification`, `pbi-clarification`, `qa-review`, `quality-gates`, `safe-refactoring`, `security-review`, `cross-platform-impact`, `android-expert`, `ios-expert`, `architecture-diagrams`, `drawio-diagram-generation` |
| Governança | lean policy, ledger, ADRs, constituição §9–§11, regra "código de produto não referencia o hub", hard rules e MCP no ledger, repo-scope por run (§11) |
| Infra | hooks de tokens, `docs/improvements.md`, `.ai/`, `.github/copilot-instructions.md` e `mermaid.instructions.md` |

Não portado: o gerador de relatório HTML de tokens (`generate-token-report.py`, 599 linhas, acoplado ao Potbelly); os CSVs de tokens são locais e abrem em qualquer planilha.

Fora do escopo (decisão do usuário, 2026-10-01): dashboard de release/sprint, `vendor-docs/`, `.claude/context/`, Playwright MCP e `templates/`.

Observação: a Lean Artifact Policy pede aprovação antes de criar mais de 2 arquivos; o lote foi autorizado explicitamente pelo usuário.
