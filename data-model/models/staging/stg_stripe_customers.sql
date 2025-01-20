{{
    config(
        materialized='incremental',
        unique_key='id'
    )
}}

with transformed_customers AS (
  select
    id,
    name,
    phone,
    TRY_CAST(json_extract(metadata, '$.user_id') AS int) AS user_id,
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
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY created_at DESC) AS row_num
    FROM transformed_customers
    LEFT JOIN {{ countries }} countries
    ON transformed_customers.country_code = countries.code
)

SELECT *
FROM ranked_customers
WHERE row_num=1
