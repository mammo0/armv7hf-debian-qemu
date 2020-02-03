# build the resin-xbuild binary
FROM golang:stretch AS builder

WORKDIR /go/src/resin-xbuild
COPY src/resin-xbuild.go .

RUN go build -ldflags "-w -s" resin-xbuild.go

# get qemu-*-static
FROM multiarch/qemu-user-static:latest as qemu


# runtime stage
FROM scratch

COPY bin/ /
COPY --from=builder /go/src/resin-xbuild/resin-xbuild /
COPY --from=qemu /usr/bin/qemu-arm-static /
COPY --from=qemu /usr/bin/qemu-aarch64-static /
