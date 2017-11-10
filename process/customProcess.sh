#!/bin/bash


usage="$(basename "$0") [-h] -i indexfile -o outputdir-name [-b bamfile | -f fastq-file] -- trim & process files using kallisto

where:
    -h  show this help text
    -i  path to indexfile (within this container, possibly mounted via -v)
    -o  output directory for this sample, within /outputs
    -b  path to bamfile, relative to /inputs
    -f  path to fastq file(s), relative to /inputs"


set -e; # quit on error

# What it does:

# 1. (optionally) convert bam to fastq
# 2. trim fastq
# 3. run kallisto

# example:
# ./process  -i Homo_sapiens.GRCh38.cdna.all.kallisto.idx -o ERR431606_out -f ERR431606.fastq.tar.gz
# this will process ERR431606_1.fastq.gz, ERR431606_2.fastq.gz with Kallisto index Homo_sapiens.GRCh38.cdna.all.kallisto.idx
# the results will be stored in output/ERR431606_out, and the logs will be stored in output/ERR431606_out/logs.

while getopts :i:o:b:f: option
do
 case "${option}"
 in
 i) indexname=${OPTARG};;
 o) outputname=${OPTARG};;
 b) bamfile=${OPTARG};;
 f) fastqfile=${OPTARG};;
 ?) echo "$usage"
    exit 0
    ;;
 esac
done
shift $((OPTIND - 1))

## remaining options listed in files

if [ "$bamfile" ]; then
  prefix="${bamfile%.*}"
  bamfile=/inputs/$bamfile
  gunzip=0
  untar=0
  untargz=0
  using_bam=1
else
  prefix="${fastqfile%%.*}"
  using_bam=0
  # determine if extension is tgz, tar.gz, or gz
  extension1="${filename#*.}" # full extension
  extension2="$filename##*.}" # last part of extension
  if [ "$extension1" == "tar.gz" ]; then
    untargz=1
    gunzip=0
    untar=0
  elif [ "$extension1" == "targz" ]; then
    untargz=1
    gunzip=0
    untar=0
  elif [ "$extension1" == "$extension2" ]; then
    untargz=0
    if [ "$extension1" == "tar" ]; then
      untar=1
      gunzip=0
    elif [ "$extension1" == "gz" ]; then
      untar=0
      gunzip=1
    fi
  fi
  fastqfile=/intput/$fastqfile
fi

if [ $using_bam -eq 1 ]; then
    echo "Using bam files"
else
    echo "using fastq files"
fi


# directories containing output
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

if [ $using_bam -eq 1 ]; then
	untrimmed=$(ls $fastq_untrimmed/*.fq | wc -l)
	if (( $untrimmed > 1 )); then
		echo -e "Untrimmed fastq files exist; skipping bamtofastq conversion" >> $logs/out.txt
	else 
		echo -e "Beginning conversion:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> $logs/time.txt
		#samtools sort -n $bamfile ${bamfile}.qsort
		#bamToFastq -i ${bamfile} -fq "fastq_untrimmed/${prefix}_1.fastq" >> logs/$outputname/out.txt
		bamtofastq filename=${bamfile} outputperreadgroupprefix=$prefix outputperreadgroup=1 collate=1 outputdir=$fastq_untrimmed &>> $logs/bamtofastq.log
	fi
elif [ $untargz -eq 1 ]; then
    tar xzf $fastqfile -C $fastq_untrimmed --strip=1 &>> $logs/untargz.txt
elif [ $untar == 1 ]; then
    tar xf $fastqfile -C $fastq_untrimmed --strip=1 &>> $logs/untar.txt
elif [ $gunzip == 1 ]; then
    cp $fastqfile $fastq_untrimmed && gunzip $fastq_untrimmed/*.gz &>> $logs/gunzip.tzt
fi

##### TRIM
untrimmed=$(ls $fastq_untrimmed/*.f*q | wc -l)
trimmed=$(ls $fastq_trimmed/*.fq | wc -l)
if [ $untrimmed != $trimmed ]; then
    echo -e "Trimming Fastq:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> $logs/time.txt
    taskFile="/tmp/gdsc_parallel_tasks_$prefix"
    rm -f $taskFile

    # automatically detects whether we have paired end reads (num > 1)
    num=$(ls $fastq_untrimmed/*.f*q | wc -l)
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
    cp $taskFile $logs


    chmod 777 $taskFile
    parallel -a $taskFile --ungroup --max-procs $cpu &>> $logs/trim_galore.log
    rm -f $taskFile

    untrimmed=$(ls $fastq_untrimmed/*.fq | wc -l)
    trimmed=$(ls $fastq_trimmed/*.fq | wc -l)

    if [ $untrimmed != $trimmed ]; then
      echo "Not all fastq files trimmed" &>> $logs/out.txt
      exit 1;
    fi

    echo -e "Finished Trimming Fastq:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> $logs/time.txt
    # note that trim_galore seems to name all files *.fq
fi

echo -e "Running Kallisto:\t$(date +"%Y-%m-%d %H:%M:%S:%3N")" >> $logs/time.txt
num=$(ls $fastq_trimmed/*.fq | wc -l)
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
