{{
    config(
        materialized = 'table',
        unique_key = 'subscription_id'
    )
}}

with churned_subscriptions as (
    select
        sub.subscription_id,
        sub.product_name,
        sub.amount_paid,
        sub.currency,
        sub.current_period_start,
        sub.current_period_end,
        sub.ended_at,
        sub.canceled_at,
        sub.status,
        cust.country_code,
        case
            when sub.status in ('canceled', 'paused', 'unpaid') then sub.amount_paid
            else 0
        end as lost_revenue,
    from {{ ref('int_subscriptions') }} sub
    left join {{ ref('dim_customers') }} cust
    on sub.customer_id = cust.customer_id
    where sub.status in ('canceled', 'paused', 'unpaid')
),
country_churn as (
    select
        country_code,
        date_trunc('month', current_period_end) as churn_month,
        sum(lost_revenue) as total_lost_revenue,
        count(subscription_id) as churn_count
    from churned_subscriptions
    group by
        country_code,
        date_trunc('month', current_period_end)
)
select
    country_code,
    churn_month,
    total_lost_revenue,
    churn_count
from country_churn
order by churn_month, country_code
