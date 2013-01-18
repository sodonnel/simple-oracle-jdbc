require 'helper'

class ResultSetTest < Test::Unit::TestCase

  include TestHelper

  def setup
    @@interface ||= SimpleOracleJDBC::Interface.create('sodonnel',
                                                       'sodonnel',
                                                       'local11gr2.world',
                                                       'localhost',
                                                       '1521'
                                                       )
    @interface = @@interface


    @sql = SimpleOracleJDBC::Sql.execute(@interface.connection,
                 "select 'a' a_val,
                         1   b_val
                  from dual
                  union all
                  select 'aa' a_val,
                          2   b_val
                  from dual")
  end

  def teardown
    @sql.close
  end


  def test_each_array_returns_array_per_row
    rows = 0
    @sql.each_array do |r|
      assert(r.is_a? Array)
      rows += 1
    end
    assert_equal(2, rows)
  end

  def test_next_array_returns_a_row_per_call
    row = @sql.next_array
    assert_equal(row[0], 'a')
    assert_equal(row[1], 1)
    row = @sql.next_array
    assert_equal(row[0], 'aa')
    assert_equal(row[1], 2)
    row = @sql.next_array
    assert_nil(row)
    # After getting a nil row, it indicates the end of the result set
    # another fetch will raise an exception as the result set will have
    # been closed
    assert_raises SimpleOracleJDBC::NoResultSet do
      row = @sql.next_array
    end
  end

  def test_all_array_returns_all_rows_as_array_or_arrays
    rows = @sql.all_array
    assert_equal(rows.length, 2)
    assert_equal(rows[0][0], 'a')
    assert_equal(rows[0][1], 1)
    assert_equal(rows[1][0], 'aa')
    assert_equal(rows[1][1], 2)
    # A second call to all_array will error
    assert_raises SimpleOracleJDBC::NoResultSet do
      row = @sql.all_array
    end
  end

  def test_each_hash_returns_hash_per_row
    rows = 0
    @sql.each_hash do |r|
      assert(r.is_a? Hash)
      assert(r.has_key? 'A_VAL')
      assert(r.has_key? 'B_VAL')
      rows += 1
    end
    assert_equal(2, rows)
  end

  def test_next_hash_returns_a_hash_per_call
    row = @sql.next_hash
    assert_equal(row['A_VAL'], 'a')
    assert_equal(row['B_VAL'], 1)
    row = @sql.next_hash
    assert_equal(row['A_VAL'], 'aa')
    assert_equal(row['B_VAL'], 2)
    row = @sql.next_hash
    assert_nil(row)
    # After getting a nil row, it indicates the end of the result set
    # another fetch will raise an exception as the result set will have
    # been closed
    assert_raises SimpleOracleJDBC::NoResultSet do
      row = @sql.next_hash
    end
  end

  def test_all_hash_returns_all_rows_as_array_of_hashes
    rows = @sql.all_hash
    assert_equal(rows.length, 2)
    assert_equal(rows[0]['A_VAL'], 'a')
    assert_equal(rows[0]['B_VAL'], 1)
    assert_equal(rows[1]['A_VAL'], 'aa')
    assert_equal(rows[1]['B_VAL'], 2)
    # A second call to all_hash will error
    assert_raises SimpleOracleJDBC::NoResultSet do
      row = @sql.all_hash
    end
  end

  def test_close_result_set
    assert_nothing_raised do
      @sql.close_result_set
    end
  end

  def test_all_retrieves_fail_when_no_or_closed_result_set
    calls = [:all_array, :each_array, :next_array, :all_hash, :each_hash, :next_hash]
    @sql.close_result_set
    calls.each do |c|
      assert_raises SimpleOracleJDBC::NoResultSet do
        @sql.send(c)
      end
    end
  end

end
