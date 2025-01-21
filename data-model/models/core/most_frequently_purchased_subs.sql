with product_purchases as (
    select
        s.product_name,
        c.country_code,
        count(s.subscription_id) as purchase_count
    from {{ ref('dim_products') }} p
    join {{ ref('int_subscriptions') }} s
        on p.id = s.product_id
    join {{ ref('dim_customers') }} c
        on s.customer_id = c.customer_id
    where s.status = 'active'
    group by
        p.id,
        s.product_name,
        c.country_code
),
ranked_purchases as (
    select
        product_name,
        country_code,
        purchase_count,
        row_number() over (partition by country_code order by purchase_count desc) as rank
    from product_purchases
)
select
    product_name,
    country_code,
    purchase_count
from ranked_purchases
where rank = 1
order by country_code
