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
    #      :refcursor => OracleTypes::CURSOR,
    #      :raw       => OracleTypes::RAW
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

# PLSQL Arrays

Passing arrays to and from PLSQL objects is somewhat painful. To do this, you need to create type objects on the database, eg:

    create or replace type t_varchar_tab is table of varchar2(100);
    /

Then you can define PLSQL functions to have input or output parameters of that type, eg:

    create or replace function test_array_varchar(i_array t_varchar2_tab)
      return t_varchar2_tab
    is
      v_return_value t_varchar2_tab;
    begin
      v_return_value := t_varchar2_tab();
      for i in 1..i_array.count loop
        v_return_value.extend(1);
        v_return_value(v_return_value.count) := i_array(i);
      end loop;
      return v_return_value;
    end;
    /

Using the type and function defined above, you can pass an array to the function and receive the result using a similar interface as normal values:

    call = conn.prepare_proc("begin
                                :out_array := test_array_varchar(:i_array);
                              end;")
    call.execute([SimpleOracleJDBC::OraArray, SimpleOracleJDBC::OraArray.new('t_varchar2_tab', nil), :out],
                 SimpleOracleJDBC::OraArray.new('t_varchar2_tab', ['abc', 'def', nil]))
    return_array = call[1]
    return_array.each do |v|
      puts "The value is: #{v}"
    end

    # The value is: abc
    # The value is: def
    # The value is:

There are a few important differences in the syntax for array calls.

To pass an array in, you must create a SimpleOracleJDBC::OraArray object. This takes 2 parameters:

1. The name of the type on the Oracle database
2. A Ruby array of values to pass to Oracle.

Right now, an array of Integers, Floats, String, Dates or Times is supported. Nil values are allowed (as shown in the example above).

To receive an array of values, again use the SimpleOracleJDBC::OraArray class. The syntax is similar to receiving any output variable from a stored procedure (ie the 3 element array syntax), except the 2nd element in the array is no longer nil. It is important to create an instance of the OraArray object using the name of the Oracle Type, as this is required to retrieve the results from the PLSQL call.

For in out parameters, simply use the 3 element array syntax as with out parameters, only pass a Ruby array as the second parameter.

The array feature has been tested with Oracle arrays of char, varchar2, integer, number, date, timestamp and raw.

# PLSQL Record Types

Using a similar interface as for PLSQL Arrays, it is possible to bind PLSQL Record types to a stored procedure. A PLSQL record type is define on the database using something like the following:

    create or replace type t_record as object (
      p_varchar varchar2(10),
      p_integer integer,
      p_number  number,
      p_char    char(10),
      p_date    date,
      p_timestamp timestamp,
      p_raw     raw(10)
    );
    /
    
    create or replace function test_record(i_record t_record)
      return t_record
    is
    begin
      return i_record;
    end;
    /

Using the type and function above, it is possible to pass a Ruby Array of values for the record and receive a Ruby Array as a response:

    call = conn.prepare_proc("begin
                               :out_array := test_record(:i_array);
                              end;")
    record = ["The String", 123, 456.789, 'THE CHAR', Time.gm(2013,11,23), Time.gm(2013,12,23,12,24,36), 'ED12ED12']
    call.execute([SimpleOracleJDBC::OraRecord, SimpleOracleJDBC::OraRecord.new('t_record', nil), :out],
                  SimpleOracleJDBC::OraRecord.new('t_record', record))
    return_array = call[1]
    return_array.each do |v|
      puts "The value is: #{v}"
    end
    
    # The value is: The String
    # The value is: 123.0
    # The value is: 456.789
    # The value is: THE CHAR
    # The value is: 2013-11-23 00:00:00 +0000
    # The value is: 2013-12-23 12:24:36 +0000
    # The value is: ED12ED12

There are a few important differences in the syntax for record calls.

To pass a record in, you must create a SimpleOracleJDBC::OraRecord object. This takes 2 parameters:

1. The name of the type on the Oracle database
2. A Ruby array of values to pass to Oracle.

The array of Ruby values must contain the same number of fields in the record. To set a field in the record to null pass nil inside the array.

To receive a record from a procedure call, again use the SimpleOracleJDBC::OraRecord class. The syntax is similar to receiving any output variable from a stored procedure (ie the 3 element array syntax), except the 2nd element in the array is no longer nil. It is important to create an instance of the OraRecord object using the name of the Oracle Type, as this is required to retrieve the results from the PLSQL call.

For in out parameters, simply use the 3 element array syntax as with out parameters, only pass a Ruby array as the second parameter.

# Arrays of PLSQL Records

If you define a PLSQL array as table of a record type, then you have an array of PLSQL records. For example, building on the record type created above:

    create or replace type t_record_tab as table of t_record;
    /
    
    create or replace function test_array_of_records(i_array t_record_tab)
      return t_record_tab
    is
      v_return_value t_record_tab;
    begin
      v_return_value := t_record_tab();
      for i in 1..i_array.count loop
        v_return_value.extend(1);
        v_return_value(v_return_value.count) := i_array(i);
      end loop;
      return v_return_value;
    end;
    /

Binding an array like this to a stored procedure works just like binding an array of values. The only difference is that each value passed in the input array, must also be an array. Each of those arrays are then converted into the internal Oracle format using the OraRecord class. For example:

    call = conn.prepare_proc("begin
                               :out_array := test_array_of_records(:i_array);
                              end;")
    record = ["The String", 123, 456.789, 'THE CHAR', Time.gm(2013,11,23), Time.gm(2013,12,23,12,24,36), 'ED12ED12']
    call.execute([SimpleOracleJDBC::OraArray, SimpleOracleJDBC::OraArray.new('t_record_tab', nil), :out],
               # ! Note how the record is an array inside of an array
                  SimpleOracleJDBC::OraArray.new('t_record_tab', [record]))
    return_array = call[1]
    return_array.each do |v|
      # Each return element in the array is an array
      puts "The value is: #{v[0]}"
    end
    
    # The value is: The String


# What About Nested Types?

A nested type is a type that has another type as one of its attributes. Right now they are not supported.

# SQL Arrays

Similar to PLSQL arrays, it is possible to bind an array of values to an SQL call:

        sql = @interface.execute_sql("select * from table(:b_tab)", 
                                     SimpleOracleJDBC::OraArray.new('t_varchar2_tab', ['abc', 'def']))

Again, instead of passing a simple Ruby type, you need to pass an instance of OraArray as the bind variable.

This also works with PLSQL Arrays of Records, eg:

    sql = @interface.execute_sql("select * from table(:b_tab)",
                                 SimpleOracleJDBC::OraArray.new('t_record_tab', [
                                                                  ["S1", nil, nil, nil, nil, nil, nil],
                                                                  ["S2", nil, nil, nil, nil, nil, nil]                                                                                           ]))


More complex types are not yet supported.


# TODO (AKA missing features)

Bindable types that are not yet supported:

 * passing a ref_cursor into a proc
 * binding a CLOB to a procedure

Types that cannot be retrieved from an SQL result set

  * CLOB - is returned as a string so long as it is under 4000 characters
  * Cursor
  * Long
  * nvarchar etc
