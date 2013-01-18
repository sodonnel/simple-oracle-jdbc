require 'java'
require 'date'

module SimpleOracleJDBC
  java_import 'oracle.jdbc.OracleDriver'
  java_import 'oracle.jdbc.OracleConnectionWrapper'
  java_import 'oracle.sql.TIMESTAMP'
  java_import 'oracle.sql.NUMBER'
  java_import 'oracle.jdbc.OracleTypes'
  java_import 'java.sql.DriverManager'
  java_import 'java.sql.SQLException'
end

require 'simple_oracle_jdbc/bindings'
require 'simple_oracle_jdbc/result_set'
#require 'interface'
require 'simple_oracle_jdbc/sql'
require 'simple_oracle_jdbc/interface'
require 'simple_oracle_jdbc/db_call'
