# Data uploader for workflow automation using Agave v2 for actors and file upload.

import json, os, datetime, mimetypes
from typing import List
from agavepy import Agave

ag = Agave()
ag.restore()
ag.token.create()

# Set up upload directories
with open("file_upload_list.json") as file_list:
    files_to_upload: list = json.loads(file_list.read())['data']

# Make the directories to upload into
base_upload_dir = '/containerization'
current_year: str = str(datetime.datetime.now().year)
current_month: str = str(datetime.datetime.now().month)
current_day: str = str(datetime.datetime.now().day)
ag.files.manageOnDefaultSystem(body={"action": "mkdir", "path": current_year}, sourceFilePath=base_upload_dir)
ag.files.manageOnDefaultSystem(body={"action": "mkdir", "path": current_month}, sourceFilePath=f"{base_upload_dir}/{current_year}")
ag.files.manageOnDefaultSystem(body={"action": "mkdir", "path": current_day}, sourceFilePath=f"{base_upload_dir}/{current_year}/{current_month}")


# Finally, upload the files.
print(f"Files to upload: {files_to_upload}")
for fnap in files_to_upload:
    fileToUpload = open(fnap['filePath'], 'rb')
    res = ag.files.importData(fileName=fnap['fileName'], filePath=f"{base_upload_dir}/{current_year}/{current_month}/{current_day}", fileToUpload=fileToUpload)
