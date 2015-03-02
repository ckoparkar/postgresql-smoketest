require 'sinatra/base'
require 'json'
require 'pg'

class PostgresqlSmoketest < Sinatra::Base
  get '/' do
    connection.exec("SELECT 'ok'").values.first.first
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
