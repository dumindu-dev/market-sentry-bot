FROM ballerina/ballerina:2201.8.6
LABEL maintainer="dumindu.chath@gmail.com"

USER root

RUN adduser choreo -G wheel --disabled-password --uid 10001

COPY . /home/choreo

USER 10001

WORKDIR /home/choreo

EXPOSE  8290

CMD bal run