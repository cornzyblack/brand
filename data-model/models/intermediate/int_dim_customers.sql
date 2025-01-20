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
    cc.*,
    stu.name AS user_name
FROM customers_country cc
LEFT JOIN {{ ref('stg_users') }} stu
ON stu.id = cc.user_id
