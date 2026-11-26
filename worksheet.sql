SELECT cd_codigo,
       TO_CHAR(dt_emissao, 'YYYYMM') AS aaaamm,
       ROUND(SUM(total_custo), 2)    AS valor
FROM DB_CDS.STG.STG_SD3_CONSUMO
WHERE TO_CHAR(dt_emissao, 'YYYYMM') = '202609'
GROUP BY 1, 2
ORDER BY 1;