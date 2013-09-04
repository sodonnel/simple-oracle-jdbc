require 'helper'

class SqlTest < Test::Unit::TestCase

  include TestHelper

  def setup
    @interface = @@interface
    @sql = SimpleOracleJDBC::Sql.new(@interface.connection)
  end

  def teardown
    @sql.close
  end

  def test_class_method_prepare_returns_correct_object
    sql_obj = SimpleOracleJDBC::Sql.prepare(@interface.connection, 'select * from dual')
    assert(sql_obj.is_a? SimpleOracleJDBC::Sql)
    results = sql_obj.execute.all_array
    assert_equal(results.length, 1)
  end

  def test_class_method_execute_returns_correct_object
    sql_obj = SimpleOracleJDBC::Sql.execute(@interface.connection, 'select * from dual')
    assert(sql_obj.is_a? SimpleOracleJDBC::Sql)
  end

  def test_class_method_execute_allows_binds_to_be_set
    sql_obj = SimpleOracleJDBC::Sql.execute(@interface.connection,
                                            'select * from dual where 1 = ? and 2 = ?',
                                            1, 2)
    results = sql_obj.all_array
    assert_equal(results.length, 1)
  end

  def test_prepare_method_available_and_returns_self
    prepared = @sql.prepare('select * from dual')
    assert_equal(prepared, @sql)
  end

  def test_execute_method_avaliable_and_returns_self
    sql_obj = SimpleOracleJDBC::Sql.prepare(@interface.connection, 'select * from dual')
    executed = sql_obj.execute
    assert_equal(executed, sql_obj)
  end

  def test_execute_method_accepts_binds_correctly_and_returns_self
    sql_obj = SimpleOracleJDBC::Sql.prepare(@interface.connection,
                                            "select * from dual where 1 = ? and 'a' = ? and 1.234 = ?")
    #"
    executed = sql_obj.execute(1, 'a', 1.234)
    assert_equal(executed, sql_obj)
    results = sql_obj.all_array
    assert_equal(results.length, 1)
    assert_equal(results[0][0], 'X')
  end

  def test_close_does_not_error_when_no_statement
    assert_nothing_raised do
      @sql.close
    end
  end

  def test_close_does_not_error_when_statement_exists
    sql_obj = SimpleOracleJDBC::Sql.prepare(@interface.connection, 'select * from dual')
    assert_nothing_raised do
      sql_obj.close
    end
  end

end
