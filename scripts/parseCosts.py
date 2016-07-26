#!/usr/bin/env python
import sys, json, re, time
from datetime import datetime

charges = []

with open(sys.argv[1],'r') as billing_file:
    for line in billing_file:
        line = line.replace(",\n","")
        line = re.sub(r'([{,]\s{0,})([^\"\\,\]\}\{\[ ]{2,})(\s?:)',r'\1"\2"\3', line)
        line = re.sub(r':\s?([^\\,\]\}\{\[]{2,})',r': "\1"', line)
        line = re.sub(r'([\[,]\s{0,})([^\,\]\[\"\{\}]{1,})([,\]])',r'\1"\2"\3', line)
        line = re.sub(r'([\[,]\s{0,})([^\,\]\[\"\{\}]{1,})([,\]])',r'\1"\2"\3', line)
        line = re.sub(r'\"(\s{0,}\d+\.?\d+\s{0,})\"',r'\1',line)
        charges.append(json.loads(line))

start_date = time.strptime(sys.argv[2],"%m-%d-%Y")
end_date = time.strptime(sys.argv[3],"%m-%d-%Y")

ignore = []
for item in sys.argv[4:]:
    ignore.append(item)

total = 0
for charge in charges:
    start = time.strptime(charge['startTime'], "%Y-%m-%dT%H:%M:%S-07:00")
    if start > start_date and start < end_date and charge['description'] not in ignore:
        print charge['description'], charge['cost']['amount']
        total += charge['cost']['amount']
print "Total: " + str(total)
