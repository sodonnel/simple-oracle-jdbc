module SimpleOracleJDBC

  class DBCall

    # This class is used to prepare and execute stored procedure calls against
    # the database. The interface is similar to the Sql class.
    #
    # @!attribute call
    #   @return [JDBC Callable Statement] Returns the raw JDBC callable statement
    #

    include Binding

    attr_reader :call


    # Takes a JDBC database connection and a procedure call and returns a
    # SimpleOracleJDBC object after preparing the procedure call. The prepared
    # JDBC callable statement is stored in @call
    def self.prepare(conn, sql)
      call = new(conn, sql)
    end

    # Takes a JDBC database connection, a procedure call and an optional set of binds and
    # returns a SimpleOracleJDBC object after preparing and executing the procedure call.
    def self.execute(conn, sql, *binds)
      call = new(conn,sql)
      call.execute(*binds)
      call
    end

    # Similar to the class method prepare.
    def initialize(conn, sql)
      @connection = conn
      @call = @connection.prepare_call(sql)
    end

    # Executes the prepared callable statement stored in @call.
    #
    # The passed list of bind variables are bound to the object before it is executed.
    def execute(*binds)
      @binds = binds
      @binds.each_with_index do |b,i|
        bind_value(@call, b, i+1)
      end
      begin
        @call.execute
      rescue Java::JavaSql::SQLException => sqle
        if sqle.message =~ /no data found/
          raise SimpleOracleJDBC::NoDataFound, sqle.to_s
        elsif sqle.message =~ /too many rows/
          raise SimpleOracleJDBC::TooManyRows, sqle.to_s
        elsif sqle.message =~ /ORA-2\d+/
          raise SimpleOracleJDBC::ApplicationError, sqle.to_s
        else
          raise
        end
      end
      self
    end

    # Allows the bound values to be retrieved along with OUT or IN OUT parameters.
    #
    # The bind variables are indexed from 1.
    #
    # If a refcursor is return, it is retrieved as a SimpleOracleJDBC::Sql object. Other
    # values are returned as Ruby classes, such as Date, Time, String, Float etc.
    def [](i)
      if i < 1
        raise BindIndexOutOfRange, "Bind indexes must be greater or equal to one"
      end
      bind = @binds[i-1]
      if bind.is_a? Array
        # If its an array, it means it was in OUT or INOUT parameter
        if bind[0] == Date
          retrieve_date(@call, i)
        elsif bind[0] == Time
          retrieve_time(@call, i)
        elsif bind[0] == String
          retrieve_string(@call, i)
        elsif bind[0] == Fixnum or bind[0] == Integer
          retrieve_int(@call, i)
        elsif bind[0] == Float
          retrieve_number(@call, i)
        elsif bind[0] == :refcursor
          retrieve_refcursor(@call, i)
        end
      else
        # If its not an array, it was just an IN, so just pull the bind
        # out of the bind array. No need to get it from the DB object.
        bind
      end
    end

    # Closes the callable statement
    def close
      if @call
        @call.close
        @call = nil
      end
      @bind = nil
    end

  end
end
