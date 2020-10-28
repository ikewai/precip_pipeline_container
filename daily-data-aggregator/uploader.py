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

base_url        = msg_dict['ul_base_url']
api_token       = msg_dict['ul_api_token']
files_to_upload = msg_dict['ul_files_to_upload']

def upload_file_via_curl(base_url, api_token, local_path, remote_path):
    upload_url = base_url + '/files/v2/media/system/mydata-mdodge'
    post_file = ('\'' + 'curl -sk -H "Authorization: Bearer ' + api_token + 
                 '" -X POST -F "fileToUpload=@' + local_path +
                 '" ' + upload_url + '\'')
    res = subprocess.run(["/bin/bash", "-c", post_file], capture_output=True).stdout.decode('utf8')
    return res

for file_path in files_to_upload:
    print('Trying to upload' + file_path + '.\n')
    upload_file_via_curl(base_url=base_url, api_token=api_token, local_path=file_path, remote_path='')
    

# Agavepy method (as opposed to curl)
# Make the ag object from our variables.
# ag = Agave(api_server=base_url, token=api_token)

# Time to start uploading files.
# Note to self: determine where stuff gets uploaded to 
# for file_path in files_to_upload:
    # print('Trying to upload' + file_path + '.')
    # ag.files_upload(files_to_upload[file_path], (''))