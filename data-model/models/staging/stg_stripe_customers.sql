{{
    config(
        materialized='incremental',
        unique_key='id'
    )
}}


select
  id,
  UPPER(name) AS name,
  phone,
  address['user_id'] as user_id,
  address['city'] as address_city,
  trim(address['line1'] || ' ' ||  address['line2']) as address_line,
  address['state'] as address_state,
  address['postal_code'] as address_postal_code,
  address['country'] AS alpha_2_country_code,
  created as created_at,
  updated as updated_at,
  DATE AS ingested_date,
  coalesce(is_deleted, false) as is_deleted,
  currency as alpha_2_currency_code

FROM read_parquet('s3://{{ env_var('AWS_BUCKET_NAME') }}/stripe/stripe_customers/DATE=*/*.parquet',
                 hive_partitioning = true)

{% if is_incremental() %}

where load_date >= (select coalesce(max(load_date),'1900-01-01') from {{ this }} )

{% endif %}
