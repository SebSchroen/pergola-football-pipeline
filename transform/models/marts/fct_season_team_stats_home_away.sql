with fixture_history as (
    select * from {{ ref('stg_fixture_history') }}
),

understat_history as (
    select * from {{ ref('stg_understat_history') }}
),

masterdata as (
    select * from {{ ref('stg_masterdata') }}
),

home_stats as (
    select
        fh.season,
        md.label as team_label,
        'home' as location,
        sum(case when fh.ft_result = 'H' then 3 when fh.ft_result = 'D' then 1 else 0 end) as points,
        sum(fh.ft_home_goal) as goals_for,
        sum(fh.ft_away_goal) as goals_against,
        sum(uh.xg_home) as xgoals_for,
        sum(uh.xg_away) as xgoals_against,
        sum(uh.xpts_home) as xpts
    from fixture_history fh
    left join masterdata md
        on fh.team_home = md.footballdata
    left join understat_history uh
        on cast(fh.date as date) = cast(uh.date as date)
        and md.understat = uh.team_home
    group by 1, 2
),

away_stats as (
    select
        fh.season,
        md.label as team_label,
        'away' as location,
        sum(case when fh.ft_result = 'A' then 3 when fh.ft_result = 'D' then 1 else 0 end) as points,
        sum(fh.ft_away_goal) as goals_for,
        sum(fh.ft_home_goal) as goals_against,
        sum(uh.xg_away) as xgoals_for,
        sum(uh.xg_home) as xgoals_against,
        sum(uh.xpts_away) as xpts
    from fixture_history fh
    left join masterdata md
        on fh.team_away = md.footballdata
    left join understat_history uh
        on cast(fh.date as date) = cast(uh.date as date)
        and md.understat = uh.team_away
    group by 1, 2
),

combined as (
    select * from home_stats
    union all
    select * from away_stats
)

select * from combined
order by season, team_label, location
