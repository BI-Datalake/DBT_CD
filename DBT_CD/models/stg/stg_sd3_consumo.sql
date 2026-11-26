-- Consumo dos CDs (requisições - devoluções) a partir das movimentações internas do Protheus (SD3010),
-- só dos centros de custo da seed dim_cd_centro_custo, desde var consumo_inicio.
-- Grão: dt_emissao + filial + cod_cc + cod_prod + um (já agregado por dia; a semana e o mês saem daqui).
-- Tabela (exceção ao padrão view da STG): é a leitura pesada da SD3010, feita uma vez por build.
--
-- Regra de consumo (decidida em 26/11/2026, validada com dados de Jundiaí):
--   * TM >= 500 soma (requisição); TM < 500 subtrai (devolução).
--   * Fora da conta: TM 999 e D3_CF RE4/DE4. São transferências entre armazéns, não consumo.
--     Ex.: Jundiaí CC 27160050 em set/2026 tem R$ 18.343,52 de transferência 02 -> 16 que, contada,
--     fazia o consumo do CC cair de R$ 22.405,67 para R$ 4.062,15.
{{ config(materialized='table') }}

with

movimentos as (
    select * from {{ source('totvs_protheus', 'sd3010') }}
    where d_e_l_e_t_ = ''
      and d3_estorno <> 'S'
      -- coalesce: TM não numérico não derruba a linha (continua sendo tratado como devolução)
      and coalesce(try_to_number(d3_tm), 0) <> 999
      and coalesce(trim(d3_cf), '') not in ('RE4', 'DE4')
      and left(d3_emissao, 6) >= '{{ var("consumo_inicio") }}'
),

centros_custo as (
    select cd_codigo, cd_nome, ccusto from {{ ref('dim_cd_centro_custo') }}
),

tratado as (
    select
        c.cd_codigo,
        c.cd_nome,
        to_date(m.d3_emissao, 'YYYYMMDD')                  as dt_emissao,
        trim(m.d3_filial)                                  as filial,
        c.ccusto                                           as cod_cc,
        trim(m.d3_cod)                                     as cod_prod,
        trim(m.d3_um)                                      as um,
        iff(try_to_number(m.d3_tm) >= 500, 1, -1)          as sinal,
        m.d3_quant,
        m.d3_custo1,
        m.d3_doc
    from movimentos m
    inner join centros_custo c
        on trim(m.d3_cc) = c.ccusto
),

final as (
    select
        cd_codigo,
        cd_nome,
        dt_emissao,
        filial,
        cod_cc,
        cod_prod,
        um,
        sum(sinal * d3_quant)    as total_quant,
        sum(sinal * d3_custo1)   as total_custo,
        count(d3_doc)            as total_movimentos
    from tratado
    group by cd_codigo, cd_nome, dt_emissao, filial, cod_cc, cod_prod, um
)

select * from final
