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
| Scripts / dashboards | 3 | 0 |
| Vendor docs | sim (Olo) | não |

## Referências quebradas (encontradas na análise)

O `CLAUDE.md` aponta para arquivos que **não existem**:

- `docs/lean-artifact-policy.md`
- `.claude/agents/agents.md`

---

## P0 — Corrigir antes de expandir

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
| `/validate-workspace` | Checa se `MyIsn.Android`, `MyIsn.iOS` e `Mockoon` estão clonados, em qual branch e se estão limpos ou sujos | O `workspace.config.json` já existe, então é barato |
| `/sync-context` | Auditoria de drift em modo audit-first entre docs, comandos e constituição; só aplica correções após aprovação | 8 docs de referência vão envelhecer |
| `/speckit.validation-plan` | Gera o `validation-plan.md` para fluxos de risco | Login/Jumio, ISN ID wallet, geolocalização, certificados, formulários |
| `/speckit.validate` | Organiza evidências (screenshots, saída de testes) em `pr-evidence.md` | O `/speckit.review` hoje mistura as duas tarefas |
| `/quick-fix` | Caminho curto para teste quebrado ou bug pequeno, sem o fluxo completo | Evita o fluxo completo de spec para trabalho trivial |
| `/bug-report` | Rascunha um Bug do Azure DevOps a partir de contexto colado no chat | Complementa o `po-work-item-publish` |

### Agentes (hoje só existe o `product-orchestrator`)

| Agente | Papel |
|---|---|
| `code-reviewer` | Sustenta a revisão de código do `/speckit.review` |
| `qa-reviewer` | Rastreia critérios de aceite até testes reais |
| `cross-platform-reviewer` | Compara Android vs iOS e aponta drift (caso real: feature flag do LMS com nome diferente em cada plataforma) |
| `current-state-analyzer` | Formaliza o que o `/document-projects` faz hoje (`technical-refinement/*/current-state.md`) |
| `documentation-maintainer` | Mantém o `docs/` alinhado com a realidade |
| `code-refactor-planner` | Planeja refactors sem mudar comportamento |

### Skills de metodologia (o Empower só tem skills de orquestração)

| Skill | Finalidade |
|---|---|
| `bdd-specification` | Critérios de aceite Given/When/Then padronizados |
| `pbi-clarification` | Poucas perguntas focadas; fecha atualizando a spec |
| `qa-review` | Rastreabilidade critério → teste real |
| `quality-gates` | Exige evidência antes de avançar |
| `safe-refactoring` | Refatorar sem mudar comportamento |
| `security-review` | Mobile: tokens, biometria, Jumio/KYC, PII |
| `cross-platform-impact` | Formalizar o núcleo do `orchestrate-feature` como skill reutilizável |
| `android-expert` / `ios-expert` | Camada de roteamento que lê o CLAUDE.md/docs de cada repo; o `speckit.implement` já delega para skills dos repos, mas falta essa camada |

### Templates (o Empower não tem pasta `templates/`)

`spec`, `clarify`, `plan`, `tasks`, `pr-evidence`, `pr-summary`, `validation-plan`, `bugs`, `tech-debt`, `platform-spec`, `branch-preparation`.

Hoje cada comando provavelmente reinventa a estrutura de títulos. No Potbelly, o `branch-preparation` é uma pré-condição de segurança antes da implementação.

## P2 — Governança e rastreabilidade

| Item | Detalhe |
|---|---|
| `decisions/adr/` | README + `ADR-Template` para decisões que cruzam repos. Candidatos reais: split do LMS, contrato do Mockoon, estratégia de feature flag |
| Regra "código de produto nunca referencia o Hub" | Hard rule 11 do Potbelly. Nenhum comentário/string/teste em `MyIsn.*` ou `Mockoon` citando `.claude`, `specs/` etc. Falta na constituição do Empower |
| Seções que faltam na constituição | Platform Autonomy (Potbelly §13), Segurança e Privacidade (§11), Compatibilidade de API e Impacto no Cliente (§8, relevante porque apps já instalados convivem com contratos novos). Empower: 157 linhas vs 441 |
| Hard rules explícitas no CLAUDE.md | Sem deploy, sem commit/push como efeito colateral, sem mudanças em CI/signing, sem PR automático. Parte está no `deny` do `settings.json`, mas falta como regra escrita |
| Playbook de MCP ("manual, opt-in") | As skills do Empower usam o Azure DevOps MCP; documentar o que pode ser chamado automaticamente e o que exige pedido explícito |
| Cadeia de pré-requisitos por plataforma | `--platform ios\|android\|mockoon` obrigatório em plan, tasks, implement, review e PR. Hoje o `enforce-one-repo-per-session` só atua na hora de escrever |
| Camada de navegação `.ai/` | `repo.yaml`, `symbols.yaml`, `domains/`, `folders/`. Só vale a pena com mais de ~20 artefatos |

## P3 — Automação e relatórios

| Item | Detalhe |
|---|---|
| Hooks de uso de tokens | `token-log-start/stop.sh` + `generate-token-report.py`, com limite diário. Útil com vários devs |
| Dashboard de release / sprint | `/release-dashboard` + `script/ado-analyzer`: story points, cycle time, rollover por plataforma. Só se a gestão quiser essas métricas |
| `docs/improvements.md` | Caixa de entrada de ideias de melhoria do hub |
| Skills de diagrama | `architecture-diagrams` (Mermaid), `drawio-diagram-generation`, `.github/instructions/mermaid.instructions.md`. Úteis para o `cross-platform-flows.md` |
| `/observability-review` | O Empower tem `docs/observability.md`, mas nenhuma revisão; cobriria logging/analytics dos apps |
| `.github/copilot-instructions.md` na raiz | Se o time usa Copilot (o Mockoon já tem um) |
| `vendor-docs/` | Docs de terceiros (Jumio etc.) com índice em `.claude/context/`, como o Potbelly faz com o Olo |
| `.claude/context/` | Contexto só para LLM (README + `functional/` + `vendor-docs/`), separado do `docs/` humano |
| Playwright MCP | Validação assistida; provavelmente não se aplica (sem web) |

## P4 — Provavelmente não se aplica

- `backend-expert`, `web-expert`, `potbelly-expert`, `cloud-observability-review`: o Empower não tem backend nem web próprios.
- `swagger-standalone-docs`, `script/aws-dashboard-pipeline`: específicos de AWS/Lambda.
- Regras de `x-channel`: específicas do Potbelly.
- Pastas `discovery/` (DISC-*) e `analysis/` (AN-*): só se discovery de arquitetura antes do PBI virar prática; o `technical-refinement` cobre parte disso hoje.
- `/pb-ado-export-feature-csv`, `/functional-ingest`: só se houver um backlog legado em CSV para converter.

---

## Ordem sugerida

1. P0 (4 itens): poucos arquivos, fecha as referências quebradas.
2. `/validate-workspace`, `/sync-context`, `templates/`.
3. Agentes de review + skills `bdd-specification` e `qa-review`.
4. ADRs e seções faltantes da constituição.

Observação: a Lean Artifact Policy pede aprovação antes de criar mais de 2 arquivos, então cada lote deve ser proposto primeiro.
