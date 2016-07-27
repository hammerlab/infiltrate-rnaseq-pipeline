
# TODO: rewrite this in unix fashion: silent on success. i.e. make docker output quiet and test the exit codes.

sudo rm -rf /mnt/disks/mz/rnatmp2;
mkdir /mnt/disks/mz/rnatmp2;

# this should work properly
docker run --rm -v /mnt/disks/mz/rnatmp2:/working maximz/download_rna:latest get_data quanta.cloudapp.net/test.txt.gz test.txt.gz /working;
echo $?;

# this should fail (file does not exist)
docker run --rm -v /mnt/disks/mz/rnatmp2:/working maximz/download_rna:latest get_data quanta.cloudapp.net/test2.txt.gz test2.txt.gz /working;
echo $?;

# this should fail (broken archive)
docker run --rm -v /mnt/disks/mz/rnatmp2:/working maximz/download_rna:latest get_data quanta.cloudapp.net/broken.gz broken.gz /working;
echo $?;

echo 'expected 0 1 1'