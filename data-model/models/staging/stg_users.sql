{{
    config(
        materialized='incremental',
        unique_key='id'
    )
}}

WITH ranked_users AS (
    SELECT *,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY last_updated) AS rn
    FROM {{ ref('users') }}
)

SELECT
user_id as id,
name,
email,
created_at,
last_updated,
FROM ranked_users
WHERE rn = 1
