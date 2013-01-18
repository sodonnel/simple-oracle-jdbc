require 'helper'

class InterfaceTest < Test::Unit::TestCase

  include TestHelper

  def setup
    @interface = SimpleOracleJDBC::Interface.create(DB_USER,
                                                    DB_PASSWORD,
                                                    DB_SERVICE,
                                                    DB_HOST,
                                                    DB_PORT)
  end

  def teardown
    @interface.disconnect
  end

  def test_interface_can_be_created_with_connection_details
    # the interface is created in setup
    assert_not_nil(@interface)
  end

  def test_raw_database_connection_accessible
    connection = @interface.connection
    # should return a JDBC connection object - test to see if it responds
    # to a JDBC method
    assert(connection.respond_to? :prepare_statement)
  end

  def test_disconnect_method_closes_db_connection
    @interface.disconnect
    assert_nil(@interface.connection)
  end

  def test_commit_method_available
    assert_nothing_raised do
      @interface.commit
    end
  end

  def test_rollback_method_available
    assert_nothing_raised do
      @interface.rollback
    end
  end

  def test_prepare_sql_query_returns_sql_object
    sql = @interface.prepare_sql("select * from dual")
    assert(sql.is_a? SimpleOracleJDBC::Sql)
    sql.close
  end

  def test_execute_sql_query_returns_sql_object
    sql = @interface.execute_sql("select * from dual")
    assert(sql.is_a? SimpleOracleJDBC::Sql)
    sql.close
  end

  def test_prepare_call_returns_db_call_object
    call = @interface.prepare_proc("begin
                                     :l_date := :i_date;
                                   end;")
    assert(call.is_a? SimpleOracleJDBC::DBCall)
  end

  def test_execute_call_returns_an_executed_db_call_object
    call = @interface.execute_proc("begin
                                     :l_date := :i_date;
                                   end;", [Time, nil, :out], Time.now)
    assert(call.is_a? SimpleOracleJDBC::DBCall)
  end


end

