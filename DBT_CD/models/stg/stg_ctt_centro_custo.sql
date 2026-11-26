-- Centros de custo (CTT010). Grão: cod_cc. A descrição é CTT_DESC01.
-- Na CTT010 o valor válido de D_E_L_E_T_ pode ser vazio ou nulo.

with

centros as (
    select * from {{ source('totvs_protheus', 'ctt010') }}
    where (d_e_l_e_t_ = '' or d_e_l_e_t_ is null)
),

final as (
    select
        trim(ctt_custo)              as cod_cc,
        {{ clean_text('ctt_desc01') }} as desc_cc,
        coalesce(trim(ctt_bloq), '2') = '1' as is_bloqueado
    from centros
    qualify row_number() over (
        partition by trim(ctt_custo)
        order by r_e_c_n_o_ desc
    ) = 1
)

select * from final
