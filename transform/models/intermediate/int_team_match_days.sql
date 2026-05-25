with home_games as (
    select
        season,
        date,
        team_home as team,
        'home' as venue
    from {{ ref('stg_fixture_history') }}
),

away_games as (
    select
        season,
        date,
        team_away as team,
        'away' as venue
    from {{ ref('stg_fixture_history') }}
),

all_games as (
    select * from home_games
    union all
    select * from away_games
)

select
    *,
    row_number() over (
        partition by season, team 
        order by date
    ) as match_day
from all_games
