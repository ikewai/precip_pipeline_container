# Data uploader for workflow automation using the Agave (v2) API for actors,
# and the usual REST requests for upload.


# Notes for continued implementation:
# The message sent to the actor needs to be a JSON object that includes the following:
# - gw_upload_url:  The base URL to access the science gateway that files will be stored in.
# - gw_api_token:   The api token to run this uploader with.

import json, os, datetime, mimetypes
from agavepy import Agave

ag = Agave()
ag.restore()
ag.token.create()
# Set up upload directories
with open("file_upload_list.json") as file_list:
    files_to_upload: list = json.loads(file_list.read())

# map csv to text/csv instead of application/vnd.ms-excel
mimetypes.add_type('text/csv', '.csv', strict=True)

# Make the directories to upload into
upload_dir = '/containerization'
current_year: str = str(datetime.datetime.now().year)
current_month: str = str(datetime.datetime.now().month)
current_day: str = str(datetime.datetime.now().day)
ag.files.manageOnDefaultSystem(body={"action": "mkdir", "path": current_year}, sourceFilePath=upload_dir)
ag.files.manageOnDefaultSystem(body={"action": "mkdir", "path": current_month}, sourceFilePath=f"{upload_dir}/{current_year}")
ag.files.manageOnDefaultSystem(body={"action": "mkdir", "path": current_day}, sourceFilePath=f"{upload_dir}/{current_year}/{current_month}")

# Finally, upload the files.
print(f"Files to upload: {files_to_upload}")
for file_path in files_to_upload:
    fileToUpload = open(file_path, 'rb')
    #File Name may be autogen, file path will be based on run date, via the making directories
    res = ag.files.importData(fileName="FILENAMEHERE", filePath="FILEPATHHERE", fileToUpload=fileToUpload)

# take action based on response (success, etc)