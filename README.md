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
