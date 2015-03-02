require 'sinatra/base'

class PostgresqlSmoketest < Sinatra::Base
  get '/' do
    "hello world"
  end
end
