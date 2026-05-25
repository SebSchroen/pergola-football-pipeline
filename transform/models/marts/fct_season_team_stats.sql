with split_stats as (
    select * from {{ ref('fct_season_team_stats_home_away') }}
),

final_stats as (
    select
        season,
        team_label as team,
        sum(points) as points,
        sum(goals_for) as goals,
        sum(goals_against) as goals_against,
        sum(goals_for) - sum(goals_against) as goal_diff,
        sum(xgoals_for) as xgoals,
        sum(xpts) as xpts
    from split_stats
    group by 1, 2
)

select
    season,
    rank() over (partition by season order by points desc, goal_diff desc, goals desc) as rank,
    team,
    points,
    goal_diff,
    goals,
    goals_against,
    xgoals,
    xpts
from final_stats
order by season, rank
