# Script to launch rainfall container in Abaco.
# Requires tapipy (Tapis v3)

### Add: log execution ID, success/fail, error codes, and notify via email to [address] if run has problems
### - include email/smtp library - check if abaco/tapis has email address callback, as this might be easier for notification.

import json
import os
import requests
from tapipy.tapis import Tapis

# Variables from execute_rainfall.config (JSON)
config = json.load("execute_rainfall.config")

# Initialize Tapis object
t = Tapis(
    base_url='https://tacc.tapis.io',
    tenant_id='tacc',
    account_type='user',
    access_token=config['abaco_acc'],
    refresh_token=config['abaco_ref']
)

# Arrange environment variables to pass to daily-data-aggregator
msg                      = dict(gw_upload_url="", gw_api_token="", gw_user="", gw_dirs_to_upload="")
msg['gw_upload_url']     = config['gateway_url'] + '/files/v2/media/system/mydata-' + config['gateway_user'] + '/'
msg['gw_api_token']      = config['gateway_token']
msg['gw_dirs_to_upload'] = config['directories_to_upload']

# Check if any changes have been made to daily-data-aggregator
# - Keep the id of the build as a value in config
# - Ask DockerHub what the latest image is
# - Evaluate to true if the latest image has a different id

## Talk with TACC to get hash of container from actor ID
if ('changes to daily-data-aggregator'):
    'refresh auth with tacc, then create new actor with updated image'
    'set the actor id of the new actor in (probably a metadata object if this script'
    '  is to run in a container)'
else:
    'refresh authentication tokens with tacc'

# Construct JSON object with tokens
msg_str = json.dumps(msg)

# Send message to TACC to execute rainfall container on Abaco,
#  with said message's JSON holding the necessary environment variables. 
# These variables are:
# - ul_upload_url:  The base URL to access the science gateway that files will be stored in.
# - ul_api_token:   The api token to run this uploader with.
# - ul_dirs_to_upload:  A JSON object, serving as a list of the absolute paths
#                       of the directories we want to upload during this run.
#                       Typically, this will be the same across runs unless
#                       something is being debugged, tested, or added.

# Log the execution ID, success/fail, error codes, and 
