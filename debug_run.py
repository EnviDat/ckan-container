"""Required to run CKAN as subprocess of debugpy."""

import re
import sys
from ckan.cli.cli import ckan

sys.argv[0] = re.sub(r"(-script\.pyw|\.exe)?$", "", sys.argv[0])
ckan()
