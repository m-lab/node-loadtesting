FROM measurementlab/phatbox

RUN apt-get update && apt-get install -y procps
RUN apt-get install -y vim
COPY run.sh /root/bin/


# docker build -t phatbox:v0.N .
