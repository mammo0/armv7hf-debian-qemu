# build the resin-xbuild binary
FROM golang:stretch AS go_builder

WORKDIR /go/src/resin-xbuild
COPY src/resin-xbuild.go .

RUN go build -ldflags "-w -s" resin-xbuild.go

# build qemu-*-static
FROM fedora:latest AS qemu_builder
ARG PKGNAME_S=qemu
ARG PKGNAME_L=$PKGNAME_S-user-static
# install build packages
RUN yum -y install yum-utils rpm-build
# get the qemu source package and install it to '/root/rpmbuild'
RUN yumdownloader --source $PKGNAME_L && \
    rpm -i $PKGNAME_S*.src.rpm
# install build dependencies and prepare building
RUN cd ~/rpmbuild/SPECS && \
    yum-builddep -y $PKGNAME_S.spec && \
    rpmbuild -bp $PKGNAME_S.spec
# apply the execve patch
COPY src/v3-linux-user-add-option-to-intercept-execve-syscalls.patch /
RUN cd ~/rpmbuild/BUILD/$PKGNAME_S* && \
    patch -p1 < /v3-linux-user-add-option-to-intercept-execve-syscalls.patch
# build the package
RUN cd ~/rpmbuild/SPECS && \
    rpmbuild -bc --short-circuit $PKGNAME_S.spec
# after the build the binaries are in the 'build-static/<arch>-linux-user' directory
# move the required binaries to root '/' directory (they can be copied easier later)
RUN cd ~/rpmbuild/BUILD/$PKGNAME_S*/build-static && \
    cp arm-linux-user/qemu-arm /qemu-arm-static && \
    cp aarch64-linux-user/qemu-aarch64 /qemu-aarch64-static


# runtime stage
FROM scratch

COPY bin/ /
COPY --from=go_builder /go/src/resin-xbuild/resin-xbuild /
COPY --from=qemu_builder /qemu-arm-static /
COPY --from=qemu_builder /qemu-aarch64-static /
