FROM pjtatlow/kallisto-image-genomics-tcga:latest
RUN apt-get update && \
  apt-get install bedtools
COPY customProcess.sh /usr/local/bin/process
WORKDIR /working
CMD ["process"]
