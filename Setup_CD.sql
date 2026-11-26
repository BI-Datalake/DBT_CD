-- ==============================================
-- CDS: Setup inicial do projeto dbt do relatório de insumos dos CDs
-- Rodar no Snowsight, na ordem. Não altera nada do DOC_AI_DB.LAB (produção atual).
-- Nomes ficam em variáveis do dbt_project.yml; se mudar aqui, muda lá.
-- ==============================================

-- ----------------------------------------------
-- 1. Limite de créditos (precisa de ACCOUNTADMIN)
--    AJUSTE a cota mensal conforme o orçamento. 10 é só um ponto de partida.
-- ----------------------------------------------
USE ROLE ACCOUNTADMIN;

CREATE RESOURCE MONITOR IF NOT EXISTS CDS_RM
    WITH CREDIT_QUOTA = 10
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS
        ON 75  PERCENT DO NOTIFY
        ON 100 PERCENT DO SUSPEND
        ON 110 PERCENT DO SUSPEND_IMMEDIATE;

-- ----------------------------------------------
-- 2. Warehouse, database e schemas (SYSADMIN, igual ao projeto do Bruno)
-- ----------------------------------------------
USE ROLE SYSADMIN;

CREATE WAREHOUSE IF NOT EXISTS CDS_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

CREATE DATABASE IF NOT EXISTS DB_CDS;

-- Camadas do dbt (o dbt só escreve aqui)
CREATE SCHEMA IF NOT EXISTS DB_CDS.STG;
CREATE SCHEMA IF NOT EXISTS DB_CDS.TRUSTED;
CREATE SCHEMA IF NOT EXISTS DB_CDS.REFINED;

-- Objetos que ficam FORA do dbt: procedures, tasks, semantic view,
-- log da IA, CFG de destinatários e backups de DDL.
CREATE SCHEMA IF NOT EXISTS DB_CDS.APP;

-- ----------------------------------------------
-- 3. Ligar o limite ao warehouse (precisa de ACCOUNTADMIN)
-- ----------------------------------------------
USE ROLE ACCOUNTADMIN;
ALTER WAREHOUSE CDS_WH SET RESOURCE_MONITOR = CDS_RM;

-- ----------------------------------------------
-- 4. Contexto de trabalho
-- ----------------------------------------------
USE ROLE SYSADMIN;
USE WAREHOUSE CDS_WH;
USE DATABASE DB_CDS;

-- ----------------------------------------------
-- 5. Conferências (rodar e olhar o resultado)
-- ----------------------------------------------
SHOW WAREHOUSES LIKE 'CDS_WH';
SHOW SCHEMAS IN DATABASE DB_CDS;

-- O SYSADMIN precisa ler as origens do Protheus. Se esta consulta falhar,
-- falta GRANT de SELECT em TOTVS_PROTHEUS.TRUSTED para o SYSADMIN.
SELECT COUNT(*) AS LINHAS_SD3_2025
FROM TOTVS_PROTHEUS.TRUSTED.SD3010
WHERE LEFT(D3_EMISSAO, 4) = '2025';
