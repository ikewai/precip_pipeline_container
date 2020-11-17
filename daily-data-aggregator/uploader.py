# Data uploader for workflow automation using the Agave (v2) API for actors,
# and the usual REST requests for upload.


# Notes for continued implementation:
# The message sent to the actor needs to be a JSON object that includes the following:
# - ul_upload_url:  The base URL to access the science gateway that files will be stored in.
# - ul_api_token:   The api token to run this uploader with.
# - ul_ref_token:   The refresh token to refresh the api token, if this container
#                   takes a very long time to execute.
# - ul_dirs_to_upload:  A JSON object, serving as a list of the absolute paths
#                       of the directories we want to upload during this run.
#                       Typically, this will be the same across runs unless
#                       something is being debugged, tested, or added.

import json
import os
import requests
import mimetypes
from agavepy import actors
from agavepy import Agave

# Pull variables from abaco message.
# msg is a python dictionary, returned from the JSON-parsing get_context().
# api_token is a short-lived (intended for single execution) access-only token.
msg = actors.get_context()
if "json" in msg['content_type']:
    msg_dict = msg['message_dict']
else:
    print("the message isn't in json format.")
    exit(1)

upload_url      = msg_dict['ul_upload_url']
api_token       = msg_dict['ul_api_token']
ref_token       = msg_dict['ul_ref_token']
dirs_to_upload = json.loads(msg_dict['ul_dirs_to_upload'])

# TODO: Check if api_token will still be valid for the next 30 minutes,
#       refresh using ref_token it if it won't.


#  If any of these files end up being very large, it is recommended to use stream
#  uploading. That will require pulling in the requests-toolbelt library,
#  as recommended by the documentation for the requests library.
def upload_files_via_requests(upload_url, api_token, dirs_to_upload):
    headers = {
        'accept': 'application/json',
        'authorization': "Bearer " + api_token,
        'content-type': 'application/json; charset=utf-8'
    }
    
    # map csv to text/csv instead of application/vnd.ms-excel
    mimetypes.add_type('text/csv', '.csv', strict=True)

    file_list = []
    for directory in dirs_to_upload:
        for file in os.listdir(path=directory):
            # Append this file to the list of files.
            file_list.append(
                ('file', (file, open(directory+file, 'rb'), mimetypes.guess_type(file)))
            )
    res = requests.post(headers=headers, url=upload_url, files=file_list)
    print(res)

# Finally, upload the files.
upload_files_via_requests(upload_url, api_token, dirs_to_upload)