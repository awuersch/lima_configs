from ingest import Ingest
import specs
from toposort import toposort, toposort_flatten

class Pgsql:
  def __init__(self, dir):
    self.ingest_obj = Ingest(dir)
    self.schema = self.ingest_obj.ingest_dir()
    self.name_to_enum_spec = {
        name:vals for name, vals in specs.enum_specs_iter(self.schema)}
    self.name_to_array_spec = {
        name:vals for name, vals in specs.array_specs_iter(self.schema)}
    self.indent_length = 2
    self.indent = ' ' * self.indent_length

  datatype_to_pgtype = {
    specs.Type.bool:'BOOL',
    specs.Type.int:'SMALLINT',
    specs.Type.id:'INTEGER',
    specs.Type.idx:'INTEGER',
    specs.Type.string:'TEXT',
    specs.Type.float:'FLOAT',
    specs.Type.date:'DATE',
    specs.Type.side:'side',
    specs.Type.result:'result',
    specs.Type.owner:'owner',
    specs.Type.onmove:'onmove',
    specs.Type.action:'action',
    specs.Type.skill:'skill',
    specs.Type.luck:'luck',
    specs.Type.eval:'eval',
    specs.Type.met:'met',
    specs.Type.post_crawford:'post_crawford',
    specs.Type.score:'score',
    specs.Type.move:'move',
    specs.Type.dice:'dice',
    specs.Type.probs:'probs',
    specs.Type.prices:'prices',
    specs.Type.surrogate:'SERIAL'}

  def sql_identifier(self, name):
    """return an identifier valid for sql (perhaps just postgresql)"""
    return name.replace('-','_').replace(' ','$')

  def enum_type_decl(self, name):
    # allow datatypes or strings
    datatype = name if isinstance(name, specs.Type) else specs.name_to_type[name]
    name = specs.type_to_name[name] if isinstance(name, specs.Type) else name
    identifier = self.sql_identifier(name)
    prov, vals = self.name_to_enum_spec[datatype][0]
    comment = repr(self.ingest_obj.provenance_to_plain(prov))
    return ['CREATE TYPE ' +
        identifier +
        ' AS ENUM (' +
        ', '.join([repr(val) for val in vals]) +
        ')' +
        '; -- see: ' +
        comment]

  def array_domain_decl(self, name):
    # allow datatypes or strings
    datatype = name if isinstance(name, specs.Type) else specs.name_to_type[name]
    name = specs.type_to_name[name] if isinstance(name, specs.Type) else name
    identifier = self.sql_identifier(name)
    prov, [dtname, *dims] = self.name_to_array_spec[datatype][0]
    comment = repr(self.ingest_obj.provenance_to_plain(prov))
    pgtype = self.datatype_to_pgtype[specs.name_to_type[dtname]]
    # avoid [0] dims -- 0 as a dim means any size, not 0 size
    dimstrs = [str(dim) if dim else '' for dim in dims]
    arraydims = ''.join(['[' + dimstr + ']' for dimstr in dimstrs])
    return ['CREATE DOMAIN ' +
        identifier +
        ' AS ' +
        pgtype +
        arraydims +
        '; -- see: ' +
        comment]

  def column_line_parts(self, column_spec, temp=False):
    """return a (comment_line, provenance_comment) pair."""
    name, (datatype, nullspec, defaultspec), prov = column_spec
    name = self.sql_identifier(name)
    comment = repr(self.ingest_obj.provenance_to_plain(prov))
    parts = [name, self.datatype_to_pgtype[datatype]]
    # make pgtype INTEGER if temp table and pgtype is SERIAL
    if temp and parts[1] == 'SERIAL':
      parts[1] = 'INTEGER'
    # add not null and default modifiers ('SERIAL' is already not null)
    if not nullspec and parts[1] != 'SERIAL':
      parts.append('NOT NULL')
    elif defaultspec:
      parts.append('DEFAULT TRUE')
    return name, ' '.join(parts), comment

  def table_decl(self, table, temp=False):
    """return a CREATE [TEMP] TABLE stmt as a list of lines"""
    column_specs = specs.column_spec_iter(self.schema, table)
    # each triplet is a column, a column line and a provenance comment
    part_triplets = [self.column_line_parts(spec, temp) for spec in column_specs]
    # zip(*[(a,b,c),...]) equals unzip, i.e., returns ([a,...], [b,...], [c,...])
    columns, column_lines, comments = zip(*part_triplets)
    # add indent
    column_lines = [self.indent + column for column in column_lines]
    # ',x'.join(l).split('x') for isinstance(l, list) is a cool trick.
    # it lets commas be separators, not terminators.
    # assumption: 'x' is not in any column line. an example 'x': '\n'.
    column_lines = ',\n'.join(column_lines).split('\n')
    # we end by creating a list of lines
    lines = list()
    cmd = 'CREATE TEMP TABLE ' if temp else 'CREATE TABLE '
    lines.append(cmd + self.sql_identifier(table) + ' (')
    lines.extend(column_lines)
    lines.append(');')
    if not temp:
      # add comment stmts
      start = 'COMMENT ON COLUMN '
      for column, comment in zip(columns, comments):
        # double up single quotes, and wrap comment in single quotes
        comment = "'see " + comment.replace("'","''") + "'"
        table_column = '.'.join([table, column])
        lines.append(start + table_column + ' IS ' + comment + ';')
    return lines

  def constraints_decl(self, table):
    """declare primary, foreign, and unique key constraints for a table."""
    id_prefix = {'pks':'pk', 'fks':'fk', 'uniqs':'uk'}
    kind = {'pks':'PRIMARY KEY', 'fks':'FOREIGN KEY', 'uniqs':'UNIQUE'}
    # collect declarations and comments separately
    decls = list()
    comments = list()
    delete_option = 'ON DELETE CASCADE'
    for file in ['pks', 'fks', 'uniqs']:
      if table in self.schema[file]:
        id_start = id_prefix[file]
        clause_start = self.indent + 'ADD CONSTRAINT '
        for i, [prov, args] in enumerate(self.schema[file][table]):
          # constraint line
          constraint_id = '_'.join([table, id_start, str(i+1)])
          line = clause_start + constraint_id + ' ' + kind[file] + ' ('
          if file == 'pks':
            line += self.sql_identifier(args[0]) + ')'
          elif file == 'fks':
            column, reftable, refcolumn = args
            column = self.sql_identifier(column)
            refcolumn = self.sql_identifier(refcolumn)
            line += column + ') REFERENCES ' + reftable + ' (' + refcolumn + ')'
            line += ' ' + delete_option
          else:
            columns = [self.sql_identifier(column) for column in args]
            line += ', '.join(columns) + ')'
          decls.append(line)
          comment = repr(self.ingest_obj.provenance_to_plain(prov))
          comments.append((constraint_id, comment))
    # join decls
    decls = ',\n'.join(decls).split('\n')
    # generate ALTER TABLE stmt
    lines = list()
    lines.append('ALTER TABLE ' + table)
    lines.extend(decls)
    lines.append(';')
    # generate COMMENT ON stmts
    stmt_start = 'COMMENT ON CONSTRAINT '
    for constraint_id, comment in comments:
      # double up single quotes, and wrap comment in single quotes
      comment = "'see " + comment.replace("'","''") + "'"
      stmt = stmt_start + constraint_id + ' ON ' + table + ' IS ' + comment + ';'
      lines.append(stmt)
    return lines

  def enum_decls(self):
    enums = specs.enum_types_used(self.schema)
    return [self.enum_type_decl(name) for name in enums]

  def domain_decls(self):
    domains = specs.domain_types_used(self.schema)
    return [self.array_domain_decl(name) for name in domains]

  def table_order(self):
    return toposort_flatten(specs.table_dependencies(self.schema))

  def table_decls(self, temp=False):
    return [self.table_decl(name, temp) for name in self.table_order()]

  def constraints_decls(self):
    return [self.constraints_decl(name) for name in self.table_order()]
