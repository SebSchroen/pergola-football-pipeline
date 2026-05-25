with fixtures as (
    select
        cast(date as date) as match_date,
        season,
        competition,
        team_home,
        team_away,
        ft_home_goal,
        ft_away_goal,
        home_foul,
        away_foul,
        home_yellow_card,
        away_yellow_card,
        home_red_card,
        away_red_card,
        b365_home_odds,
        b365_draw_odds,
        b365_a_odds
    from {{ ref('stg_fixture_history') }}
),

understat as (
    select
        cast(date as date) as match_date,
        season,
        team_home,
        team_away,
        xg_home,
        xg_away,
        xpts_home,
        xpts_away
    from {{ ref('stg_understat_history') }}
),

ratings as (
    select
        cast(date as date) as match_date,
        team,
        pre_home_rating,
        pre_away_rating,
        post_home_rating,
        post_away_rating
    from {{ ref('stg_ratings_history') }}
),

masterdata as (
    select * from {{ ref('stg_masterdata') }}
),

joined as (
    select
        f.match_date,
        f.season,
        f.competition,
        f.team_home,
        f.team_away,
        f.ft_home_goal,
        f.ft_away_goal,
        f.home_foul,
        f.away_foul,
        f.home_yellow_card,
        f.away_yellow_card,
        f.home_red_card,
        f.away_red_card,
        f.b365_home_odds,
        f.b365_draw_odds,
        f.b365_a_odds,
        u.xg_home,
        u.xg_away,
        u.xpts_home,
        u.xpts_away,
        r_home.pre_home_rating as pre_home_rating,
        r_home.post_home_rating as post_home_rating,
        r_away.pre_away_rating as pre_away_rating,
        r_away.post_away_rating as post_away_rating
    from fixtures f
    left join masterdata md_home
        on f.team_home = md_home.footballdata
    left join masterdata md_away
        on f.team_away = md_away.footballdata
    left join understat u
        on f.season = u.season
        and f.match_date = u.match_date
        and md_home.understat = u.team_home
        and md_away.understat = u.team_away
    left join ratings r_home
        on f.match_date = r_home.match_date
        and f.team_home = r_home.team
    left join ratings r_away
        on f.match_date = r_away.match_date
        and f.team_away = r_away.team
)

select * from joined
