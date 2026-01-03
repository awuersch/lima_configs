#! /usr/bin/python3

# ingest and show all schema-related structures
from ingest import Ingest
from pathlib import Path, PurePath
import pprint

dir = '../schema'
obj = Ingest(dir)
pprint.pprint(obj.dir)
l = [path.name for path in Path.iterdir(obj.dir)]
pprint.pprint(repr(l))
schema = obj.ingest_dir()
pprint.pprint(schema)
table_dict = dict()
for table, tuples in schema['cols'].items():
  column_dict = {column:(obj.provenance_to_plain(prov),fields)
    for column, (prov, fields) in obj.to_column_dict(tuples).items()}
  table_dict[table] = column_dict
pprint.pprint(table_dict)
