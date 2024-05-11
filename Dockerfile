FROM ballerina/ballerina:2201.8.6
LABEL maintainer="dumindu.chath@gmail.com"

COPY . /home/ballerina

USER 10016

EXPOSE  8290

CMD bal run