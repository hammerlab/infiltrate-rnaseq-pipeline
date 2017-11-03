FROM pjtatlow/kallisto-image-genomics-tcga:latest
RUN apt-get update && \
  apt-get install bedtools samtools
COPY customProcess.sh /usr/local/bin/process
WORKDIR /working
CMD ["process"]
