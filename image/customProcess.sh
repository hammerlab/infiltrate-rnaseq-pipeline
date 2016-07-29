#!/bin/bash

set -e; # quit on error

# What it does:
# 1. un-gzip fastq data
# 2. trim fastq
# 3. run kallisto
# 4. tar up output and logs

# Arguments:
# 1. prefix for reads, whose filenames end in .fastq.gz
# 2. kallisto index file name.
# 3. output folder name.

# example:
# ./process ERR431606 Homo_sapiens.GRCh38.cdna.all.kallisto.idx ERR431606_out
# this will process ERR431606_1.fastq.gz, ERR431606_2.fastq.gz with Kallisto index Homo_sapiens.GRCh38.cdna.all.kallisto.idx
# the results will be stored in output/ERR431606_out, and the logs will be stored in logs/ERR431606_out.
# both of those directories will be targz'ed up at the end.

prefix=$1;
indexname=$2;
outputname=$3;

cd /working;
mkdir -p tars/;
mkdir -p output/$outputname/;
mkdir -p logs/$outputname/;
mkdir -p fastq_untrimmed;
mkdir -p fastq_trimmed;
echo -e "Starting\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" > logs/$outputname/time.txt

logSar &
cpu=$(getNumCPU)
mem=$(free -h | gawk  '/Mem:/{print $2}')

echo "You have $cpu cores and $mem GB of memory" >> logs/$outputname/out.txt
echo -e "Beginning ungzip:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> logs/$outputname/time.txt

# check to see if files were already ungzipped (interrupted job)
if [[ ! -f fastq_untrimmed/$prefix_1.fastq || ! -f fastq_untrimmed/$prefix_2.fastq ]]; then
    # echo "not already ungzipped"
  # gunzip (this WILL delete original files only if successful)
  # unpigz is a parallel version of gunzip
  ungz="unpigz -f $prefix*.fastq.gz"
  echo $ungz >> logs/$outputname/out.txt
  $ungz >> logs/$outputname/out.txt

  mv $prefix*.fastq fastq_untrimmed

  echo -e "Finished UNTAR:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> logs/$outputname/time.txt
fi

##### TRIM

echo -e "Trimming Fastq:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> logs/$outputname/time.txt
taskFile="/tmp/gdsc_parallel_tasks_$prefix"
rm -f $taskFile

# automatically detects whether we have paired end reads (num > 0)
num=$(ls fastq_untrimmed/$prefix*_1.* | wc -l)
kallisto_option=""
if (( $num > 0 )); then
  for f1 in "fastq_untrimmed/$prefix*_1.*"
  do
    f2=${f1/_1\./_2.}
    if [ -f $f2 ]; then
      echo "trim_galore --paired $f1 $f2 --length 35 -o fastq_trimmed/" >> $taskFile
    else
      echo "trim_galore $f1 --length 35 -o fastq_trimmed/" >> $taskFile
    fi
  done
else
  for f1 in "fastq_untrimmed/$prefix*"
  do
      echo "trim_galore $f1 --length 35 -o fastq_trimmed/" >> $taskFile
  done
fi


chmod 777 $taskFile
parallel -a $taskFile --ungroup --max-procs $cpu &>> logs/$outputname/out.txt
rm -f $taskFile

untrimmed=$(ls fastq_untrimmed/$prefix* | wc -l)
trimmed=$(ls fastq_trimmed/$prefix*.fq | wc -l)

if [ $untrimmed != $trimmed ]; then
  echo "Not all fastq files trimmed" &>> logs/$outputname/out.txt
  exit 1;
fi

echo -e "Finished Trimming Fastq:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> logs/$outputname/time.txt
# note that trim_galore seems to name all files *.fq


echo -e "Running Kallisto:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> logs/$outputname/time.txt
# kallisto command depends on whether we have paired-end reads
if (( $num > 0 )); then
  kallisto quant -i $indexname -b 30 -t $cpu --bias -o output/$outputname/ $(ls -d -1 fastq_trimmed/$prefix*.fq) &>> logs/$outputname/out.txt
else
  kallisto quant -i $indexname -b 30 -t $cpu --bias --single -l 200 -s 5 -o output/$outputname/ $(ls -d -1 fastq_trimmed/$prefix*.fq) &>> logs/$outputname/out.txt
fi
echo -e "Taring output\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> logs/$outputname/time.txt
tar -zcvf tars/$outputname.tar.gz output/$outputname/
sar -A > logs/$outputname/sar.txt

tar -zcvf tars/$outputname.logs.tar.gz logs/$outputname/*
echo -e "Finished Taring output\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> logs/$outputname/time.txt
echo "DONE"
