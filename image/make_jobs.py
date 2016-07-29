import ntpath

with open('template.yaml', 'r') as t:
	template = t.read()

samples = [] # e.g. ERR431566

with open('../list_of_data.txt', 'r') as f:
	for line in f:
		line = line.strip()
		filename = ntpath.basename(line)
		trimmed_name = filename[:filename.index('_')] # e.g. ERR431566
		samples.append(trimmed_name)
		assert len(trimmed_name) == len('ERR431566')

samples = list(set(samples)) # dedupe

for trimmed_name in samples:
	with open('jobs/%s.yaml' % trimmed_name, 'w') as w:
		w.write(template.format(**{
			'filename': trimmed_name, # this is a prefix
			'outputname': trimmed_name,
			'jobid': trimmed_name.lower().replace('_','-') # note though with this trimming we won't have underscores, but just to be safe
			}))