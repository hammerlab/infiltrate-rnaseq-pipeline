#!/usr/bin/env python

import sys, os, glob, re, gzip

samples = {}
with open(sys.argv[1],'r') as tcga:
    header = tcga.readline()
    for line in tcga:
        line = line.strip().split(',')
        tcga_id = line[0]
        cancer_type = line[1]
        gchub_id = line[9]
        samples[gchub_id] = [tcga_id, cancer_type]

out = open(sys.argv[2],'w')
out.write("TCGA_ID\tGCHUB_ID\tCancer Type\ttranscript_id\ttranscript_id_versioned\tgene_id\tgene_id_versioned\thavana_gene\thavana_gene_versioned\thavana_transcript\thavana_transcript_versioned\ttranscript_name\tgene_name\ttype\tlength\teff_length\tcounts_value\ttpm_value\n")
i = 0

for output in sys.argv[3:]:
    i += 1
    path = output.replace("/abundance.tsv","").replace("/output","")
    sample_id = ""
    for char in path:
        sample_id += char
        if char == '/':
            sample_id = ""
    with open(output,'r') as kallisto:
        for line in kallisto:
            line = line.strip().split()
            if line[0] != 'target_id':
                ids = line[0].split('|')
                out.write("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" % (samples[sample_id][0], sample_id, samples[sample_id][1] , ids[0].split('.')[0], ids[0],
                                                                                                            ids[1].split('.')[0], ids[1], ids[2].split('.')[0], ids[2],
                                                                                                            ids[3].split('.')[0], ids[3], ids[4], ids[5], ids[7], line[1], line[2], line[3], line[4]))
    print "finished", output, i
out.close()
