import ntpath

with open('template.yaml', 'r') as t:
	template = t.read()

with open('../list_of_data.txt', 'r') as f:
	for line in f:
		line = line.strip()
		filename = ntpath.basename(line)
		trimmed_name = filename[:filename.index('.')]
		with open('jobs/%s.yaml' % filename, 'w') as w:
			w.write(template.format(**{
				'filename': trimmed_name, # this is a prefix
				'outputname': trimmed_name,
				'jobid': trimmed_name.lower().replace('_','-')
				}))