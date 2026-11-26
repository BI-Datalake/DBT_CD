# DBT_CD
Projeto dbt do relatório automático de consumo de insumos dos CDs (Santos, Jundiaí e Cuiabá), sobre Snowflake (DB `DB_CDS`, WH `CDS_WH`, role `SYSADMIN`). Lê o consumo (SD3) e as entradas de nota (SD1) do TOTVS Protheus e entrega as tabelas que alimentam o e-mail mensal e semanal.

## Estrutura
| Pasta/arquivo | Conteúdo |
|---|---|
| `AGENTS.md` | Instruções fixas para o Cortex Code, carregadas em toda conversa. Só o que é estável |
| `DBT_CD/` | Projeto dbt (models, seeds, macros, tests, dbt_project.yml, profiles.yml) |
| `DBT_CD/docs/estado_projeto.md` | Modelos existentes, decisões e pendências. Atualizar a cada entrega |
| `app/` | Fora do dbt: procedures, tasks, semantic view, log da IA, CFG de destinatários |
| `Setup_CDS.sql` | Cria warehouse, database, schemas e limite de créditos |

## Camadas
- **Origens** (`TOTVS_PROTHEUS.TRUSTED`): só leitura, via `source()`.
- **STG**: limpeza e tipagem. `stg_sd3_consumo` é tabela porque lê a SD3010.
- **TRUSTED**: regras de negócio (consumo por período, variação, fornecedor, motivo).
- **REFINED**: `fct_`/`dim_` lidos pela procedure do e-mail e pela semantic view.

## Checklist operacional
- [ ] **Novo CD ou centro de custo**: incluir em `seeds/dim_cd_centro_custo.csv` e rodar `dbt seed`.
- [ ] **Nova TES de compra ou transferência**: incluir em `seeds/tes_entrada.csv`.
- [ ] **Destinatários**: tabela `CFG_RELATORIO_INSUMOS_CD` (schema APP).
- [ ] Rodar `dbt build --project-dir DBT_CD` e conferir os testes (soma dos CCs = total do CD).

## Executar
```
dbt deps --project-dir DBT_CD
dbt seed --project-dir DBT_CD
dbt build --project-dir DBT_CD --select stg_sd3_consumo+
```
Nos Workspaces, use comandos simples, sem `&&`, pipes ou `cd`, e sem `dbt debug`.

## Trabalhando com o Cortex Code
- O `AGENTS.md` entra sozinho em toda conversa: não cole prompts longos.
- Regra nova e estável vai no `AGENTS.md`. Status, números e pendências vão em `docs/estado_projeto.md`.
- Para economizar créditos: `--select` em vez do projeto inteiro, `LIMIT` e período curto nos testes, previews com `P_ENVIAR = FALSE`.

## Segurança
Nunca alterar as origens (`TOTVS_PROTHEUS`) nem `DOC_AI_DB.LAB` (produção atual). DROP, TRUNCATE ou DELETE fora de STG, TRUSTED ou REFINED só com autorização.
