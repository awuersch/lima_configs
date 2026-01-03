from pgsql import Pgsql
pgsql_obj = Pgsql('../schema')
def lines_to_string(lines):
  return '\n'.join(lines)
def show_decl(lines):
  print(lines_to_string(lines))
def show_decls(decls):
  strings = [lines_to_string(lines) for lines in decls]
  print('\n\n'.join(strings))
def show_table_decl(table, temp=False):
  show_decl(pgsql_obj.table_decl(table, temp))
def show_table_decls(temp=False):
  show_decls(pgsql_obj.table_decls(temp))
def show_enum_decl(name):
  show_decl(pgsql_obj.enum_type_decl(name))
def show_enum_decls():
  show_decls(pgsql_obj.enum_decls())
def show_domain_decl(name):
  show_decl(pgsql_obj.array_domain_decl(name))
def show_domain_decls():
  show_decls(pgsql_obj.domain_decls())
def show_constraints_decl(table):
  show_decl(pgsql_obj.constraints_decl(table))
def show_constraints_decls():
  show_decls(pgsql_obj.constraints_decls())

# show_table_decl('games')
# show_constraints_decl('games')
# show_table_decl('statsside')
# show_constraints_decl('statsside')
show_enum_decls()
show_domain_decls()
show_table_decl('mets')
show_table_decls()
show_constraints_decl('mets')
show_constraints_decls()
# table_order = pgsql_obj.table_order()
# print(table_order)
