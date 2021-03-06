require 'helper'

class OraArrayTest < Test::Unit::TestCase

  include TestHelper

  def setup
    @interface = @@interface
    @sql = SimpleOracleJDBC::Sql.new(@interface.connection)
  end

  def teardown
    @sql.close
  end

  def test_oracle_varchar_array_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                      :out_value := test_array_varchar(:i_array);
                                    end;")
    call.execute([SimpleOracleJDBC::OraArray, SimpleOracleJDBC::OraArray.new('t_varchar2_tab', nil), :out],
                 SimpleOracleJDBC::OraArray.new('t_varchar2_tab', ['abc', 'def', nil]))
    return_array = call[1]
    assert_equal('abc', return_array[0])
    assert_equal('def', return_array[1])
    assert_equal(nil, return_array[2])
  end

  def test_nil_varchar_array_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                      :out_value := test_array_varchar(:i_array);
                                    end;")
    call.execute([SimpleOracleJDBC::OraArray, SimpleOracleJDBC::OraArray.new('t_varchar2_tab', nil), :out],
                 SimpleOracleJDBC::OraArray.new('t_varchar2_tab', []))
    return_array = call[1]
    assert_equal(0, return_array.length)
  end

  def test_oracle_char_array_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                      :out_value := test_array_char(:i_array);
                                    end;")
    call.execute([SimpleOracleJDBC::OraArray, SimpleOracleJDBC::OraArray.new('t_char_tab', nil), :out],
                 SimpleOracleJDBC::OraArray.new('t_char_tab', ['abc', 'def', nil]))
    return_array = call[1]
    # chars are right padded. In this case to 100 characters
    assert_match(/abc\s+/, return_array[0])
    assert_match(/def\s+/, return_array[1])
    assert_equal(100, return_array[0].length)
    assert_equal(nil, return_array[2])
  end

  def test_nil_char_array_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                      :out_value := test_array_char(:i_array);
                                    end;")
    call.execute([SimpleOracleJDBC::OraArray, SimpleOracleJDBC::OraArray.new('t_char_tab', nil), :out],
                 SimpleOracleJDBC::OraArray.new('t_char_tab', []))
    return_array = call[1]
    assert_equal(0, return_array.length)
  end


  def test_nil_varchar_array_can_be_bound_and_retrieved_when_passed_as_nil
    call = @interface.prepare_proc("begin
                                      :out_value := test_array_varchar(:i_array);
                                    end;")
    call.execute([SimpleOracleJDBC::OraArray, SimpleOracleJDBC::OraArray.new('t_varchar2_tab', nil), :out],
                 SimpleOracleJDBC::OraArray.new('t_varchar2_tab', nil))
    return_array = call[1]
    assert_equal(0, return_array.length)
  end

  def test_oracle_integer_array_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                      :out_value := test_array_integer(:i_array);
                                    end;")
    call.execute([SimpleOracleJDBC::OraArray, SimpleOracleJDBC::OraArray.new('t_integer_tab', nil), :out],
                 SimpleOracleJDBC::OraArray.new('t_integer_tab', [9, 10, nil]))
    return_array = call[1]
    assert_equal(9, return_array[0])
    assert_equal(10, return_array[1])
    assert_equal(nil, return_array[2])
  end

  def test_nil_order_integer_array_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                      :out_value := test_array_integer(:i_array);
                                    end;")
    call.execute([SimpleOracleJDBC::OraArray, SimpleOracleJDBC::OraArray.new('t_integer_tab', nil), :out],
                 SimpleOracleJDBC::OraArray.new('t_integer_tab', []))
    return_array = call[1]
    assert_equal(0, return_array.length)
  end

  def test_oracle_number_array_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                      :out_value := test_array_number(:i_array);
                                    end;")
    call.execute([SimpleOracleJDBC::OraArray, SimpleOracleJDBC::OraArray.new('t_number_tab', nil), :out],
                 SimpleOracleJDBC::OraArray.new('t_number_tab', [9.123456, 10.123456, nil]))
    return_array = call[1]
    assert_equal(9.123456, return_array[0])
    assert_equal(10.123456, return_array[1])
    assert_equal(nil, return_array[2])
  end

  def test_nil_oracle_number_array_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                      :out_value := test_array_number(:i_array);
                                    end;")
    call.execute([SimpleOracleJDBC::OraArray, SimpleOracleJDBC::OraArray.new('t_number_tab', nil), :out],
                 SimpleOracleJDBC::OraArray.new('t_number_tab', []))
    return_array = call[1]
    assert_equal(0, return_array.length)
  end


  def test_oracle_date_array_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                      :out_value := test_array_date(:i_array);
                                    end;")
    date_array = [Time.gm(2013,1,1,12,31), Time.gm(2014,1,1,12,31), nil]
    call.execute([SimpleOracleJDBC::OraArray, SimpleOracleJDBC::OraArray.new('t_date_tab', nil), :out],
                 SimpleOracleJDBC::OraArray.new('t_date_tab', date_array))
    return_array = call[1]
    assert_equal(date_array[0], return_array[0])
    assert_equal(date_array[1], return_array[1])
    assert_equal(nil, return_array[2])
  end

  def test_nil_oracle_date_array_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                      :out_value := test_array_date(:i_array);
                                    end;")
    date_array = []
    call.execute([SimpleOracleJDBC::OraArray, SimpleOracleJDBC::OraArray.new('t_date_tab', nil), :out],
                 SimpleOracleJDBC::OraArray.new('t_date_tab', date_array))
    return_array = call[1]
    assert_equal(0, return_array.length)
  end

  def test_oracle_timestamp_array_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                      :out_value := test_array_timestamp(:i_array);
                                    end;")
    date_array = [Time.gm(2013,1,1,12,31), Time.gm(2014,1,1,12,31), nil]
    call.execute([SimpleOracleJDBC::OraArray, SimpleOracleJDBC::OraArray.new('t_timestamp_tab', nil), :out],
                 SimpleOracleJDBC::OraArray.new('t_timestamp_tab', date_array))
    return_array = call[1]
    assert_equal(date_array[0], return_array[0])
    assert_equal(date_array[1], return_array[1])
    assert_equal(nil, return_array[2])
  end

  def test_nil_oracle_timestamp_array_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                      :out_value := test_array_timestamp(:i_array);
                                    end;")
    date_array = []
    call.execute([SimpleOracleJDBC::OraArray, SimpleOracleJDBC::OraArray.new('t_timestamp_tab', nil), :out],
                 SimpleOracleJDBC::OraArray.new('t_timestamp_tab', date_array))
    return_array = call[1]
    assert_equal(0, return_array.length)
  end


  def test_oracle_raw_array_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                      :out_value := test_array_raw(:i_array);
                                    end;")

    call.execute([SimpleOracleJDBC::OraArray, SimpleOracleJDBC::OraArray.new('t_raw_tab', nil), :out],
                 SimpleOracleJDBC::OraArray.new('t_raw_tab', ['ADEADEADE', '3E3E3E', nil]))
    return_array = call[1]
    assert_equal('0ADEADEADE', return_array[0]) # uneven number of bytes left padded with zero
    assert_equal('3E3E3E', return_array[1])
    assert_equal(nil, return_array[2])
  end

  def test_nil_oracle_raw_array_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                      :out_value := test_array_raw(:i_array);
                                    end;")
    date_array = []
    call.execute([SimpleOracleJDBC::OraArray, SimpleOracleJDBC::OraArray.new('t_raw_tab', nil), :out],
                 SimpleOracleJDBC::OraArray.new('t_raw_tab', date_array))
    return_array = call[1]
    assert_equal(0, return_array.length)
  end

  def test_ora_array_object_can_be_reused_with_different_values
    call = @interface.prepare_proc("begin
                                      :out_value := test_array_raw(:i_array);
                                    end;")
    data_array = ['DEDEDE', 'ABABAB']
    input_array_obj =  SimpleOracleJDBC::OraArray.new('t_raw_tab', data_array)
    output_array_obj = SimpleOracleJDBC::OraArray.new('t_raw_tab', nil)
    call.execute([SimpleOracleJDBC::OraArray, output_array_obj, :out], input_array_obj)
    return_array = call[1]
    assert_equal(2, return_array.length)

    input_array_obj.values= ["121212", "AADDAADD", "01"]
    call.execute([SimpleOracleJDBC::OraArray, output_array_obj, :out], input_array_obj)
    return_array = call[1]
    assert_equal(3, return_array.length)
  end

  def test_exception_raised_if_values_passed_is_not_array
    assert_raises RuntimeError do
      input_array_obj =  SimpleOracleJDBC::OraArray.new('t_raw_tab', 'string')
    end
  end

  def test_ora_array_of_records_can_be_bound_and_retrieved
     call = @interface.prepare_proc("begin
                                      :out_value := test_array_of_records(:i_array);
                                    end;")
    record = ["The String", 123, 456.789, 'THE CHAR', Time.gm(2013,11,23), Time.gm(2013,12,23,12,24,36), 'ED12ED12']
    record2 = record.dup
    record2[0] = "String2"

    call.execute([SimpleOracleJDBC::OraArray, SimpleOracleJDBC::OraArray.new('t_record_tab', nil), :out],
                 SimpleOracleJDBC::OraArray.new('t_record_tab', [ record, record2 ]))
    return_array = call[1]
    assert_equal(2, return_array.length)
    assert_equal("The String", return_array.first[0])
    assert_equal(123, return_array.first[1])
    assert_equal(456.789, return_array.first[2])

    assert_equal("String2", return_array[1][0])
  end

  def test_empty_ora_array_of_records_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                      :out_value := test_array_of_records(:i_array);
                                    end;")

    call.execute([SimpleOracleJDBC::OraArray, SimpleOracleJDBC::OraArray.new('t_record_tab', nil), :out],
                 SimpleOracleJDBC::OraArray.new('t_record_tab', nil))
    return_array = call[1]
    assert_equal(0, return_array.length)
  end

  def test_ora_array_of_nil_records_can_be_bound_and_retrieved
    call = @interface.prepare_proc("begin
                                      :out_value := test_array_of_records(:i_array);
                                    end;")
    record = [nil, nil, nil, nil, nil, nil, nil]

    call.execute([SimpleOracleJDBC::OraArray, SimpleOracleJDBC::OraArray.new('t_record_tab', nil), :out],
                 SimpleOracleJDBC::OraArray.new('t_record_tab', [ record ]))
    return_array = call[1]
    assert_equal(1, return_array.length)
    assert_equal(nil, return_array.first[0])
  end

end
