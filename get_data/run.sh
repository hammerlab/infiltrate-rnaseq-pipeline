rm -rf /mnt/disks/mz/rnatmp2;
mkdir /mnt/disks/mz/rnatmp2;
echo 'try: '
echo 'get_data quanta.cloudapp.net/test.txt.gz test.txt.gz /working'
docker run --rm -it -v /mnt/disks/mz/rnatmp:/working maximz/download_rna:latest bash