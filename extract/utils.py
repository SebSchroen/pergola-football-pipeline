import pandas as pd
from datetime import datetime
import penaltyblog as pb

def get_dynamic_fixture_history(league_name="DEU Bundesliga 1", start_history_year=2006):
    """
    Fetches historical football fixture data dynamically from a specified start year
    up to the most recent season available.

    Args:
        league_name (str): The name of the league to fetch data for (e.g., "DEU Bundesliga 1").
        start_history_year (int): The calendar year from which to start fetching seasons.
                                  (e.g., 2006 for the 2006-2007 season).

    Returns:
        pd.DataFrame: A DataFrame containing concatenated fixture data for all available seasons.
                      Returns an empty DataFrame if no data could be fetched.
    """
    all_fixtures_data = []
    current_year = datetime.now().year

    # Determine the range of seasons to attempt fetching.
    # A season 'YYYY-YYYY+1' typically starts in YYYY and ends in YYYY+1.
    # To get the "most recent available", we should try at least up to the season
    # that starts in the current calendar year (e.g., "2024-2025" if current_year is 2024).
    # We also attempt to fetch one more season (e.g., "2025-2026") to ensure we capture
    # the very latest data, or to confirm that no further data is available.
    # `range(start_history_year, current_year + 2)` will generate `year` values from
    # `start_history_year` up to `current_year + 1`.
    # For example, if current_year is 2024, it will try seasons starting in 2006, ..., 2024, 2025.
    # This covers "2024-2025" and "2025-2026".

    print(f"Starting to fetch {league_name} fixture data from {start_history_year}-{start_history_year+1}...")

    for year in range(start_history_year, current_year + 2):
        season_string = f"{year}-{year+1}"
        print(f"Attempting to fetch data for season: {season_string}")

        try:
            fixtures = pb.scrapers.FootballData(league_name, season_string).get_fixtures()
            if not fixtures.empty:
                print(f"Successfully fetched {len(fixtures)} fixtures for season {season_string}.")
                all_fixtures_data.append(fixtures)
            else:
                # If a season returns empty, it's highly probable that subsequent seasons
                # will also be empty. So, we can stop here to avoid unnecessary requests.
                print(f"No data found for season {season_string}. This likely means the season is not yet available or complete. Stopping further attempts.")
                break 
        except Exception as e:
            # Catch any errors during fetching (e.g., network issues, changes in scraper source).
            # If an error occurs, it's also a strong indicator that further seasons might not be available
            # or the scraper is having issues. It's usually safer to stop.
            print(f"Error fetching data for season {season_string}: {e}. Stopping further attempts.")
            break

    if all_fixtures_data:
        # Concatenate all collected DataFrames into a single one
        fixture_history = pd.concat(all_fixtures_data, ignore_index=True)
        print(f"\nSuccessfully collected data for {len(all_fixtures_data)} seasons.")
        print(f"Total number of fixtures collected: {len(fixture_history)}")
        return fixture_history
    else:
        print("\nNo fixture data could be collected.")
        return pd.DataFrame()