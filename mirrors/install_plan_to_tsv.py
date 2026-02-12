import sys
import json
import logging

# convert URL templates in install-plan.json to TSV (tab-separated CSV)

logger = logging.getLogger(__name__)

def main():
  logging.basicConfig(filename='install_plan_to_tsv.log', level=logging.INFO)

  try:
    o = json.load(sys.stdin)
  except Exception as e:
    logger.error('json.load failure:', e)
    exit(1)

  header = ['name', 'source_key', 'url_template']
  sep = '\t'

  print(sep.join(header))

  cxt = []
  k = 'artifacts'
  if k in o:
    for i, artifact in enumerate(o[k]):
      cxt.append(f'artifact {i}')
      k = "name"
      if k in artifact:
        name = artifact[k]
        ks = ["sources", "index_sources", "download_sources"]
        for k in ks:
          if k in artifact:
            source_key = k
            found = False
            for j, source in enumerate(artifact[k]):
              cxt.append(f'source {j}')
              k = 'env'
              if k in source:
                env = source[k]
                if source[k] == 'opensource':
                    cxt.append('env:opensource')
                  found = True
                  k = 'url_template'
                  if k in source:
                    url_template = source[k]
                    line = [name, source_key, url_template]
                    print(sep.join(line))
                  else:
                    logger.error(f'key {k} not in {cxt}')
                  cxt.pop()
              else:
                logger.error(f'key {k} not in {cxt}')
              cxt.pop()
            if not found:
                logger.error(f'key:value "env:opensource" not in {cxt}')
      else:
        logger.error(f'key {k} not in {cxt}')
      cxt.pop()
  else:
    logger.error(f'key {k} not in json object, lineno {sys._getframe(1).f_lineno}')

if __name__ == '__main__':
  main()
