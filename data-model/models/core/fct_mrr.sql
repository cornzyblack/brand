with active_subscriptions as (
    select
        subscription_id,
        product_name,
        amount_paid,
        currency,
        current_period_start,
        current_period_end,
        case
            when status = 'active' then amount_paid
            else 0
        end as mrr
    from {{ ref('int_subscriptions') }}
    where is_active = true
)
, monthly_mrr as (
    select
        subscription_id,
        product_name,
        sum(mrr) as total_mrr,
        currency,
        date_trunc('month', current_period_start) as mrr_month
    from active_subscriptions
    group by
        subscription_id,
        product_name,
        currency,
        date_trunc('month', current_period_start)
)
select
    subscription_id,
    product_name,
    total_mrr,
    currency,
    mrr_month
from monthly_mrr
order by mrr_month, subscription_id
