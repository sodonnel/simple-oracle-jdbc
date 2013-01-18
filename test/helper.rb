$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'simple_oracle_jdbc'
require 'test/unit'

module TestHelper

  DB_USER     = 'sodonnel'
  DB_PASSWORD = 'sodonnel'
  DB_SERVICE  = 'local11gr2.world'
  DB_HOST     = 'localhost'
  DB_PORT     = '1521'

  @@interface ||= SimpleOracleJDBC::Interface.create(DB_USER,
                                                     DB_PASSWORD,
                                                     DB_SERVICE,
                                                     DB_HOST,
                                                     DB_PORT)
end
