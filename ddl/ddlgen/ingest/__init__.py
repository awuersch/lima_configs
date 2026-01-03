# ingest package initialization

import os
import collections
from pathlib import Path
import re

# compiled regexes
blank = re.compile(r'\s*$')
comment = re.compile(r'\s*#')
has_comment = re.compile(r'#')
comment_to_end = re.compile(r'\s*#.*$')

class Ingest:
  # add schema dir to object
  def __init__(self, dir, sep = '\t'):
    self.dir = Path(dir)
    self.sep = sep
  
  def dir(self):
    return self.dir

  def sep(self):
    return self.sep

  # location
  Location = collections.namedtuple('Loc', ('dir', 'name'))
  # provenance
  Provenance = collections.namedtuple('Prov', ('loc', 'lineno'))
  
  def provenance_to_plain(self, tup):
    """convert a provenance named tuple to a plain tuple"""
    if isinstance(tup, self.Provenance):
      loc, lineno = tup
      return str(loc.dir), str(loc.name), lineno
    return ()

  def readlines_iter(self, name):
    """read a basename into a iterator of (provenance, line) tuples.
       skip blank and comment lines,
       remove end of line comments,
       and strip out trailing newlines."""
    # prepend dir
    path = self.dir / name
    with path.open() as f:
      lines = f.readlines()
      for lineno, line in enumerate(lines):
        if blank.match(line) == None and comment.match(line) == None:
          prov = self.Provenance(self.Location(self.dir, name), lineno)
          line = comment_to_end.sub('', line) \
              if has_comment.search(line) != None \
              else line.rstrip()
          yield (prov, line)
  
  def to_table_dict(self, tups):
    """convert a list of (provenance, line) tuples
       to a table -> [(provenance, fields) ...] dictionary.
       while doing so,
         skip blank and comment lines,
         remove end of line comments, and
         strip out newlines."""
    table_dict = dict()
    for provenance, line in tups:
      # head, tail
      table, *fields = line.split(self.sep)
      if table not in table_dict:
        table_dict[table] = list()
      table_dict[table].append((provenance, fields))
    return table_dict

  def to_column_dict(self, tups):
    """convert (provenance, [column, field, ...]) tuples
       to a column -> [(provenance, [field, ...]) ...] dictionary
       with key ordering by line number."""
    return {(prov.lineno, column):(prov, fields)
        for prov, [column, *fields] in tups}

  # schema structure is { basename : { table : [(prov, [field, ...]) ...] } }
  def ingest_dir(self):
    return {
      basename : self.to_table_dict(self.readlines_iter(basename))
      for basename in [path.name for path in Path.iterdir(self.dir)]}
