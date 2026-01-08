# Example: podman build --build-arg HAIKU_CROSS_COMPILER_ARCH=riscv64 --tag haiku-cross-compiler:riscv64 .

ARG HAIKU_CROSS_COMPILER_ARCH=x86_64

FROM ubuntu

# Because FUCKING docker can't even ship an image with working network out of the box
RUN apt-get update && apt-get install -y --no-install-recommends --reinstall ca-certificates

RUN apt-get update && apt-get install -y --no-install-recommends git nasm bc autoconf automake texinfo flex bison gawk build-essential unzip wget zip less zlib1g-dev libzstd-dev xorriso libtool gcc-multilib python3

RUN git clone https://github.com/LekKit/haiku-cross-compiler.git

# Build Haiku /boot/system to directly live alongside Linux container rootfs
RUN cd haiku-cross-compiler && ./build-rootfs.sh ${HAIKU_CROSS_COMPILER_ARCH} --rootfsdir / --jobs $(nproc)
RUN ln -sf /boot/system /system

# Install cross-compiler into /boot/system (Otherwise it doesn't work without extra args)
RUN cp -r /generated/cross-tools-${HAIKU_CROSS_COMPILER_ARCH}/* /boot/system/

# Install Haiku tools (package & jam) into the host
RUN mv /bin/jam /boot/system/bin/
RUN cp /generated/objects/linux/*/release/tools/package/package /usr/bin/
RUN cp /generated/objects/linux/lib/* /usr/lib/

# Symlink cross-compiler toolchain into the host
RUN bash -c "ln -sf /boot/system/bin/${HAIKU_CROSS_COMPILER_ARCH}-unknown-haiku-* /usr/bin/"

# Cleanup
RUN rm -rf /generated
