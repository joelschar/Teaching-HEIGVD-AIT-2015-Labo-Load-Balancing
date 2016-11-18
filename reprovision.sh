#!/bin/bash

if [[ "$(docker ps -aq)" != "" ]]; then
echo "************************  Shutting down  ************************"""""""
    # Shutdown docker containers
    docker kill $(docker ps -aq)
    docker rm $(docker ps -aq)
fi

# Build the haproxy image
echo "************************  build haproxy image  ************************"
cd /vagrant/ha
sudo docker build -q -t softengheigvd/ha .

# Build the webapp image
echo "************************  build webapp image  ************************"
cd /vagrant/webapp
sudo docker build -q -t softengheigvd/webapp .

# Run two webapps
echo "************************  run webapps  *******************************"
sudo docker run -d --restart=always -e "TAG=s1" --name s1 softengheigvd/webapp
sudo docker run -d --restart=always -e "TAG=s2" --name s2 softengheigvd/webapp

# Run load balancer
echo "************************  run haproxy  *******************************"
sudo docker run -d -p 80:80 -p 1936:1936 -p 9999:9999 --restart=always -v /supervisor:/supervisor --link s1 --link s2 --name ha softengheigvd/ha