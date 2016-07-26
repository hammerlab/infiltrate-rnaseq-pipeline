rm -rf /mnt/disks/mz/rnatmp;
mkdir /mnt/disks/mz/rnatmp;
cp ~/rna/ERR431606_1.fastq.gz /mnt/disks/mz/rnatmp/
cp ~/rna/ERR431606_2.fastq.gz /mnt/disks/mz/rnatmp/
cp ~/rna/b37.kallisto.idx /mnt/disks/mz/rnatmp/
echo 'try: '
echo 'process b37.kallisto.idx testout'
docker run --rm -it -v /mnt/disks/mz/rnatmp:/working maximz/rnapipeline:latest bash