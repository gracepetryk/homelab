FROM golang:alpine AS build

WORKDIR /dist

RUN apk add make

ADD https://github.com/tailscale/wireguard-go.git .
RUN make

FROM alpine:latest

COPY --from=build /dist/wireguard-go /usr/local/bin/wireguard-go
RUN chmod +x /usr/local/bin/wireguard-go

RUN apk add iproute2 wireguard-tools curl jq

COPY wg0.conf /etc/wireguard/
COPY resolv.conf /tmp/resolv.conf
COPY entrypoint.sh .

ENTRYPOINT ["/bin/sh", "entrypoint.sh", "wg0"]

