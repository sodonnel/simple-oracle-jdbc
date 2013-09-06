require 'helper'

class OraRecordTest < Test::Unit::TestCase

  include TestHelper

  def setup
    @interface = @@interface
    @sql = SimpleOracleJDBC::Sql.new(@interface.connection)
    @call = @interface.prepare_proc("begin
                                      :out_record := test_record(:i_record);
                                    end;")
  end

  def teardown
    @sql.close
  end

  def test_execption_raised_when_not_enough_values_for_record
    record = ["hello"]
    assert_raises RuntimeError do
      @call.execute([SimpleOracleJDBC::OraRecord, SimpleOracleJDBC::OraRecord.new('t_record', nil), :out],
                   SimpleOracleJDBC::OraRecord.new('t_record', record))
    end
  end

  def test_oracle_record_can_be_bound_and_retrieved
    record = ["The String", 123, 456.789, 'THE CHAR', Time.gm(2013,11,23), Time.gm(2013,12,23,12,24,36), 'ED12ED12']
    @call.execute([SimpleOracleJDBC::OraRecord, SimpleOracleJDBC::OraRecord.new('t_record', nil), :out],
                 SimpleOracleJDBC::OraRecord.new('t_record', record))
    return_array = @call[1]
    assert_equal(record[0], return_array[0])
    assert_equal(record[1], return_array[1])
    assert_equal(record[2], return_array[2])
    assert_equal(record[3], return_array[3])
    assert_equal(record[4], return_array[4])
    assert_equal(record[5], return_array[5])
    assert_equal(record[6], return_array[6])
  end

  def test_oracle_record_can_be_bound_and_retrieved_will_all_null_values
    record = [nil, nil, nil, nil, nil, nil, nil]
    @call.execute([SimpleOracleJDBC::OraRecord, SimpleOracleJDBC::OraRecord.new('t_record', nil), :out],
                 SimpleOracleJDBC::OraRecord.new('t_record', record))
    return_array = @call[1]
    assert_equal(record[0], return_array[0])
    assert_equal(record[1], return_array[1])
    assert_equal(record[2], return_array[2])
    assert_equal(record[3], return_array[3])
    assert_equal(record[4], return_array[4])
    assert_equal(record[5], return_array[5])
    assert_equal(record[6], return_array[6])
  end

end
