{{
    config(
        materialized = 'table',
        unique_key = 'id',
        sort = [
            'created_at'
        ]
    )
}}

with subscriptions as (
    select
        sub.id as subscription_id,
        sub.customer_id as customer_id,
        sub.status,
        sub.created_at,
        sub.current_period_start,
        sub.current_period_end,
        sub.ended_at,
        sub.canceled_at,
        sub.trial_start,
        sub.trial_end,
        sub.amount_paid,
        sub.currency,
        product_id,
        pdct.name as product_name,
        case
            when sub.status = 'active' then true
            else false
        end as is_active, -- For users who are active
        case
            when sub.status = 'canceled' then true
            else false
        end as is_canceled,  -- For users who canceled their subscription, this will be useful in calculating churn for Rebrandly
        case
            when sub.status = 'trialing' then true
            else false
        end as is_trialing, -- For users who are trialing, this will be useful in reaching out to customers e.g: offers, and campaigns by Rebrandly
        case
            when sub.status = 'paused' then true
            else false
        end as is_paused  -- For users who paused their subscriptions: meaning they were on a trial before, and didn't move to take up a sub
    from {{ ref('stg_stripe_subscriptions') }} sub
    left join {{ ref('stg_stripe_products') }} pdct
    ON sub.product_id = pdct.id
)

select *
from subscriptions
