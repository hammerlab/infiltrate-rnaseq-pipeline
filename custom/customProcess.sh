#!/bin/bash

# What it does:
# 1. un-gzip fastq data
# 2. trim fastq
# 3. run kallisto
# 4. tar up output and logs

# Arguments:
# OLD 1. first of the paired end reads, ending in .fastq. Corresponds to an input file with that name with .gz
# OLD 2. second of the paired end reads, ending in .fastq. Corresponds to an input file with that name with .gz
# 1. kallisto index file name.
# 2. output filename.

echo -e "Starting\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" > time.txt
logSar &
cd working

cpu=$(getNumCPU)

mem=$(free -h | gawk  '/Mem:/{print $2}')

echo "You have $cpu cores and $mem GB of memory" >> out.txt
echo -e "Beginning ungzip:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> time.txt
mkdir -p output
mkdir -p fastq_untrimmed
mkdir -p fastq_trimmed


ungz="gunzip *.fastq.gz"
echo $ungz >> out.txt
$ungz >> out.txt

mv *.fastq fastq_untrimmed



# echo $1 >> out.txt # first of the paired end reads
# untar="gunzip $1.gz && mv $1 fastq_untrimmed/" # gunzip automatically deletes orig file
# echo $untar >> out.txt
# $untar >> out.txt

# echo $2 >> out.txt # second of the paired end reads
# untar="gunzip $2.gz && mv $2 fastq_untrimmed/" # gunzip automatically deletes orig file
# echo $untar >> out.txt
# $untar >> out.txt

#unpigz fastq_untrimmed/*.gz >> out.txt
echo -e "Finished UNTAR:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> time.txt


##### TRIM

echo -e "Trimming Fastq:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> time.txt
taskFile=/tmp/gdsc_parallel_tasks
rm -f $taskFile

# automatically detects whether we have paired end reads (num > 0)
num=$(ls fastq_untrimmed/*_1.* | wc -l)
kallisto_option=""
if (( $num > 0 )); then
  for f1 in fastq_untrimmed/*_1.*
  do
    f2=${f1/_1\./_2.}
    if [ -f $f2 ]; then
      echo "trim_galore --paired $f1 $f2 --length 35 -o fastq_trimmed/" >> $taskFile
    else
      echo "trim_galore $f1 --length 35 -o fastq_trimmed/" >> $taskFile
    fi
  done
else
  for f1 in fastq_untrimmed/*
  do
      echo "trim_galore $f1 --length 35 -o fastq_trimmed/" >> $taskFile
  done
fi


chmod 777 $taskFile
parallel -a $taskFile --ungroup --max-procs $cpu &>> out.txt
rm -f $taskFile

untrimmed=$(ls fastq_untrimmed/* | wc -l)
trimmed=$(ls fastq_trimmed/*.fq | wc -l)

if [ $untrimmed != $trimmed ]; then
  echo "Not all fastq files trimmed" &>> out.txt
  exit 1;
fi

rm -rf fastq_untrimmed

echo -e "Finished Trimming Fastq:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> time.txt
# note that trim_galore seems to name all files *.fq


echo -e "Running Kallisto:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> time.txt
# kallisto command depends on whether we have paired-end reads
if (( $num > 0 )); then
  kallisto quant -i $1 -b 30 -t $cpu --bias -o output/ $(ls -d -1 fastq_trimmed/*.fq) &>> out.txt
else
  kallisto quant -i $1 -b 30 -t $cpu --bias --single -l 200 -s 5 -o output/ $(ls -d -1 fastq_trimmed/*.fq) &>> out.txt
fi
echo -e "Taring output\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> time.txt
tar -zcvf $2.tar.gz output
sar -A > sar.txt

tar -zcvf $2.logs.tar.gz *.txt
echo -e "Finished Taring output\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> time.txt
echo "DONE"
