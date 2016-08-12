#!/usr/bin/env python

import sys, os, glob, re, gzip

cancer_type = {}
with open(sys.argv[1],'r') as names:
    file_name = ""
    for line in names:
        line = line.strip()
        if file_name == "" and line[0:10] == "<filename>":
            line = line.replace("<filename>","").replace(".bam</filename>","")
            file_name = line
        elif file_name != "" and  line[0:14] == "<disease_abbr>":
            cancer_type[file_name] = line.replace("<disease_abbr>","").replace("</disease_abbr>","")
            file_name = ""
            
out = open(sys.argv[2],'w')
os.system("mkdir -p working")
out.write("CCLE_name\tCell_line_primary_name\ttranscript_id\ttranscript_id_versioned\tgene_id\tgene_id_versioned\thavana_gene\thavana_gene_versioned\thavana_transcript\thavana_transcript_versioned\ttranscript_name\tgene_name\ttype\tplatform\tlength\teff_length\tcounts_value\ttpm_value\n")

for output in sys.argv[3:]:
    path = output.replace("/abundance.tsv","").replace("/output","")
    sample_id = ""
    for char in path:
        sample_id += char
        if char == '/':
            sample_id = ""
    file_name = os.path.basename(output)
    print sample_id, file_name
    if sample_id in cancer_type.keys():
        with open(output,'r') as kallisto:
            for line in kallisto:
                line = line.strip().split()
                if line[0] != 'target_id':
                    ids = line[0].split('|')
                    out.write("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" % (sample_id, cancer_type[sample_id], ids[0].split('.')[0], ids[0],
                                                                                                            ids[1].split('.')[0], ids[1], ids[2].split('.')[0], ids[2],
                                                                                                            ids[3].split('.')[0], ids[3], ids[4], ids[5], ids[7], "Illumina HiSeq", line[1], line[2], line[3], line[4]))

    else:
        print >> sys.stderr, file_name + " not in dictionary!"
        out.close()
        sys.exit(1)
out.close()
