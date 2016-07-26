FROM ubuntu

RUN apt-get update && apt-get install -y build-essential cmake zlib1g-dev libhdf5-dev git hdf5-tools curl python gcc python-dev python-setuptools software-properties-common libncurses5-dev sysstat parallel
RUN apt-get install -y gawk
RUN add-apt-repository -y ppa:webupd8team/java
RUN apt-get update && apt-get install
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
RUN apt-get install -y oracle-java8-installer

RUN mkdir /working
WORKDIR /working

RUN mkdir /working/picardtools
COPY picardtools/ /working/picardtools
COPY sambamba /working
WORKDIR /working
COPY process /usr/local/bin/process
COPY logSar /usr/local/bin/logSar
COPY trim_galore /usr/local/bin/trim_galore
COPY getCPUs.py /usr/local/bin/getNumCPU

RUN git clone https://github.com/pachterlab/kallisto.git
WORKDIR /working/kallisto
RUN mkdir build
WORKDIR /working/kallisto/build
RUN cmake .. && make && make install

RUN easy_install -U pip
RUN pip install -U crcmod
RUN pip install --upgrade cutadapt


RUN echo 'ENABLED="true"' > /etc/default/sysstat
RUN echo "PATH=/usr/lib/sysstat:/usr/sbin:/usr/sbin:/usr/bin:/sbin:/bin" > /etc/cron.d/sysstat
RUN echo "* * * * * root command -v debian-sa1 > /dev/null && debian-sa1 1 1\n" >> /etc/cron.d/sysstat

CMD ["process"]
