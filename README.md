#  A set of docker containers to support the 'Ike Wai precipitation data pipeline.

  

These containers are intended to be used with the function-as-a-service [TACC Abaco API](https://tacc-cloud.readthedocs.io/projects/abaco/en/latest/), for resource-efficient on-demand execution.

This repo is still in heavy development.

----

### Contents

- Files for [`daily-data-aggregator`](https://hub.docker.com/repository/docker/ikewai/daily-data-aggregator): This container handles daily aggregation and processing of data into useful forms. Built on the [`ikewai/rainfallbase`](https://hub.docker.com/repository/docker/ikewai/rainfallbase) image.

- `docs`: Documentation on the architecture and usage of the containers and scripts. Currently out of date; will be improved once project is in production.

----
### Usage Overview
- Prerequisites: 
	- An account on the ['Ike Wai Gateway](https://github.com/ikewai/precip_pipeline_container). This account needs to be capable of reading and editing specific metadata(link coming soon), and [uploading files via the REST API](https://github.com/ikewai/precip_pipeline_container/blob/base/daily-data-aggregator/uploader.py). 
	- An account on the [TACC Cloud](https://portal.tacc.utexas.edu/). This account needs to be capable of [generating/refreshing auth tokens](https://tapis-project.github.io/live-docs/#tag/Tokens) and creating/executing containers on [Abaco](https://tacc-cloud.readthedocs.io/projects/abaco/en/latest/).


- Configuration:
	- `gateway_url`: The base URL of the gateway that you're storing metadata/files in. 
		- Example: `https://ikeauth.its.hawaii.edu`.  
	- `gateway_token`: The long-lived access token for your application on the gateway.
		- Example: `HxOf9qj174lh3rRZZBtCRKCPa9nj`
	- `gateway_user`: The user whose data folder this execution will be added to.
		- Example: `mdodge` 
	- `abaco_url`: The base URL of the abaco server that you're executing the container in.
		- Example: `https://tacc.tapis.io`
	- `abaco_acc`: The access token of your application on abaco.
		- Example: `HxOf9qj174lh3rRZZBtCRKCPa9nj`
	- `abaco_ref`: The refresh token of your application on abaco.
		- Example: `0N95CAOpbeTvzXUDKFL1BuYoWjpW`
	- `dirs_to_upload`: A comma-separated list of directories to upload to the gateway.
