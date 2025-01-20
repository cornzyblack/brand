{{
    config(
        materialized='incremental',
        unique_key='id'
    )
}}

WITH transformed_subscription_items AS (
    SELECT
        id,
        subscription_id,
        status,
        to_timestamp(created) as created_at,
        to_timestamp(current_period_start) as current_period_start,
        to_timestamp(current_period_end) as current_period_end,
        to_timestamp(ended_at) as ended_at,
        to_timestamp(canceled_at) as canceled_at,
        to_timestamp(created) AS created_at,
        to_timestamp(updated) AS updated_at,
        default_payment_method_id,
        tax_percent,
        cancellation_reason,
        trial_start,
        trial_end
        DATE AS load_date
    FROM read_parquet('s3://{{ env_var('AWS_BUCKET_NAME') }}/stripe/stripe_subscription_items/DATE=*/*.parquet',
                     hive_partitioning = true)

    {% if is_incremental() %}
        WHERE created_at >= (SELECT COALESCE(MAX(created_at), '1900-01-01') FROM {{ this }})
        OR updated_at >= (SELECT COALESCE(MAX(updated_at), '1900-01-01') FROM {{ this }})
    {% endif %}
),

ranked_subscription_items AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY created_at DESC) AS row_num
    FROM transformed_ranked_subscription_items
)

SELECT *
FROM ranked_subscription_items
WHERE row_num = 1
