prefix="/working"

import ntpath

with open('template.yaml', 'r') as t:
	template = t.read()

with open('list_of_data.txt', 'r') as f:
	for line in f:
		line = line.strip()
		filename = ntpath.basename(line)
		with open('jobs/%s.yaml' % filename, 'w') as w:
			w.write(template.format(**{
				'url': line,
				'filename': filename,
				'prefix': prefix,
				'jobid': filename[:filename.index('.')].lower().replace('_','-')
				}))