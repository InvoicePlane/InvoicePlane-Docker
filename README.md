# InvoicePlane Docker

Docker-compose with a webserver, MySQL, phpmyadmin and redis
- docker-compose.yml
- .env

## Building
Normally you build images to containers with the following command:
`docker-compose up nginx mysql php-fpm phpmyadmin redis workspace --build -d`
We've simplified this for you with a bash script:
`./buildmeup.sh` will build the containers for you (on Linux and on Mac)

## Starting
Normally you start containers with the following command:
`docker-compose up nginx mysql php-fpm phpmyadmin redis workspace -d`

We've simplified this for you with a bash script:
`./startmeup.sh` will start the containers for you (on Linux and on Mac)

## Getting inside a container
Normally you get into a container with the following command:
`docker-compose exec --user=ivpldock workspace bash`

We've simplified this for you with a bash script:
`./workmeup.sh` will get you inside a container (on Linux and on Mac)

## Directories

| Directory	|      Purpose   																											|
|----------	|:--------------------------------------------------------------:			|
| ./.docker 	|  for all the DockerFiles 	|																																				|
| ./sites 	|  for all the sites (for the nginx webserver)												|

### Origins
This script was originally called Laradock. We've forked it to target just the specific images that are needed to run InvoicePlane.

Link to Laradock: [laradock](https://github.com/laradock/laradock/)
We've included their license file in this repository.
