{{
    config(
        materialized='incremental',
        unique_key='id'
    )
}}

WITH transformed_subscriptions AS (
    SELECT
        id,
        customer AS customer_id,
        status,
        to_timestamp(start_date) AS start_date,
        to_timestamp(current_period_start) AS current_period_start,
        to_timestamp(current_period_end) AS current_period_end,
        to_timestamp(ended_at) AS ended_at,
        to_timestamp(canceled_at) AS canceled_at,
        cancel_at_period_end,
        to_timestamp(created) AS created_at,
        is_deleted AS is_deleted,
        tax_percent,
        trial_start,
        currency,
        trial_end,
        COALESCE(plan['active'], False) as plan_active,
        plan['interval'] as plan_interval,
        plan['id'] as plan_id,
        plan['amount'] / 100 as amount_paid,
        plan['currency'] as plan_currency,
        plan['product'] as product_id,
        plan['interval_count'] as plan_interval_count,
        plan['billing_scheme'] as plan_billing_scheme,
        quantity,
        DATE AS load_date
    FROM read_parquet('s3://{{ env_var('AWS_BUCKET_NAME') }}/stripe/stripe_subscriptions/DATE=*/*.parquet',
                     hive_partitioning = true)

    {% if is_incremental() %}
        WHERE created_at >= (SELECT COALESCE(MAX(created_at), '1900-01-01') FROM {{ this }})
    {% endif %}
),

ranked_subscriptions AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY created_at DESC) AS row_num
    FROM transformed_subscriptions
)

SELECT
    id,
    customer_id,
    status,
    start_date,
    current_period_start,
    current_period_end,
    ended_at,
    canceled_at,
    cancel_at_period_end,
    created_at,
    tax_percent,
    trial_start,
    trial_end,
    currency,
    quantity,
    plan_active,
    plan_interval,
    plan_id,
    amount_paid,
    product_id,
    plan_interval_count,
    plan_billing_scheme,
    load_date
FROM ranked_subscriptions
WHERE row_num = 1
