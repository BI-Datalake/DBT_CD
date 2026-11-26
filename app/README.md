# app/ — objetos fora do dbt

Ficam aqui, como scripts versionados, os objetos que o dbt não gerencia. Todos moram no schema `DB_CDS.APP`:

- `SP_RELATORIO_INSUMOS_CD` e `SP_RELATORIO_INSUMOS_CD_LOTE` (procedures do e-mail)
- `SV_CONSUMO_INSUMOS_CD` (semantic view)
- `CFG_RELATORIO_INSUMOS_CD` (destinatários; contém e-mails, não vai em seed)
- `LOG_RELATORIO_INSUMOS_IA` (tokens por execução)
- funções de formatação (`FMT_BRL`, `FMT_PCT`, ...) e tasks (SUSPENDED até a validação das áreas)

Os scripts de origem estão em `DOC_AI_DB.LAB` (produção atual). Copiar para cá só depois que as tabelas REFINED existirem, trocando as leituras para `DB_CDS.REFINED`.
