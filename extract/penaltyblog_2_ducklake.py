import penaltyblog as pb
import pandas as pd
import dlt
import os

from utils import get_dynamic_fixture_history, get_understat_fixture_data

from dotenv import load_dotenv

load_dotenv(override=False)


S3_BUCKET = os.environ["S3_BUCKET"]

# xGoals

xgoals_history = get_understat_fixture_data(league_name="DEU Bundesliga 1", start_history_year=2017)



# Fixtures
fixture_history = get_dynamic_fixture_history(league_name="DEU Bundesliga 1", start_history_year=2006)



# PI Ratings
pi_ratings = pb.ratings.PiRatingSystem()


for idx, row in fixture_history.iterrows():
    goal_diff = row["goals_home"] - row["goals_away"]
    pi_ratings.update_ratings(row["team_home"], row["team_away"], goal_diff, row["date"])



ratings_history_pd = pd.DataFrame(pi_ratings.rating_history).sort_values(["team", "date"])



DATASET_NAME = "raw"

destination = dlt.destinations.ducklake()
    
pipeline = dlt.pipeline(
    pipeline_name=f"raw_load_{S3_BUCKET}",
    destination=destination,
    dataset_name=DATASET_NAME,
)


@dlt.resource(name="ratings_history", columns={
    "team": {"data_type": "text"}
})

def ratings_resource():
    yield ratings_history_pd



@dlt.resource(name="fixture_history", columns={
    "season": {"data_type": "text"},
    "competition": {"data_type": "text"},
    "div": {"data_type": "text"},
    "team_home": {"data_type": "text"},
    "team_away": {"data_type": "text"},
    "ftr": {"data_type": "text"},
    "htr": {"data_type": "text"},
    "time": {"data_type": "text"},
    "ï»¿_div": {"data_type": "text"},
    "datetime": {"data_type": "timestamp"}
})
def fixtures_resource():
    yield fixture_history



@dlt.resource(name="xgoals_history")


def xgoals_resource():
    yield xgoals_history



info = pipeline.run(
    [fixtures_resource(), ratings_resource(), xgoals_resource()],
    loader_file_format="parquet"
)

print(info)
