{{
    config(
        materialized='incremental',
        unique_key='match_id',
        incremental_strategy='merge'
    )
}}

select
    md5(concat(date, competition, season, team_home, team_away)) as match_id,
    date,
    competition,
    season,
    team_home,
    team_away,
    goals_home as ft_home_goal,
    goals_away as ft_away_goal,
    xg_home,
    xg_away,
    forecast_w*3+forecast_d*1+forecast_l*0 AS xpts_home,
    forecast_w*0+forecast_d*1+forecast_l*3 AS xpts_away,
    datetime
from {{ source('raw', 'xgoals_history') }}

{% if is_incremental() %}
    where date >= (select max(date) from {{ this }})
{% endif %}
