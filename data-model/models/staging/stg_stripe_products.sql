{{
    config(
        materialized='incremental',
        unique_key='id'
    )
}}

with transformed_products AS (
  SELECT
    id,
    name,
    active,
    description,
    is_deleted,
    default_price,
    to_timestamp(created) AS created_at,
    DATE AS load_date,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY created DESC) AS row_num

  FROM read_parquet('s3://{{ env_var('AWS_BUCKET_NAME') }}/stripe/stripe_products/DATE=*/*.parquet',
                 hive_partitioning = true)

{% if is_incremental() %}

  WHERE created_at >= (SELECT COALESCE(MAX(created_at), '1900-01-01') FROM {{ this }})

{% endif %}
)

SELECT
  id,
  name,
  active,
  description,
  is_deleted,
  default_price,
  created_at,
  load_date
FROM transformed_products
WHERE row_num=1
