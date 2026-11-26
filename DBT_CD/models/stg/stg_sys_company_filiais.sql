-- Filiais do Protheus (SYS_COMPANY): liga o CNPJ de um fornecedor interno ao código da filial de origem.
-- Usado para rastrear a transferência até a compra externa (ex.: filial 07 -> 63 no Corporativo).
-- Grão: cnpj (um CNPJ por filial; se houver mais de um registro, vale o de menor código de filial).

with

filiais as (
    select * from {{ source('totvs_protheus', 'sys_company') }}
    where trim(d_e_l_e_t_) = ''
),

final as (
    select
        trim(m0_cgc)      as cnpj,
        trim(m0_codfil)   as cod_filial
    from filiais
    qualify row_number() over (partition by trim(m0_cgc) order by trim(m0_codfil)) = 1
)

select * from final
