{{
    config(
        materialized='incremental',
        unique_key='subscription_item_id'
    )
}}

WITH transformed_subscription_items AS (
    SELECT
        id as subscription_item_id,
        subscription as subscription_id,
        status AS subscription_status,
        to_timestamp(created) as created_at,
        to_timestamp(current_period_start) as current_period_start,
        to_timestamp(current_period_end::int) as current_period_end,
        to_timestamp(ended_at) as ended_at,
        to_timestamp(canceled_at::int) as canceled_at,
        tax_percent,
        trial_start,
        trial_end,
        plan['object']['active'] as plan_active,
        plan['object']['interval'] as plan_interval,
        plan['object']['id'] as plan_id,
        plan['object']['amount'] as plan_amount,
        plan['object']['product'] as product_id,
        plan['object']['interval_count'] as plan_interval_count,
        plan['object']['billing_scheme'] as plan_billing_scheme,
        DATE AS load_date
    FROM read_parquet('s3://{{ env_var('AWS_BUCKET_NAME') }}/stripe/stripe_subscription_items/DATE=*/*.parquet',
                     hive_partitioning = true)

    {% if is_incremental() %}
        WHERE created_at >= (SELECT COALESCE(MAX(created_at), '1900-01-01') FROM {{ this }})
    {% endif %}
),

ranked_subscription_items AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY subscription_item_id ORDER BY created_at DESC) AS row_num
    FROM transformed_subscription_items
)

SELECT
subscription_item_id,
subscription_id,
subscription_status,
created_at,
current_period_start,
current_period_end,
ended_at,
canceled_at,
tax_percent,
trial_start,
trial_end,
plan_active,
plan_interval,
plan_id,
plan_amount,
product_id,
plan_interval_count,
plan_billing_scheme
FROM ranked_subscription_items
WHERE row_num = 1
