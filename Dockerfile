FROM ballerina/ballerina:2201.8.6
LABEL maintainer="dumindu.chath@gmail.com"

COPY . /home/ballerina

RUN adduser choreo -G wheel --disabled-password --no-create-home --uid 10001

USER 10001

EXPOSE  8290

CMD bal run