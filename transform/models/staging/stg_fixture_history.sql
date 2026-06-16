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
    season,
    competition,
    div,
    team_home,
    team_away,
    ftr as ft_result,
    fthg as ft_home_goal,
    ftag as ft_away_goal,
    hthg as ht_home_goal,
    htag as ht_way_goal,
    htr as ht_result,
    hf as home_foul,
    af as away_foul,
    hy as home_yellow_card,
    ay as away_yellow_card,
    hr as home_red_card,
    ar as away_red_card,
    b365_h as b365_home_odds,
    b365_d as b365_draw_odds,
    b365_a as b365_a_odds
from {{ source('raw', 'fixture_history') }}

{% if is_incremental() %}
    where date >= (select max(date) from {{ this }})
{% endif %}
