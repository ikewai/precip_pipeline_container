# A set of docker containers to support the 'Ike Wai precipitation data pipeline.

 These containers are intended to be used with the function-as-a-service [TACC Abaco API](https://tacc-cloud.readthedocs.io/projects/abaco/en/latest/), for resource-efficient on-demand execution.
 They can still be run as standalone containers of course, with proper configuration.
 
 Note that this repo is currently in heavy development. None of the containers are production-ready yet.
 
 An overview of each container:
 - `rainfall-core`: A base container with all the necessary dependencies to execute the workflows in the other containers.
 - `daily-data-aggregator`: This container handles daily aggregation and processing of data into useful forms.
 - `monthly-map-creator`: (coming soon) This container handles the monthly generation of rainfall prediction maps.

 More detailed documentation and graphics on the execution process can be found in the `docs` folder. 