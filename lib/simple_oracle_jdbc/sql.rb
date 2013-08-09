module SimpleOracleJDBC

  class Sql

    # The Sql class provides a simple interface for preparing, executing and retrieving results
    # for SQL statements.
    #
    # The ResultSet module is included to allow results to be retrieved from result sets as arrays
    # or hashes.
    #
    # The Binding module is included to allow Ruby types to be convered into sensible Java equivalents
    # and vice versa.
    #
    # @!attribute statement
    #   @return [JDBC Prepared Statement] Returns the raw JDBC prepared statement
    #
    # @!attribute sql
    #   @return [String] Returns the original SQL string used to create the object
    #
    # @!attribute result_set
    #   @return [JDBC Result Set] Returns the raw JDBC result set after the statement is executed


    include Binding
    include ResultSet

    attr_reader :statement, :sql, :result_set

    attr_writer :result_set

    # Creates a new instance of this class. Not intended to be used directly. Use the factory
    # class methods prepare or execute instead.
    def initialize
      @auto_statement_close = true
    end

    # Takes a JDBC connection object and an SQL statement and returns a SimpleOracleJDBC::Sql
    # object with the prepared statement.
    def self.prepare(connection, sql)
      sql_object = self.new
      sql_object.disable_auto_statement_close
      sql_object.prepare(connection,sql)
    end

    # Takes a JDBC connection object, an SQL statement and an optional list of bind variables and
    # will prepare and execute the sql statement, returning an SimpleOracle::Sql object.
    def self.execute(connection, sql, *binds)
      sql_object = self.new
      sql_object.prepare(connection, sql)
      sql_object.execute(*binds)
    end

    # Given a JDBC connection and a SQL string, the sql will be stored in the @sql instance variable
    # and a JDBC prepared statement will be stored in @statement.
    #
    # This method returns self to allow calls to be chained.
    def prepare(connection, sql)
      @sql = sql
      @statement = connection.prepare_statement(@sql)
      self
    end

    # Executes the SQL prepared by the prepare method and binds the optional list of bind varibles.
    #
    # If the SQL statement does not return data (ie is not a select statement) then @result_set will be
    # set to nil. Otherwise, the resulting JDBC result set will be stored in @result_set
    def execute(*binds)
      binds.each_with_index do |b, i|
        bind_value(@statement, b, i+1)
      end

      # What about a select that starts with the WITH clause?
      unless @sql =~ /^\s*select/i
        @result_set = nil
        @statement.execute()
        if @auto_statement_close
          close_statement
        end
      else
        @result_set = @statement.execute_query()
      end
      self
    end

    # Closes both the prepared SQL statement stored in @statement and any result set stored in @result_set
    def close
      close_result_set
      close_statement
    end

    # Closes the JDBC statement stored in @statement
    def close_statement
      if @statement
        @statement.close
        @statement = nil
      end
    end


    # If a statement was prepared, it is likely it is going to be reused, so the statement
    # handle should not be closed after execution.
    #
    # If the statement is directly executed, then the prepared handle was never requested
    # and so it probably should be closed.
    #
    # This method is called by the prepare class/factory method
    def disable_auto_statement_close
      @auto_statement_close = false
    end

  end
end
