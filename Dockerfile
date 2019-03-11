# build the resin-xbuild binary
FROM golang:stretch AS builder

WORKDIR /go/src/resin-xbuild
COPY src/resin-xbuild.go .

RUN go build -ldflags "-w -s" resin-xbuild.go


# runtime stage
FROM balenalib/armv7hf-debian:stretch

COPY bin/ /usr/bin/
COPY --from=builder /go/src/resin-xbuild/resin-xbuild /usr/bin/
