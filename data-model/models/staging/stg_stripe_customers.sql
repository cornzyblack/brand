{{
    config(
        materialized='incremental',
        unique_key='id'
    )
}}

with transformed_customers AS (
  select
    id,
    TRY_CAST(json_extract(metadata, '$.user_id') AS int) AS user_id,
    name,
    phone AS phone_number,
    address['city'] AS address_city,
    TRIM(coalesce(address['line1'], '') || ' ' ||  coalesce(address['line2'], '')) AS address_line,
    address['state'] AS address_state,
    address['postal_code'] AS address_postal_code,
    address['country'] AS country_code,
    to_timestamp(created) AS created_at,
    to_timestamp(updated) AS updated_at,
    DATE AS load_date,
    coalesce(is_deleted, false) AS is_deleted,
    currency AS currency_code
FROM read_parquet('s3://{{ env_var('AWS_BUCKET_NAME') }}/stripe/stripe_customers/DATE=*/*.parquet',
                 hive_partitioning = true)

{% if is_incremental() %}

  WHERE created_at >= (SELECT COALESCE(MAX(created_at), '1900-01-01') FROM {{ this }})
  OR updated_at >= (SELECT COALESCE(MAX(updated_at), '1900-01-01') FROM {{ this }})

{% endif %}
),

ranked_customers AS (
    SELECT tc.*,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_at DESC) AS row_num,
           cc.name AS country_name
    FROM transformed_customers tc
    LEFT JOIN {{ ref('country_codes') }} cc
    ON tc.country_code = cc.code
)

SELECT
id,
user_id,
name,
phone_number,
address_city,
address_line,
address_state,
address_postal_code,
country_code,
created_at,
updated_at,
load_date,
is_deleted,
currency_code,
country_name
FROM ranked_customers
WHERE row_num=1
