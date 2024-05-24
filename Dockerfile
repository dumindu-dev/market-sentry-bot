FROM ubuntu:22.04
LABEL maintainer="dumindu.chath@gmail.com"

RUN adduser --home /home/choreo -uid 10001 choreo
# && usermod -aG sudo choreo

RUN apt update && apt install wget -y

RUN wget https://dist.ballerina.io/downloads/2201.9.0/ballerina-2201.9.0-swan-lake-linux-x64.deb

RUN dpkg -i ballerina-2201.9.0-swan-lake-linux-x64.deb

COPY . /home/choreo

WORKDIR /home/choreo

RUN bal build

USER 10001

EXPOSE  8290

CMD bal run target/bin/greeter.jar