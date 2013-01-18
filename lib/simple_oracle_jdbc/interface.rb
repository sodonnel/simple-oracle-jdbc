module SimpleOracleJDBC

  class NoDataFound < Exception
  end
  class TooManyRows < Exception
  end
  class ApplicationError < Exception
  end
  class NoResultSet < Exception
  end
  class BindIndexOutOfRange < Exception
  end
  class UnknownBindType < Exception
  end
  class UnknowSQLType < Exception
  end

  class Interface

    # The Interface class is the intended entry point for the SimpleOracleJDBC gem.
    #
    # The SimpleOracleJDBC class  provides a lightweight wrapper around a raw JDBC connection
    # to make interaction between JRuby and Oracle easier. It only wraps commonly used features of JDBC,
    # and makes the raw JDBC connection available to handle less common or more complex tasks.
    #
    # @!attribute connection
    #   @return [JDBC Oracle Database connection] Returns the raw JDBC database connection

    attr_accessor :connection

    # Factory method to create a new interface using an existing database connection.
    # Returns an instance of SimpleOracleJDBC::Interface
    def self.create_with_existing_connection(conn)
      connector = self.new
      connector.set_connection conn
      connector
    end

    # Factory method to establish a new JDBC connection and create a new interface.
    # Returns a SimpleOracleJDBC::Interface
    def self.create(user, password, database_service, host=nil, port=nil)
      conn = self.new
      conn.connect(user, password, database_service, host, port)
      conn
    end

    # Establishes a new database connection using the supplied parameters.
    def connect(user, password, database_service, host=nil, port=nil)
      oradriver = OracleDriver.new

      DriverManager.registerDriver oradriver
      @connection = DriverManager.get_connection "jdbc:oracle:thin:@#{host}:#{port}/#{database_service}", user, password
      @connection.auto_commit = false
    end

    # Closes the database connection
    def disconnect
      if @connection
        @connection.close
        @connection = nil
      end
    end

    # Performs a commit on the database connection
    def commit
      @connection.commit
    end

    # Performs a rollback on the database connection
    def rollback
      @connection.rollback
    end

    # Prepares a SQL statement using the Sql class.
    #
    # Returns a Sql object.
    def prepare_sql(query)
      Sql.prepare(@connection, query)
    end

    # Executes a SQL statement using the Sql class
    #
    # Returns a Sql object
    def execute_sql(query, *binds)
      Sql.execute(@connection, query, *binds)
    end

    # Prepares a stored procedure call using the DBCall class.
    #
    # Returns a DBCall object
    def prepare_proc(sql)
      DBCall.prepare(@connection, sql)
    end

    alias_method :prepare_call, :prepare_proc

    # Executes a stored procedure call using the DBCall class.
    #
    # Returns a DBCall object
    def execute_proc(sql, *binds)
      DBCall.execute(@connection, sql, *binds)
    end

    alias_method :execute_call, :execute_proc

    protected

    def set_connection(conn)
      @connection = conn
    end

    private

    def initialize
    end

  end

end

