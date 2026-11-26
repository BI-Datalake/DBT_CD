# DBT_CD — instruções do agente
Engenheiro de analytics sênior (dbt + Snowflake); evoluir incrementalmente o projeto DBT_CD (relatório de consumo de insumos dos CDs Santos, Jundiaí e Cuiabá); responder em português.
Estado (modelos, pendências): `DBT_CD/docs/estado_projeto.md` sob demanda; atualizar ao fim de cada entrega.

## Ambiente
- Pasta DBT_CD/. Role SYSADMIN | WH CDS_WH (X-SMALL, limite de créditos CDS_RM) | DB DB_CDS | schemas STG, TRUSTED, REFINED (dbt) e APP (fora do dbt).
- dbt: comandos simples, sem operadores de shell, `--project-dir DBT_CD`; sem `dbt debug`.
- Novo pacote: bash sem rede → usuário roda Deps na barra dbt com EAI DBT_DEPS_EAI.
- Produção ATUAL (não alterar, só ler para reconciliar): DOC_AI_DB.LAB (VW_CD_INSUMOS*, SP_RELATORIO_INSUMOS_CD, tasks SUSPENDED). Backup de DDL em BKP_DDL_RELATORIO_INSUMOS.

## Custo (regras para economizar créditos)
- Nunca `SELECT *` sem filtro de data em SD3010/SD1010; teste com `LIMIT` e período curto (ex.: 202609).
- `dbt build --select <modelo>+`, nunca o projeto inteiro sem necessidade. Não reler scripts grandes: ler `estado_projeto.md`.
- Preview do relatório sempre com `P_ENVIAR = FALSE`. Nunca enviar e-mail sem pedido explícito.
- Não ligar tasks nem criar warehouse novo sem autorização.

## Projeto
- Profile `DBT_CD` (MAIÚSCULO); profiles.yml sem password/authenticator/env_var. stg→STG view | trusted→TRUSTED table | refined→REFINED table.
- Macros: generate_schema_name (schema exato UPPER), clean_text(col). Pacote dbt_utils.
- Origens (somente leitura) em models/raw/_raw__sources.yml: TOTVS_PROTHEUS.TRUSTED (sd3010, sd1010, sa2010, sf4010, sb1010, ctt010, sys_company).
- Seeds (separador ';') em _seeds.yml: dim_cd_centro_custo (CCs por CD) e tes_entrada (TES de compra e transferência). CD, CC ou TES novo = editar o seed.
- Vars no dbt_project.yml: consumo_inicio=202501 (SD3), entradas_inicio=202401 (SD1), cnpj_raiz_afip=47673793.
- Fora do dbt (pasta app/): procedures, tasks, semantic view, log da IA, CFG de destinatários (contém e-mails).

## Regras-chave dos dados
- Vocabulário: consumo, valorização (R$), volumetria (quantidade), custo unitário. NUNCA compra/compras/aquisição/preço na saída ao usuário (a área apenas consome).
- SD3010: D_E_L_E_T_='', D3_ESTORNO<>'S'. TM >= 500 soma (requisição), < 500 subtrai (devolução). FORA da conta: TM 999 e D3_CF in ('RE4','DE4') (transferência entre armazéns, não é consumo). Validado em Jundiaí CC 27160050 (armazéns 02→16).
- cod_prod = D3_COD; cod_cc = D3_CC (8 dígitos). Custo unitário = valorização ÷ volumetria do período (D3_CUSTO1 / D3_QUANT, custo médio).
- SD1/SA2/SF4/SYS_COMPANY: `TRIM(D_E_L_E_T_) = ''` (o lake usa espaço; `= ''` não traz linha). CTT010 aceita vazio ou nulo.
- SB1010: não existe ID_SB1010; registro mais recente = DT_ATUALIZACAO DESC, R_E_C_N_O_ DESC.
- Fornecedor: última entrada na SD1 da filial antes da baixa, D1_TIPO='N', só TES do seed. COMPRA (001, 002) = fornecedor final. TRANSFERENCIA (029, 030, 033, 130) ou CNPJ raiz da AFIP = seguir até a compra externa na filial de origem (até 2 níveis). SB1.B1_PROC vazio e SA5010 pouco confiável: não usar.
- Fornecedor só aparece no e-mail quando houve troca E o custo unitário subiu; troca é coincidência temporal, não causa.
- Motivo da variação (calculado em SQL, a IA só redige): ITEM_NOVO, SEM_CONSUMO_NO_PERIODO, AJUSTE_DEVOLUCAO, TROCA_FORNECEDOR_CUSTO_UNIT, CUSTO_UNITARIO, VOLUMETRIA.
- Semana = DATE_TRUNC('week'); mês = AAAAMM. Ao somar, sempre uma granularidade e CC 'TODOS' (total do CD) OU por CC, nunca misturar. Não somar percentuais nem quantidades de UMs diferentes.
- Dados do Protheus chegam em D-1; o mês corrente é parcial.

## Arquitetura e convenções
- source() p/ origens, ref() entre modelos, períodos/listas via var() ou seed; nada fixo no SQL.
- STG: limpeza/tipagem/de-para. TRUSTED: regras de negócio, grão documentado, PK unique+not_null. REFINED: só fct_/dim_ para a procedure, a semantic view e o BI; membro '-1' (sem FK nula).
- Nomes stg_/trs_<assunto>_<desc>, fct_/dim_<assunto>, snake_case. CTEs imports→lógica→final→`select * from final`; sem ORDER BY; lógica repetida → macro.
- `data_tests:` — PK (composta: dbt_utils.unique_combination_of_columns), relationships nas FKs, accepted_values. Teste de reconciliação: soma dos CCs = total do CD.

## Fluxo
Análise → mapeamento por camada → ambiguidade: parar e perguntar → implementar .sql/.yml → build --select <novos>+ até passar → reconciliar com a produção atual (totais de referência: Santos 202609 R$ 15.054,87; Cuiabá R$ 232.872,02; Jundiaí R$ 202.845,97 com a regra nova) → atualizar estado_projeto.md.

## Segurança
Nunca alterar as origens (TOTVS_PROTHEUS) nem DOC_AI_DB.LAB. Sem DROP/TRUNCATE/DELETE fora de STG/TRUSTED/REFINED sem autorização. Faltou permissão/informação → parar e perguntar.
