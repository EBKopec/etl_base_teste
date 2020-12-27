FROM golang:latest

RUN rm -rf /build
RUN mkdir /build
ADD . /build
RUN cat /build/main.go | grep "file"
RUN cat /build/docker-compose.yml | grep "app-data"
WORKDIR /build

RUN export GO111MOLUDE=on
RUN go get github.com/EBKopec/etl_base_teste
RUN cd /build && git clone https://github.com/EBKopec/etl_base_teste.git

RUN cd /build && go build

# RUN ls -ltr /build/*
RUN ls -ltr /build/etl_base_teste/*

EXPOSE 10000

ENTRYPOINT ["/build/etl_base_teste"]
