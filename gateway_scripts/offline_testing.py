from os.path import exists
from io import TextIOWrapper
import os, json
from dotenv import load_dotenv
from pathlib import Path

if (exists("/container_scripts/offline.env")):
    # Make environment variables from file
    dotenv_path = Path('/container_scripts/offline.env')
    load_dotenv(dotenv_path=dotenv_path)

    # Tapis Cache Dir is set by the dotenv load.

    # Now, the currents environment variable is converted to a currents file.
    currents: dict = json.loads(os.environ.get('CURRENTS'))
    print(currents)
    currents_file: TextIOWrapper = open('/usr/src/app/.agave/currents', 'x')
    currents_file.write(json.dumps(currents))
    currents_file.close()
    