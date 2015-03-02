# postgresql-smoketest
CF app to test database connectivity.

## Usage

This sinatra app executes `SELECT 'ok'` for every `GET /` request.
It assumes that the postgresql service instance is bound to this app, and has the following details:
* username: Database username.
* password: Password for the user `username`.
* db_name: Name of the database.
* port: Port on which postgresql is running.
