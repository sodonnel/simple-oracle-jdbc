# A Thin Wrapper

The idea behind this gem is that it provides a thin wrapper around a JDBC connection. It provides an interface to quickly execute SQL statements and stored procedures, but leaves the raw JDBC connection available if anything more complicated is required, such as binding array types.

Values can be bound to SQL statements and procedures by simple passing an array of Ruby types into the excecute call, and they are mapped automatically into the correct Java SQL types. The same happens when values are returned from procedures and queries.

# More Than Just Testing

While the gem was created to help with Unit Testing PLSQL code, there is nothing preventing it being used for other quick scripts or prototypes. I haven't looked at performance at all, so if you decided to use it in a production application, test it thoroughly first!

# Requirements

This gem will only work with JRuby as it uses the Java JDBC interface.

The Oracle JDBC drivers (ojdbc6.jar) need to be in the JRuby lib directory.

# Usage

The best way to learn how to use Simple Oracle JDBC is to read through the sample code below, and then checkout the documentation.

    require 'simple_oracle_jdbc'
    
    conn = SimpleOracleJDBC::Interface.create('sodonnell',   # user
                                              'sodonnell',   # password
                                              'tuned',       # service
                                              '192.168.0.1', # host
                                              '1521')        # port
    
    # ... or create with an existing JDBC connection
    # conn = SimpleOracleJDBC.create_with_existing_connection(conn)
    
    # Create a SimpleOracleJDBC::SQL object
    sql = conn.prepare_sql("select 1 c1, 'abc' c2, sysdate c3, 23.56 c4
                                  from dual
                                  where 1 = :b1
                                  and   2 = :b2")
    
    # execute the query against the database, passing any binds as required
    sql.execute(1, 2)
    
    # get the results back as an array of arrays. Note that the resultset
    # and statement will be closed after this call, so the SQL cannot
    # be executed again.
    results = sql.all_array
    puts "The returned row is #{results[0]}"
    
    # > The returned row is [1.0, "abc", 2013-02-12 22:00:23 +0000, 23.56]
    
    # Run the same SQL statement again
    sql = conn.prepare_sql("select 1 c1, 'abc' c2, sysdate c3, 23.56 c4
                                  from dual
                                  where 1 = :b1
                                  and   2 = :b2")
    
    sql.execute(1, 2)
    
    # This time fetch the results as an array of hashes
    results = sql.all_hash
    puts "The returned row is #{results[0]}"
    puts results[0]["C3"].class
    
    # Notice how the column names are the keys of the hash, and the date is converted
    # into a Ruby Time object.
    #
    # > The returned row is {"C1"=>1.0, "C2"=>"abc", "C3"=>2013-02-12 22:03:02 +0000, "C4"=>23.56}
    # > Time
    
    # If you need to iterate over a large result set, then pass a block to the each_array
    # or each_hash method
    sql = conn.prepare_sql("select level rnum, 1 c1, 'abc' c2, sysdate c3, 23.56 c4
                            from dual
                            where 1 = :b1
                            and   2 = :b2
                            connect by level <= 4")
    
    sql.execute(1, 2).each_hash do |row|
      puts row
    end
    
    # > {"RNUM"=>1.0, "C1"=>1.0, "C2"=>"abc", "C3"=>2013-02-12 22:07:14 +0000, "C4"=>23.56}
    # > {"RNUM"=>2.0, "C1"=>1.0, "C2"=>"abc", "C3"=>2013-02-12 22:07:14 +0000, "C4"=>23.56}
    # > {"RNUM"=>3.0, "C1"=>1.0, "C2"=>"abc", "C3"=>2013-02-12 22:07:14 +0000, "C4"=>23.56}
    # > {"RNUM"=>4.0, "C1"=>1.0, "C2"=>"abc", "C3"=>2013-02-12 22:07:14 +0000, "C4"=>23.56}
    
    # Finally you can ask for each row one at a time, with each_array or each_hash
    sql = conn.prepare_sql("select level rnum, 1 c1, 'abc' c2, sysdate c3, 23.56 c4
                            from dual
                            where 1 = :b1
                            and   2 = :b2
                            connect by level <= 4")
    sql.execute(1, 2)
    
    # If you fetch to the end of the result set, then the statement and
    # and result set will be closed. Otherwise, call the close method:
    #
    # sql.close
    while row = sql.next_array do
      puts "The row is #{row}"
    end
    
    # > The row is [1.0, 1.0, "abc", 2013-02-12 22:11:38 +0000, 23.56]
    # > The row is [2.0, 1.0, "abc", 2013-02-12 22:11:38 +0000, 23.56]
    # > The row is [3.0, 1.0, "abc", 2013-02-12 22:11:38 +0000, 23.56]
    # > The row is [4.0, 1.0, "abc", 2013-02-12 22:11:38 +0000, 23.56]
    
    
    # Executing Stored Procedures is easy too, just take care of out and inout parameters.
    #
    # create or replace function test_func(i_var integer default null)
    # return integer
    # is
    # begin
    #   if i_var is not null then
    #     return i_var;
    #   else
    #     return -1;
    #   end if;
    # end;
    # /
    #
    # Execute a function with a returned parameter. Notice how the
    # out/returned parameter is passed as a 3 element array.
    # The first element defines the Ruby type which is mapped into a SQL type as follows:
    #
    #    RUBY_TO_JDBC_TYPES = {
    #      Date       => OracleTypes::DATE,
    #      Time       => OracleTypes::TIMESTAMP,
    #      String     => OracleTypes::VARCHAR,
    #      Fixnum     => OracleTypes::INTEGER,
    #      Integer    => OracleTypes::INTEGER,
    #      Bignum     => OracleTypes::NUMERIC,
    #      Float      => OracleTypes::NUMERIC,
    #      :refcursor => OracleTypes::CURSOR
    #    }
    #
    # The second element is the value, which should be nil for out parameters and can take a
    # value for inout parameters.
    #
    # The third parameter should always be :out
    #
    # Also notice how the value is retrieved using the [] method, which is indexed from 1 not zero.
    # In, out and inout parameters can be accessed using the [] method.
    proc = conn.prepare_proc("begin :return := test_func(); end;")
    proc.execute([String, nil, :out])
    puts "The returned value is #{proc[1]}"
    
    # > The returned value is -1
    
    # To pass parameters into the function, simply pass plain Ruby values:
    proc = conn.prepare_proc("begin :return := test_func(:b1); end;")
    proc.execute([String, nil, :out], 99)
    puts "The returned value is #{proc[1]}"
    proc.close
    
    # > The returned value is 99
    
    # A refcursor is returned from a stored procedure as a SimpleOracleJDBC::SQL object, so it can
    # be accessed in the way as the SQL examples above:
    #
    # create or replace function test_refcursor
    # return sys_refcursor
    # is
    #    v_refc sys_refcursor;
    # begin
    #   open v_refc for
    #   select level rnum, 1 c1, 'abc' c2, sysdate c3, 23.56 c4
    #   from dual
    #   connect by level <= 4;
    #
    #   return v_refc;
    # end;
    # /
    #
    proc = conn.prepare_proc("begin :return := test_refcursor; end;")
    proc.execute([:refcursor, nil, :out])
    sql_object = proc[1]
    sql_object.each_hash do |row|
      puts row
    end
    proc.close
    
    # > {"RNUM"=>1.0, "C1"=>1.0, "C2"=>"abc", "C3"=>2013-02-12 22:32:48 +0000, "C4"=>23.56}
    # > {"RNUM"=>2.0, "C1"=>1.0, "C2"=>"abc", "C3"=>2013-02-12 22:32:48 +0000, "C4"=>23.56}
    # > {"RNUM"=>3.0, "C1"=>1.0, "C2"=>"abc", "C3"=>2013-02-12 22:32:48 +0000, "C4"=>23.56}
    # > {"RNUM"=>4.0, "C1"=>1.0, "C2"=>"abc", "C3"=>2013-02-12 22:32:48 +0000, "C4"=>23.56}


# Datamapping

Basic Ruby types are mapped automatically into the correct types for JDBC interaction, and the JDBC types are mapped back to Ruby types when they are retrieved from the database.

# TODO (AKA missing features)

Bindable types that are not yet supported:

 * passing a ref_cursor into a proc
 * binding a CLOB to a procedure

Types that cannot be retrieved from an SQL result set

  * CLOB
  * Cursor
  * Long
  * nvarchar etc