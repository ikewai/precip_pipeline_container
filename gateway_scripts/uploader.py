# Data uploader for workflow automation using the Agave (v2) API for actors,
# and the usual REST requests for upload.


# Notes for continued implementation:
# The message sent to the actor needs to be a JSON object that includes the following:
# - gw_upload_url:  The base URL to access the science gateway that files will be stored in.
# - gw_api_token:   The api token to run this uploader with.

import json
import os
import requests
import mimetypes
from agavepy import actors
from agavepy import Agave

# Pull variables from abaco message.
# msg is a python dictionary, returned from the JSON-parsing get_context().
# api_token is a permanent token.
msg = actors.get_context()
if "json" in msg['content_type']:
    msg_dict = msg['message_dict']
else:
    print("the message isn't in json format.")
    exit(1)

upload_url      = msg_dict['gw_upload_url']
api_token       = msg_dict['gw_api_token']

# Set up upload directories
with open("file_list.json") as file_list:
    dirs_to_upload = json.loads(file_list.read())
# Directories will probably be programmatically changed, based on year/month/day


def upload_files_via_requests(upload_url, api_token, dirs_to_upload):
    headers = {
        'accept': 'application/json',
        'authorization': "Bearer " + api_token,
        'content-type': 'application/json; charset=utf-8'
    }
    
    # map csv to text/csv instead of application/vnd.ms-excel
    mimetypes.add_type('text/csv', '.csv', strict=True)

    file_list = []
    for directory in dirs_to_upload['dirs']: # need to ensure that directory has a slash at end - os.path.join (directory, filename)
        for file in os.listdir(path=directory): # check for cases where directories are nested within the directories here
            # Append this file to the list of files.
            file_list.append(
                ('file', (file, open(directory+file, 'rb'), mimetypes.guess_type(file)))
            )
    res = requests.post(headers=headers, url=upload_url, files=file_list)
    print(res)

# Finally, upload the files.

print(f"Upload URL: {upload_url}\nApi token: {api_token}\nDirs to upload: {dirs_to_upload}")
#res = upload_files_via_requests(upload_url, api_token, dirs_to_upload)

# take action based on response (success, etc)