#!/bin/bash
set -e

# PGPASSWORD="$DB_PASS" psql -v ON_ERROR_STOP=1 --username "$DB_USER" --dbname "$DB_CKAN_NAME" <<-EOSQL
#     -- Author
#     ALTER TABLE public.package
#     ALTER COLUMN author TYPE JSONB
#     USING author::JSONB;

#     -- Maintainer
#     -- Prep for future when simple subfield available
#     ALTER TABLE public.package
#     ALTER COLUMN maintainer TYPE JSONB
#     USING maintainer::JSONB;

#     -- Package extras (date)
#     -- + prep for future when simple subfield available
#     -- (funding, publication)
#     ALTER TABLE public.package_extra 
#     ALTER COLUMN value TYPE JSONB
#     USING to_jsonb(value::text);

#     UPDATE public.package_extra
#     SET value = (value #>> '{}')::jsonb
#     WHERE key IN ('date', 'spatial', 'publication', 'funding');

#     -- Drop extras field key=subtitle (redundant)
#     DELETE FROM public.package_extra WHERE key = 'subtitle';

#     -- Resources
#     -- Prep for future when simple subfield available
#     -- (resource_size, restricted)
#     ALTER TABLE public.resource
#     ALTER COLUMN extras TYPE JSONB
#     USING to_jsonb(extras::text);

#     UPDATE public.resource
#     SET extras = (extras #>> '{}')::jsonb;
# EOSQL
