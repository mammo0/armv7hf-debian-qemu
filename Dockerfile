# build the resin-xbuild binary
FROM golang:stretch AS builder

WORKDIR /go/src/resin-xbuild
COPY src/resin-xbuild.go .

RUN go build -ldflags "-w -s" resin-xbuild.go

# get qemu-*-static
FROM multiarch/qemu-user-static:x86_64-aarch64 as qemu


# runtime stage
FROM balenalib/armv7hf-debian:stretch

COPY bin/ /usr/bin/
COPY --from=builder /go/src/resin-xbuild/resin-xbuild /usr/bin/
COPY --from=qemu /usr/bin/qemu-arm-static /usr/bin
COPY --from=qemu /usr/bin/qemu-aarch64-static /usr/bin
