-- Notas de entrada (SD1010) das TES de compra e transferência (seed tes_entrada), desde var entradas_inicio,
-- só dos produtos que os CDs consomem. Serve para achar a última entrada de cada item e, daí, o fornecedor.
-- Grão: item de nota (recno, que é o R_E_C_N_O_ da SD1010).
-- A janela é mais antiga que a do consumo de propósito: item de giro lento pode ter a última entrada
-- meses antes do consumo (em set/2026, 425 de 426 itens tinham entrada a partir de 2025).

with

entradas as (
    select * from {{ source('totvs_protheus', 'sd1010') }}
    -- na SD1 o valor válido é espaço, não vazio: usar TRIM
    where trim(d_e_l_e_t_) = ''
      and d1_tipo = 'N'
      and left(d1_dtdigit, 6) >= '{{ var("entradas_inicio") }}'
),

tes as (
    select tes, tipo_entrada from {{ ref('tes_entrada') }}
),

produtos_dos_cds as (
    select distinct cod_prod from {{ ref('stg_sd3_consumo') }}
),

final as (
    select
        e.r_e_c_n_o_                    as recno,
        trim(e.d1_filial)               as filial,
        trim(e.d1_cod)                  as cod_prod,
        to_date(e.d1_dtdigit, 'YYYYMMDD') as dt_entrada,
        trim(e.d1_fornece)              as cod_fornecedor,
        trim(e.d1_loja)                 as loja,
        trim(e.d1_tes)                  as tes,
        t.tipo_entrada
    from entradas e
    inner join tes t
        on t.tes = trim(e.d1_tes)
    inner join produtos_dos_cds p
        on p.cod_prod = trim(e.d1_cod)
)

select * from final
