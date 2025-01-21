{{
    config(
        materialized = 'table',
        unique_key = 'id',
        sort = [
            'id',
            'created_at'
        ]
    )
}}

with stg_products as (
    SELECT *
    FROM {{ ref('stg_stripe_products') }}
)


SELECT
  id,
  name,
  active,
  description,
  is_deleted,
  default_price,
  created_at
FROM stg_products
