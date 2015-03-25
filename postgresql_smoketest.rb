require 'sinatra/base'
require 'json'
require 'pg'

class PostgresqlSmoketest < Sinatra::Base
  get '/' do
    connection.exec("SELECT 'ok'").values.first.first
  end

  put '/create-database/:db_name' do |db_name|
    connection.exec("CREATE DATABASE #{db_name}")
    connection.exec("REVOKE ALL ON DATABASE #{db_name} FROM public")
  end

  put '/create-user/:username/for/:db_name' do |username, db_name|
    connection.exec("CREATE USER #{username} WITH PASSWORD '#{username}'")
    connection.exec("GRANT ALL PRIVILEGES ON DATABASE #{db_name} TO #{username}")
  end

  get '/select-ok/on/:db_name/as/:username' do |db_name, username|
    conn = PG.connect(host: credentials['hostname'],
                      port: credentials['port'],
                      dbname: db_name,
                      user: username)
    conn.exec("SELECT 'ok'").values.first.first
  end

  delete '/delete-database/:db_name' do |db_name|
    connection.exec("DROP DATABASE #{db_name}")
  end

  delete '/delete-user/:username' do |username|
    connection.exec("DROP OWNED BY #{username} CASCADE")
    connection.exec("DROP ROLE #{username}")
  end

  private

  def credentials
    JSON.parse(ENV['VCAP_SERVICES'])['postgresql-db'].first['credentials']
  end

  def connection
    @conn ||= PG.connect(host: credentials['hostname'],
                        user: credentials['username'],
                        port: credentials['port'],
                        dbname: credentials['db_name'])
  end
end
