-- Fornecedores (SA2010). Grão: cod_fornecedor + loja. O CGC é o CNPJ (nome antigo).
-- Fornecedor com CNPJ de raiz var cnpj_raiz_afip é a própria AFIP (transferência interna).

with

fornecedores as (
    select * from {{ source('totvs_protheus', 'sa2010') }}
    where trim(d_e_l_e_t_) = ''
),

final as (
    select
        trim(a2_cod)                                                as cod_fornecedor,
        trim(a2_loja)                                               as loja,
        {{ clean_text('a2_nreduz') }}                               as nome_reduzido,
        {{ clean_text('a2_cgc') }}                                  as cnpj,
        left(trim(a2_cgc), 8) = '{{ var("cnpj_raiz_afip") }}'       as is_afip
    from fornecedores
    qualify row_number() over (
        partition by trim(a2_cod), trim(a2_loja)
        order by dt_atualizacao desc, r_e_c_n_o_ desc
    ) = 1
)

select * from final
