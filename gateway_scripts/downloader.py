from agavepy import actors, Agave
import json, os, datetime, calendar

ag = Agave()
ag.restore()

current_year: int = datetime.datetime.now().year
current_month: int = datetime.datetime.now().month
current_day: int = datetime.datetime.now().day
# year/month/previous_day or one day back on month/year accordingly

# Check if we're at the start of the month, we'll want the last day of last month's data if so.
isFirstDayOfMonth: bool = (current_day == 1)
# Check if we're also at the start of the year, we'll want the last day of last year's data if so.
isFirstMonthOfYear: bool = (current_month == 1)

previous_day_data_dir: str = '' # YYYY/MM/DD-formatted, to match remote directory from uploader.

if isFirstDayOfMonth and not isFirstMonthOfYear:
    last_month = current_month - 1
    last_day_of_last_month = calendar.monthrange(current_year, current_month)[1]
    previous_day_data_dir = f"{current_year}/{last_month}/{last_day_of_last_month}"

if isFirstDayOfMonth and isFirstMonthOfYear:
    last_year = current_year - 1
    last_month = 12 # December
    last_day_of_last_month = 31 # Dec always ends in 31st
    previous_day_data_dir = f"{last_year}/{last_month}/{last_day_of_last_month}"

# Next, execute the actual downloading of the station list and the previous day's data.