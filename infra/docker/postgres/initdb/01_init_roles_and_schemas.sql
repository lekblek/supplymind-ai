\getenv db_name POSTGRES_DB
\getenv app_user DB_APP_USER
\getenv migrator_user DB_MIGRATOR_USER

\set app_password `cat /run/secrets/db_app_password`
\set migrator_password `cat /run/secrets/db_migrator_password`

CREATE ROLE :"migrator_user"
  WITH LOGIN
  NOSUPERUSER NOCREATEDB NOCREATEROLE
  PASSWORD :'migrator_password';

CREATE ROLE :"app_user"
  WITH LOGIN
  NOSUPERUSER NOCREATEDB NOCREATEROLE
  PASSWORD :'app_password';

REVOKE CONNECT ON DATABASE :"db_name" FROM PUBLIC;

GRANT CONNECT ON DATABASE :"db_name"
  TO :"migrator_user", :"app_user";

GRANT CREATE ON DATABASE :"db_name"
  TO :"migrator_user";

REVOKE ALL PRIVILEGES ON SCHEMA public FROM PUBLIC;

GRANT USAGE, CREATE ON SCHEMA public TO :"migrator_user";

GRANT USAGE ON SCHEMA public TO :"app_user";

CREATE SCHEMA IF NOT EXISTS flyway AUTHORIZATION :"migrator_user";
CREATE SCHEMA IF NOT EXISTS platform AUTHORIZATION :"migrator_user";
CREATE SCHEMA IF NOT EXISTS inventory AUTHORIZATION :"migrator_user";


GRANT USAGE ON SCHEMA platform TO :"app_user";
GRANT USAGE ON SCHEMA inventory TO :"app_user";



ALTER ROLE :"app_user"
  IN DATABASE :"db_name"
  SET search_path = pg_catalog;

ALTER ROLE :"migrator_user"
  IN DATABASE :"db_name"
  SET search_path = pg_catalog;
