from ingest import Ingest
import pprint
from pathlib import Path
import specs

obj = Ingest('../schema')
schema = obj.ingest_dir()
mcol = specs.column_spec_iter(schema, 'matches')
gcol = specs.column_spec_iter(schema, 'games')
acol = specs.column_spec_iter(schema, 'adec')
pprint.pprint(list(acol))
mcon = specs.constraint_spec_iter(schema, 'matches')
gcon = specs.constraint_spec_iter(schema, 'games')
acon = specs.constraint_spec_iter(schema, 'adec')
pprint.pprint(list(acon))
