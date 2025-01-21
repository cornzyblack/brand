{{
    config(
        materialized = 'table',
        unique_key = 'subscription_id'
    )
}}

with subscriptions as (
    select
        subscription_id,
        status,
        created_at,
        current_period_start,
        current_period_end,
        ended_at,
        canceled_at,
        trial_start,
        trial_end
    from {{ ref('int_subscriptions') }}
),
churned_subscriptions as (
    select
        subscription_id,
        status,
        created_at,
        current_period_start,
        current_period_end,
        ended_at,
        canceled_at,
        trial_start,
        trial_end,
        case
            when status = 'paused' or status = 'unpaid' or status = 'canceled' then true
            else false
        end as is_churned
    from subscriptions
    where status in ('canceled', 'paused', 'unpaid')
),
monthly_churn as (
    select
        date_trunc('month', ended_at) as churn_month,
        count(subscription_id) as churn_count
    from churned_subscriptions
    group by churn_month
)
select
    churn_month,
    churn_count
from monthly_churn
order by churn_month
