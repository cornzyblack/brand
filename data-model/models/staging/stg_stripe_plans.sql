{{
    config(
        materialized='incremental',
        unique_key='id'
    )
}}

with transformed_plans AS (
  select
    id,
    interval,
    product as product_id,
    to_timestamp(created) AS created_at,
    to_timestamp(updated) AS updated_at,
    DATE AS load_date,
    coalesce(is_deleted, false) AS is_deleted,
    currency AS currency_code
  FROM read_parquet('s3://{{ env_var('AWS_BUCKET_NAME') }}/stripe/stripe_plans/DATE=*/*.parquet',
                    hive_partitioning = true)
)

SELECT *
FROM transformed_plans
