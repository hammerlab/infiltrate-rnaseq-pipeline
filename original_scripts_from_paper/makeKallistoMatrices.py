#!/usr/bin/env python

import sys

samples = []
counts = {}
tpm = {}
i = 1
for in_file in sys.argv[3:]:
    id = in_file.split("/")
    id = id[1]
    samples.append(id)
    print "Reading", id, "\tNumber", i
    with open(in_file,'r') as kallisto_output:
        header = kallisto_output.readline()
        for line in kallisto_output:
            line = line.strip().split('\t')

            if i == 1:
                counts[line[0]] = []
                tpm[line[0]] = []

            counts[line[0]].append(line[3])
            tpm[line[0]].append(line[4])
    i += 1

length = 0
for key in counts.keys():
    if length == 0: length = len(counts[key])
    else:
        if len(counts[key]) != length:
            print key, "NOT LONG ENOUGH", length

print "Writing output"
i = 0
tpm_out = open(sys.argv[2],'w')

with open(sys.argv[1],'w') as counts_out:
    counts_out.write('\t' + '\t'.join(samples) + '\n')
    tpm_out.write('\t' + '\t'.join(samples) + '\n')
    for key in sorted(counts.keys()):
        i += 1
        print "Writing key number: ", i
        counts_out.write(key + '\t' + '\t'.join(counts[key]) + '\n')
        tpm_out.write(key + '\t' + '\t'.join(tpm[key]) + '\n')

tpm_out.close()
