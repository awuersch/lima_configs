from enum import Enum, auto
from ingest import Ingest

class Type(Enum):
  bool = auto()
  int = auto()
  id = auto()
  idx = auto()
  string = auto()
  float = auto()
  date = auto()
  side = auto()
  result = auto()
  owner = auto()
  onmove = auto()
  action = auto()
  skill = auto()
  luck = auto()
  eval = auto()
  met = auto()
  post_crawford = auto()
  score = auto()
  move = auto()
  dice = auto()
  probs = auto()
  prices = auto()
  surrogate = auto()

enum_types = [
  Type.side,
  Type.result,
  Type.owner,
  Type.onmove,
  Type.action,
  Type.skill,
  Type.luck,
  Type.eval]

enum_types_set = frozenset(enum_types)

array_types = [
  Type.met,
  Type.post_crawford,
  Type.score,
  Type.move,
  Type.dice,
  Type.probs,
  Type.prices]

array_types_set = frozenset(array_types)

class Keytype(Enum):
  primary = auto()
  foreign = auto()
  uniq = auto()

class Default(Enum):
  none = auto()
  null = auto()
  true = auto()

dir = '../schema'
schema = Ingest(dir).ingest_dir()

name_to_type = {name:member for name, member in Type.__members__.items()}
name_to_default = {name:member for name, member in Default.__members__.items()}
type_to_name = {member:name for name, member in Type.__members__.items()}
default_to_name = {member:name for name, member in Default.__members__.items()}

def enum_specs_iter(schema):
  """generate enumeration specs for enum datatypes."""
  for name in schema['enums']:
    if name in name_to_type:
      yield name_to_type[name], schema['enums'][name]

def array_specs_iter(schema):
  """generate array dimension specs for array datatypes."""
  for name in schema['dims']:
    if name in name_to_type:
      yield name_to_type[name], schema['dims'][name]

# schema structure is { basename : { table : [(prov, [field, ...]) ...] } }

# a table is either a strong or a weak entity.
#   a strong entity uses a surrogate key as its primary key
#   a weak entity uses a foreign key as its primary key

def column_spec_iter(schema, table):
  """a column spec has a type, a null flag, and a default.
     column specs are ordered."""
  def nonkey_spec(datatype, defaulttype):
    "return (datatype, null?, default?)"
    typespec = name_to_type[datatype]
    nullspec = name_to_default[defaulttype] == Default.null
    defaultspec = name_to_default[defaulttype] == Default.true
    return typespec, nullspec, defaultspec

  keyname_coltype = {'surrs':Type.surrogate, 'fks':Type.id, 'idxs':Type.int}

  #
  # stage one: add primary, parent, and parent index columns
  #
  # semantic constraints active here:
  #   * entities (tables) are strong (having surrogate ids) xor weak.
  #   * weak entities have foreign key ids (primary keys).
  #   * table constraints are irrelevant here.
  #
  # schema must be valid (i.e., honors the above constraints)
  # TODO: write a schema validation function
  #  (or: don't be stupid)
  #
  for name in ['surrs', 'fks', 'idxs']:
    if table in schema[name]:
      for prov, [column, *_] in schema[name][table]:
        keyspec = (keyname_coltype[name], False, False)
        yield column, keyspec, prov
  #
  # stage two: add non-key columns
  #
  # semantic constraints active here:
  #   * columns in key names ('surrs', 'fks', 'idxs') are not in 'cols'
  #
  # schema must be valid (i.e., honors the above constraints)
  # TODO: write a schema validation function
  #  (or: don't be stupid)
  #
  if table in schema['cols']:
    for prov, [column, datatype, default] in schema['cols'][table]:
      yield column, nonkey_spec(datatype, default), prov

def constraint_spec_iter(schema, table):
  """constraints are unordered,
       but we will order constraint ids for the same keytype.
     a constraint has a keytype and a list of arguments."""
  name_to_keytype = {
      'pks':Keytype.primary,
      'fks':Keytype.foreign,
      'uniqs':Keytype.uniq}
  for name in name_to_keytype.keys():
    if table in schema[name]:
      for prov, args in schema[name][table]:
        spec = (name_to_keytype[name], args, prov)
        yield spec

def table_spec_iters(schema, table):
  """generate as a pair of iterators:
     * [((column, type, default), provenance) ...] column specs
     * [((keytype, args), provenance) ...] table constraints"""
  return column_specs(schema, table), constraint_specs(schema, table)

def table_dependencies(schema):
  """return a map from tables to sets of tables they depend on"""
  deps = dict()
  fks = schema['fks']
  for table in fks:
    if table not in deps:
      deps[table] = list()
    deps[table].extend([reftable for _, [_, reftable, _] in fks[table]])
  return {table:set(table_list) for table, table_list in deps.items()}

def types_used(schema, types_set):
  types = list()
  for table in schema['cols']:
    for _, [_, name, _] in schema['cols'][table]:
      datatype = name_to_type[name]
      if datatype in types_set:
        types.append(datatype)
  return frozenset(types)

def enum_types_used(schema):
  return types_used(schema, enum_types_set)

def domain_types_used(schema):
  return types_used(schema, array_types_set)
