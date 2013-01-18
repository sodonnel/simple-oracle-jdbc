require 'helper'

class DBCallTest < Test::Unit::TestCase

  include TestHelper

  def setup
    @interface = @@interface
  end

  def teardown
  end

  def test_class_method_prepare_returns_correct_object
    call_obj = SimpleOracleJDBC::DBCall.prepare(@interface.connection, 'begin :out := :in; end;')
    assert(call_obj.is_a? SimpleOracleJDBC::DBCall)
    call_obj.close
  end

  def test_class_method_execute_returns_correct_object
    call_obj = SimpleOracleJDBC::DBCall.execute(@interface.connection,
                                                'begin :out := :in; end;',
                                                [String, nil, :out], 'ABC')
    assert(call_obj.is_a? SimpleOracleJDBC::DBCall)
    assert_equal(call_obj[1], 'ABC')
    call_obj.close
  end

  def test_class_method_execute_works_with_jdbc_type_calls
    call_obj = SimpleOracleJDBC::DBCall.execute(@interface.connection,
                                                '{ call ? := ? }',
                                                [String, nil, :out], 'ABC')
    assert(call_obj.is_a? SimpleOracleJDBC::DBCall)
    assert_equal(call_obj[1], 'ABC')
    call_obj.close
  end

  def test_prepared_call_can_be_executed_and_returns_self
    call_obj = SimpleOracleJDBC::DBCall.prepare(@interface.connection, 'begin :out := :in; end;')
    results = nil
    assert_nothing_raised do
      results = call_obj.execute([String, nil, :out], 'ABC')
    end
    assert_equal(results, call_obj)
    call_obj.close
  end

  def test_accessing_bind_out_of_range_raises_exception
    call_obj = SimpleOracleJDBC::DBCall.execute(@interface.connection,
                                                '{ call ? := ? }',
                                                [String, nil, :out], 'ABC')
    assert_raises SimpleOracleJDBC::BindIndexOutOfRange do
      call_obj[0]
    end
    call_obj.close
  end

  def test_in_binds_can_be_retrieved
    call_obj = SimpleOracleJDBC::DBCall.execute(@interface.connection,
                                                "begin :out := :in||'DEF'; end;",
                                                [String, nil, :out], 'ABC')
    assert_equal(call_obj[2], 'ABC')
    call_obj.close
  end

  def test_out_bind_can_be_retrieved
    call_obj = SimpleOracleJDBC::DBCall.execute(@interface.connection,
                                                "begin :out := :in||'DEF'; end;",
                                                [String, nil, :out], 'ABC')
    assert_equal(call_obj[1], 'ABCDEF')
    call_obj.close
  end

  def test_close_method_closes_statment
    call_obj = SimpleOracleJDBC::DBCall.execute(@interface.connection,
                                                "begin :out := :in||'DEF'; end;",
                                                [String, nil, :out], 'ABC')
    assert_not_nil(call_obj.call)
    call_obj.close
    assert_nil(call_obj.call)
  end

  def test_raw_jdbc_call_object_can_be_retrieved
    call_obj = SimpleOracleJDBC::DBCall.execute(@interface.connection,
                                                "begin :out := :in||'DEF'; end;",
                                                [String, nil, :out], 'ABC')
    assert_not_nil(call_obj.call)
  end


end
