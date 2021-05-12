# Needs to pull:
# - Station list
# - Previous day's cumulative data (if not first day of the month)

from agavepy import actors, Agave
import json, os, datetime

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

if isFirstDayOfMonth and not isFirstMonthOfYear:
    """set the appropriate directory variables"""

if isFirstDayOfMonth and isFirstMonthOfYear:
    """set the appropriate directory variables"""