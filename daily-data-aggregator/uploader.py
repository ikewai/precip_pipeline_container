# Data uploader for workflow automation using the Agave (v2) API for actors,
# and the usual REST requests for upload.


# Notes for continued implementation:
# The message sent to the actor needs to be a JSON object that includes the following:
# - ul_base_url: The base URL to access the science gateway that files will be stored in.
# - ul_api_token: The short-lived access-only token to run this uploader with.
# - ul_files_to_upload: A JSON object, serving as a list of the absolute paths
#                       of the files we want to upload during this run.
#                       Typically, this will be the same across runs unless
#                       something is being debugged, tested, or added.

import json
import os
import subprocess
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
files_to_upload = json.loads(msg_dict['ul_files_to_upload'])

# Old curl implementation.
def upload_file_via_curl(base_url, api_token, local_path, remote_path):
    upload_url = base_url + '/files/v2/media/system/mydata-mdodge'
    post_file = ('\'' + 'curl -sk -H "Authorization: Bearer ' + api_token + 
                 '" -X POST -F "fileToUpload=@' + local_path +
                 '" ' + upload_url + '\'')
    res = subprocess.run(["/bin/bash", "-c", post_file], capture_output=True).stdout.decode('utf8')
    return res

# New python/requests implementation. It still needs some work.
# This is currently (naively) assuming all uploads will be CSVs.
# Will update to include content type as a parameter.
# Also, if any of these files are large, it is recommended to use stream
#  uploading. That will require pulling in the requests-toolbelt library,
#  as recommended by the documentation for the requests library.
def upload_file_via_requests(base_url, api_token, local_path, remote_path):
    headers = {
        'accept': 'application/json',
        'authorization': "Bearer " + api_token,
        'content-type': 'application/json; charset=utf-8'
    }
    files = {}
    for file_path in files_to_upload:
        # Parse for file name.
        # code here
        files.update{
            'file': ('example_file_name.csv', open(local_path, 'rb'))
        }
    urlString = upload_url
    res = requests.post(url=, files)

for file_path in files_to_upload:
    print('Trying to upload' + file_path + '.\n')
    upload_file_via_curl(base_url=base_url, api_token=api_token, local_path=file_path, remote_path='')
    