-- Produtos (SB1010). Grão: cod_prod. A descrição (B1_DESC) é o nome do insumo que aparece no relatório.
-- Atenção: a coluna ID_SB1010 NÃO existe; usar DT_ATUALIZACAO e R_E_C_N_O_ para pegar o registro mais recente.

with

produtos as (
    select * from {{ source('totvs_protheus', 'sb1010') }}
    where d_e_l_e_t_ = ''
),

final as (
    select
        trim(b1_cod)    as cod_prod,
        trim(b1_desc)   as desc_prod
    from produtos
    qualify row_number() over (
        partition by trim(b1_cod)
        order by dt_atualizacao desc, r_e_c_n_o_ desc
    ) = 1
)

select * from final
