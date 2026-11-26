{#- Tira espaços e transforma vazio em null. -#}
{% macro clean_text(col) -%}
    nullif(trim({{ col }}), '')
{%- endmacro %}
