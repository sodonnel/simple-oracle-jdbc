# Simple Oracle JDBC

This gem provides a lightweight wrapper around a raw JDBC connection to make interaction between JRuby and Oracle easier. It only wraps commonly used features of JDBC, and makes the raw JDBC connection available to handle less common or more complex tasks.

## Requirements

This gem will only work with JRuby as it uses the Java JDBC interface.

The Oracle JDBC drivers (ojdbc6.jar) need to be in the JRuby lib directory.

## Simple Usage

The intended entry point is the Interface class. Various Interface methods will return Sql or DBCall objects. Note that the Sql and DBCall objects should generally be closed when they are no longer required to free up resources on the database.

    require 'rubygems'
    require 'simple_oracle_jdbc'

    @interface = SimpleOracleJDBC::Interface.create('sodonnel',
                                                    'sodonnel',
                                                    'local11gr2.world',
                                                    'localhost',
                                                    '1521')
    # ... or create with an existing JDBC connection
    # @interface = SimpleOracleJDBC.create_with_existing_connection(conn)

    # Create a SimpleOracleJDBC::SQL object
    sql = @interface.prepare_sql("select * from dual")

    # execute the query against the database
    sql.execute

    # get the results back as an array
    results = sql.all_array
    puts "The returned row is #{results[0][0]}"
    sql.close

    # ... or a hash
    # results = sql.execute.all_hash
    #
    # ... or use a block
    # sql.execute.each_array do |row|
    #   process_the_row
    # end

    # Execute a procedure with an OUT parameter
    proc = @interface.prepare_proc("begin :return := 'abc'; end;")
    proc.execute([String, nil, :out])
    puts "The returned value is #{proc[1]}"
    proc.close

## Datamapping

Basic Ruby types are mapped automatically into the correct types for JDBC interaction, and the JDBC types are mapped back to Ruby types when they are retrieved from the database.

## TODO (AKA missing features)

Bindable types that are not yet supported:
 * passing a ref_cursor into a proc
 * binding a CLOB to a procedure

Types that cannot be retrieved from an SQL result set
  * CLOB
  * Cursor
  * Long
  * nvarchar etc