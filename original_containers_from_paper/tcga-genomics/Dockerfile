FROM ubuntu

RUN apt-get update && apt-get install -y build-essential cmake zlib1g-dev libhdf5-dev git hdf5-tools curl python gcc python-dev python-setuptools software-properties-common libncurses5-dev sysstat gawk pigz parallel

RUN mkdir /working
WORKDIR /working

COPY process /usr/local/bin/process
COPY logSar /usr/local/bin/logSar
COPY getCPUs.py /usr/local/bin/getNumCPU
COPY trim_galore /usr/local/bin/trim_galore

RUN git clone https://github.com/pachterlab/kallisto.git
WORKDIR /working/kallisto
RUN mkdir build
WORKDIR /working/kallisto/build
RUN cmake .. && make && make install

RUN easy_install -U pip
RUN pip install --upgrade cutadapt

RUN echo 'ENABLED="true"' > /etc/default/sysstat

CMD ["process"]
