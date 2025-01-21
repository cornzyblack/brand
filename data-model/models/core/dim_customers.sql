{{
    config(
        materialized = 'table',
        unique_key = 'customer_id',
        sort = [
            'customer_id',
            'created_at'
        ]
    )
}}
with stg_customers as (
    SELECT *
    FROM {{ ref('stg_stripe_customers') }}
),

customers_country AS (
    SELECT
    stgc.*,
    cc.name as country
    FROM stg_customers stgc
    LEFT JOIN {{ ref('country_codes') }} cc
    ON stgc.country_code = cc.code
)

SELECT
    cc.id as customer_id,
    cc.user_id,
    stu.name AS user_name,
    cc.first_name,
    cc.last_name,
    cc.full_name,
    cc.address_city,
    cc.address_state,
    cc.country_code,
    cc.created_at,
    cc.updated_at,
    cc.is_deleted
FROM customers_country cc
LEFT JOIN {{ ref('stg_users') }} stu
ON stu.id = cc.user_id
