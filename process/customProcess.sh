#!/bin/bash

set -e; # quit on error

# What it does:

# 1. convert bam to fastq
# 2. trim fastq
# 3. run kallisto
# 4. tar up output and logs

# Arguments:
# 1. bam file name (in inputs dir)
# 2. kallisto index file name.
# 3. output folder name.

# example:
# ./process  Homo_sapiens.GRCh38.cdna.all.kallisto.idx ERR431606_out
# this will process ERR431606_1.fastq.gz, ERR431606_2.fastq.gz with Kallisto index Homo_sapiens.GRCh38.cdna.all.kallisto.idx
# the results will be stored in output/ERR431606_out, and the logs will be stored in logs/ERR431606_out.
# both of those directories will be targz'ed up at the end.

bamfile=/inputs/$1
prefix="${1%.*}"
indexname=$2;
outputname=$3;

fastq_untrimmed=output/$outputname/fastq_untrimmed
fastq_trimmed=output/$outputname/fastq_trimmed
logs=output/$outputname/logs
output=output/$outputname/

cd /working;
mkdir -p tars/;
mkdir -p $output;
mkdir -p $logs;
mkdir -p $fastq_untrimmed;
mkdir -p $fastq_trimmed;
echo -e "Starting\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> $logs/time.txt

logSar &
cpu=$(getNumCPU)
mem=$(free -h | gawk  '/Mem:/{print $2}')

echo "You have $cpu cores and $mem GB of memory" >> $logs/out.txt
echo -e "Beginning conversion:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> $logs/time.txt
#samtools sort -n $bamfile ${bamfile}.qsort
#bamToFastq -i ${bamfile} -fq "fastq_untrimmed/${prefix}_1.fastq" >> logs/$outputname/out.txt
bamtofastq filename=${bamfile} outputperreadgroupprefix=$prefix outputperreadgroup=1 collate=1 outputdir=$fastq_untrimmed &>> $logs/bamtofastq.log

##### TRIM
echo -e "Trimming Fastq:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> $logs/time.txt
taskFile="/tmp/gdsc_parallel_tasks_$prefix"
rm -f $taskFile

# automatically detects whether we have paired end reads (num > 1)
num=$(ls $fastq_untrimmed/*.fq | wc -l)
kallisto_option=""
if (( $num > 0 )); then
  for f1 in $(ls $fastq_untrimmed/*_1.*)
  do
    f2=${f1/_1\./_2.}
    if [ -f $f2 ]; then
      echo "trim_galore --paired $f1 $f2 --length 35 -o $fastq_trimmed/" >> $taskFile
    else
      echo "trim_galore $f1 --length 35 -o $fastq_trimmed/" >> $taskFile
    fi
  done
else
  for f1 in "fastq_untrimmed/*"
  do
      echo "trim_galore $f1 --length 35 -o $fastq_trimmed/" >> $taskFile
  done
fi
cp $taskfile $logs


chmod 777 $taskFile
parallel -a $taskFile --ungroup --max-procs $cpu &>> $logs/trim_galore.log
rm -f $taskFile

untrimmed=$(ls $fastq_untrimmed/*_1.fastq | wc -l)
trimmed=$(ls $fastq_trimmed/*.fq | wc -l)

if [ $untrimmed != $trimmed ]; then
  echo "Not all fastq files trimmed" &>> $logs/out.txt
  exit 1;
fi

echo -e "Finished Trimming Fastq:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> $logs/time.txt
# note that trim_galore seems to name all files *.fq


echo -e "Running Kallisto:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> $logs/time.txt
# kallisto command depends on whether we have paired-end reads
if (( $num > 1 )); then
  kallisto quant -i $indexname -b 30 -t $cpu --bias -o $output/ $(ls -d -1 $fastq_trimmed/*.fq) &>> $logs/kallisto.log
else
  kallisto quant -i $indexname -b 30 -t $cpu --bias --single -l 200 -s 5 -o $output/ $(ls -d -1 $fastq_trimmed/*.fq) &>> $logs/kallisto.log
fi
#echo -e "Taring output\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> $logs/time.txt
#tar -zcvf tars/$outputname.tar.gz output/$outputname/
#sar -A > logs/$outputname/sar.txt

#tar -zcvf tars/$outputname.logs.tar.gz logs/$outputname/*
#echo -e "Finished Taring output\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> logs/$outputname/time.txt
echo "DONE"
