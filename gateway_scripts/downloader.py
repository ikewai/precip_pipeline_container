# Needs to pull:
# - Station list
# - Previous day's cumulative data (if not first day of the month)

from agavepy import actors
import json

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
