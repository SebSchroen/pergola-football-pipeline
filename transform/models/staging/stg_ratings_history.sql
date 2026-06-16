{{
    config(
        materialized='incremental',
        unique_key='rating_id',
        incremental_strategy='merge'
    )
}}

select
    md5(concat(date, team)) as rating_id,
    date,
    team,
    home_rating as post_home_rating,
    away_rating as post_away_rating,
    LAG(home_rating) OVER(PARTITION BY team ORDER BY date) as pre_home_rating,
    LAG(away_rating) OVER(PARTITION BY team ORDER BY date) as pre_away_rating
from {{ source('raw', 'ratings_history') }}

{% if is_incremental() %}
    where date >= (select max(date) from {{ this }})
{% endif %}
