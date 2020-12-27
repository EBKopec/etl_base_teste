FROM golang:latest as builder

RUN mkdir /build

ADD . /build

WORKDIR /build

RUN export GO111MOLUDE=on
RUN go get github.com/EBKopec/etl_base_teste
RUN cd /build && git clone https://github.com/EBKopec/etl_base_teste.git

RUN cd /build/etl_base_teste && go build
RUN chmod -R 777 /build/etl_base_teste
# RUN ls -ltr /build/*
# RUN ls -ltr /build/etl_base_teste/etl_base_teste/*
EXPOSE 10000

ENTRYPOINT ["/build/etl_base_teste/etl_base_teste"]