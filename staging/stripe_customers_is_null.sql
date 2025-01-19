{{
    config(
        materialized='table',
        severity='ERROR'
    )
}}

SELECT *
FROM {{ ref('stg_stripe_customers') }}
WHERE id IS NULL OR name IS NULL OR phone IS NULL
