FROM ballerina/ballerina:2201.8.6
LABEL maintainer="dumindu.chath@gmail.com"

COPY . /home/ballerina

RUN addgroup -g 10016 choreo && adduser --disabled-password --no-create-home --uid 10016 --ingroup choreo choreouser

USER 10016

EXPOSE  8290

CMD bal run