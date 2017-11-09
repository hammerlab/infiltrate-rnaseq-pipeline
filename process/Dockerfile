FROM pjtatlow/kallisto-image-genomics-tcga:latest
RUN apt-get update && \
  apt-get install -y bedtools \
  samtools \
  libtool \
  automake \
  autotools-dev \
  pkg-config \
  m4

# Install biobambam2
RUN mkdir -p /tmp/install
WORKDIR /tmp/install
RUN git clone https://github.com/gt1/libmaus2.git
RUN git clone https://github.com/gt1/biobambam2.git
WORKDIR /tmp/install/libmaus2
RUN libtoolize && \
  aclocal && \
  autoreconf -i -f && \
  ./configure && \
  make && \
  make install

WORKDIR /tmp/install/biobambam2
RUN autoreconf -i -f && \
  ./configure --with-libmaus2=/usr/local/lib && \
  make install

# get process code
COPY customProcess.sh /usr/local/bin/process
WORKDIR /working
ENV LD_LIBRARY_PATH=/usr/local/lib
CMD ["process"]
