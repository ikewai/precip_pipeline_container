from io import TextIOWrapper
from os.path import exists
from agavepy import actors
import os, json

from agavepy.agave import AttrDict

if exists("/container_scripts/offline.env"):
    print("offline.env exists, skipping set_env.py")
    exit(0)

# Pull variables from abaco message.
# msg is a python dictionary, returned from the JSON-parsing get_context().
msg_base: AttrDict = actors.get_context()
if "json" in msg_base['content_type']:
    msg: dict = msg_base['message_dict']
    # Set location for agavepy to look for the "currents" file when running Agave.restore()
    os.environ['TAPIS_CACHE_DIR'] = msg['TAPIS_CACHE_DIR']

    # Build the "currents" file.
    currents: dict = {
        "refresh token": "",
        "expires_in": "",
        "expires_at": "",
        "created_at": "",
        "username": msg['GATEWAY_USERNAME'],
        "token_username": None,
        "client_name": msg['GATEWAY_CLIENT_NAME'],
        "use_nonce": False,
        "verify": True,
        "proxies": {},
        "tenantid": None,
        "apisecret": msg['GATEWAY_API_SECRET'],
        "apikey": msg['GATEWAY_API_KEY'],
        "baseurl": msg['GATEWAY_BASE_URL'],
        "access_token": msg['GATEWAY_ACCESS_TOKEN'],
    }
    currents_file: TextIOWrapper = open('/usr/src/app/.agave/currents', 'x')
    currents_file.write(json.dumps(currents))
    currents_file.close()
else:
    print("the message isn't in json format.")
    exit(1)