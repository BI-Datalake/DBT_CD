# Estado do projeto DBT_CD

Atualizado em 26/11/2026. Atualizar ao fim de cada entrega.

## Ambiente
- DB_CDS, warehouse CDS_WH (X-SMALL, auto-suspend 60 s), limite CDS_RM. Schemas STG, TRUSTED, REFINED e APP.
- Nomes de database/warehouse provisórios: se mudarem, ajustar `profiles.yml` e o AGENTS.md.

## Decisões fechadas
| Tema | Decisão |
|---|---|
| Corte do consumo | `consumo_inicio = 202501` (variável) |
| Corte das entradas (fornecedor) | `entradas_inicio = 202401`, variável separada. Teste de 26/11: em set/2026, 425 de 426 itens consumidos tinham entrada a partir de 2025 |
| Regra do SD3 | TM >= 500 soma; fora TM 999 e CF RE4/DE4. TM 500 não muda nenhum número; as exclusões só mudam Jundiaí (a partir de jul/2026) |
| Estrutura | Projeto separado do DBT_CUSTOS, mesma arquitetura. Procedures, tasks, semantic view e CFG ficam fora do dbt |

## Impacto da regra do SD3 (CSV de 25/11/2026)
Santos e Cuiabá: diferença zero em todos os meses. Jundiaí: +R$ 3.225,66 (jul), +R$ 18.355,93 (ago), +R$ 18.343,52 (set), +R$ 27.642,35 (out). Origem: CC 27160050, transferência armazém 02 → 16 (DE4 R$ 28.376,31 menos RE4 R$ 10.032,79 em set). O consumo real do posto está nas requisições RE0 do armazém 16 (R$ 23.287,06 em set).

## Modelos existentes
**Seeds:** dim_cd_centro_custo (53 CCs: Santos 10, Jundiaí 25, Cuiabá 18), tes_entrada (6 TES).
**STG:** stg_sd3_consumo (tabela), stg_sd1_entradas, stg_sa2_fornecedor, stg_ctt_centro_custo, stg_sb1_produto, stg_sys_company_filiais.
**TRUSTED / REFINED:** ainda não criados.

## Próximos passos
1. Rodar `dbt deps` e `dbt seed`, depois `dbt build --select stg_sd3_consumo+` e conferir a soma por CD e mês contra o CSV (coluna C da consulta de 25/11).
2. TRUSTED: consumo por período (MES/SEMANA, CC e total do CD), variação, fornecedor (com rastreio de transferências até 2 níveis) e análise (motivo da variação).
3. REFINED: fct_consumo_insumos_cd, dim_cd_centro_custo, dim_periodo (com período anterior e mesmo mês do ano anterior, para tendências).
4. Testes: soma dos CCs = total do CD; chave única na análise.
5. Mover para app/ os scripts da procedure, da semantic view, do log e da CFG, apontando para DB_CDS.

## Pendências de negócio
- Confirmar com a área se 25100140 (Afastados) e 25100110 (PCD) entram em Cuiabá.
- Destinatários por CD: depois da validação das áreas.
- Posse das procedures (EXECUTE AS CALLER, dono SYSADMIN) antes de ligar as tasks.
- Top insumos: a planilha da Thais é de saldo em estoque (SB9/SB2), não de consumo. Decidir o formato com a área.
