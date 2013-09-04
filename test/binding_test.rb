require 'helper'

class BindingTest < Test::Unit::TestCase

  include TestHelper

  def setup
    @interface = @@interface
    @sql = SimpleOracleJDBC::Sql.new(@interface.connection)
  end

  def teardown
    @sql.close
  end

  # The binding module provides a set of methods to bind ruby
  # types to SQL bindable objects (prepared proc calls or SQL statements)
  # All it needs is a bindable object to be passed.
  #
  # For ease of testing, the ::Interface will be used to create the
  # prepared objects.

  def test_dates_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                     :l_date := :i_date;
                                   end;")
    call.execute([Date, nil, :out], Date.new(2012,1,1))
    assert_equal(Date.new(2012,1,1), call[1])
    assert(call[1].is_a? Date)
  end

  def test_null_dates_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                     :l_date := :i_date;
                                   end;")
    call.execute([Date, nil, :out], [Date, nil])
    assert_nil(call[1])
  end


  def test_times_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                     :l_date := :i_date;
                                   end;")
    t = Time.now
    call.execute([Time, nil, :out], t)
    assert_equal(t, call[1])
    assert(call[1].is_a? Time)
  end

  def test_null_times_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                     :l_date := :i_date;
                                   end;")
    call.execute([Time, nil, :out], [Time, nil])
    assert_nil(call[1])
  end

  def test_string_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                     :l_date := :i_date;
                                   end;")
    t = "hello there I am a string"
    call.execute([String, nil, :out], t)
    assert_equal(t, call[1])
    assert(call[1].is_a? String)
  end

  def test_null_string_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                     :l_date := :i_date;
                                   end;")
    call.execute([String, nil, :out], [String, nil])
    assert_nil(call[1])
  end

  def test_integer_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                     :l_date := :i_date;
                                   end;")
    t = 1234
    call.execute([Integer, nil, :out], t)
    assert_equal(t, call[1])
    assert(call[1].is_a? Fixnum)
  end

  def test_null_integer_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                     :l_date := :i_date;
                                   end;")
    call.execute([Integer, nil, :out], [Integer, nil])
    assert_nil(call[1])
  end

  def test_number_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                     :l_date := :i_date;
                                   end;")
    t = 1234.123456789
    call.execute([Float, nil, :out], t)
    assert_equal(t, call[1])
    assert(call[1].is_a? Float)
  end

  def test_null_number_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                     :l_date := :i_date;
                                   end;")
    call.execute([Float, nil, :out], [Float, nil])
    assert_nil(call[1])
  end

  def test_refcursor_can_be_bound_and_retrieved
    call = @interface.prepare_proc("declare
                                      v_refcursor sys_refcursor;
                                    begin
                                      open v_refcursor for
                                      select * from dual;

                                      :ret := v_refcursor;
                                    end;")
    call.execute([:refcursor, nil, :out])
    results = call[1]
    assert(results.is_a? SimpleOracleJDBC::Sql)
    rows = results.all_array
    assert_equal(rows.length, 1)
    assert_equal(rows[0][0], 'X')
  end

  def test_raw_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                     :l_raw := :i_raw;
                                   end;")
    call.execute([:raw, nil, :out], [:raw, "DEDEDEDEFF"])
    assert(call[1].is_a?(String), "Ensure a string is returned")
    assert(call[1], "DEDEDEDEFF")
  end

  def test_null_raw_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                     :l_raw := :i_raw;
                                   end;")
    call.execute([:raw, nil, :out], [:raw, nil])
    assert_nil(call[1])
  end


  def test_unknown_data_type_raises_exeception_when_bound
    call = @interface.prepare_proc("begin
                                     :l_date := :i_date;
                                   end;")
    assert_raises SimpleOracleJDBC::UnknownBindType do
      call.execute([SimpleOracleJDBC::Interface, nil, :out], [Float, nil])
    end
  end

  def test_in_out_parameter_can_be_bound
    call = @interface.prepare_proc("begin
                                     :l_date := :i_date;
                                   end;")
    t = 1234.123456789
    call.execute([Float, nil, :out], [Float, t, :inout])
    assert_equal(t, call[1])
    assert(call[1].is_a? Float)
  end

  ### SQL specific tests.

  def test_date_is_retrieved_as_ruby_time
    sql = @interface.execute_sql("select to_date('20120713 13:23:23', 'YYYYMMDD HH24:MI:SS') from dual")
    results = sql.all_array
    assert_equal(results[0][0], Time.local(2012, 7, 13, 13, 23, 23))
  end

  def test_null_date_is_retrived_as_nil
    sql = @interface.execute_sql("select cast(null as date) from dual")
    results = sql.all_array
    assert_equal(results[0][0], nil)
  end

  def test_timestamp_is_retrieved_as_ruby_time
    sql = @interface.execute_sql("select cast(to_date('20120713 13:23:23', 'YYYYMMDD HH24:MI:SS') as timestamp) from dual")
    results = sql.all_array
    assert_equal(results[0][0], Time.local(2012, 7, 13, 13, 23, 23))
  end

  def test_null_timestamp_is_retrived_as_nil
    sql = @interface.execute_sql("select cast(null as timestamp) from dual")
    results = sql.all_array
    assert_equal(results[0][0], nil)
  end

  def test_integer_is_retrieved_as_ruby_integer
    sql = @interface.execute_sql("select cast(1234567890 as integer) from dual")
    results = sql.all_array
    assert_equal(results[0][0], 1234567890)
  end

  def test_null_integer_is_retrived_as_nil
    sql = @interface.execute_sql("select cast(null as integer) from dual")
    results = sql.all_array
    assert_equal(results[0][0], nil)
  end

  def test_number_is_retrieved_as_ruby_float
    sql = @interface.execute_sql("select cast(1234567890.123456789 as number) from dual")
    results = sql.all_array
    assert_equal(results[0][0], 1234567890.123456789)
  end

  def test_null_number_is_retrived_as_nil
    sql = @interface.execute_sql("select cast(null as number) from dual")
    results = sql.all_array
    assert_equal(results[0][0], nil)
  end

  def test_char_is_retrieved_as_ruby_string
    sql = @interface.execute_sql("select cast('hello there' as char(11)) from dual")
    results = sql.all_array
    assert_equal(results[0][0], "hello there")
  end

  def test_null_char_is_retrieved_as_nil
    sql = @interface.execute_sql("select cast(null as char(10)) from dual")
    results = sql.all_array
    assert_equal(results[0][0], nil)
  end

  def test_varchar_is_retrieved_as_ruby_string
    sql = @interface.execute_sql("select cast('hello there' as varchar2(1000)) from dual")
    results = sql.all_array
    assert_equal(results[0][0], "hello there")
  end

  def test_null_varchar_is_retrieved_as_nil
    sql = @interface.execute_sql("select cast(null as varchar2(10)) from dual")
    results = sql.all_array
    assert_equal(results[0][0], nil)
  end

  def test_raw_is_retrieved_as_ruby_string
    sql = @interface.execute_sql("select cast('DFDFDFDF' as raw(16)) from dual")
    results = sql.all_array
    assert_equal(results[0][0], "DFDFDFDF")
  end

  def test_null_raw_is_retrieved_as_nil
    sql = @interface.execute_sql("select cast(null as raw(16)) from dual")
    results = sql.all_array
    assert_equal(results[0][0], nil)
  end


  def test_unknown_data_type_from_sql_raises_exeception
    sql = @interface.execute_sql("select cast('hello there' as nvarchar2(1000)) from dual")
    assert_raises SimpleOracleJDBC::UnknownSQLType do
      results = sql.all_array
    end
  end



end
