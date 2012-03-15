#!/usr/bin/ruby
require 'rubygems'
require 'pg'




class Calibrator


    DEFAULT_HOST = "localhost"
    DEFAULT_PORT = 5432
    DEFAULT_DBNAME = "calibration"
    DEFAULT_DBUSER = "calibrate"
    DEFAULT_DBPASSWORD = "calibrate"




	def initialize( host = DEFAULT_HOST, port = DEFAULT_PORT, dbname = DEFAULT_DBNAME, dbuser = DEFAULT_DBUSER, dbpassword = DEFAULT_DBPASSWORD)

		@conn = PG.connect( :host => host, :dbname => dbname, :port => port, :user => dbuser, :password => dbpassword ) or
        i            abort "Unable to create a new connection!"

        abort "Connection failed: %s" % [ conn.error_message ] if
                @conn.status == PG::CONNECTION_BAD


    end

    def run_query(query_text)
        result = @conn.exec(query_text)
        puts result.values
    end
end



cal = Calibrator.new
cal.run_query("SELECT * FROM pgbench_history ;")

