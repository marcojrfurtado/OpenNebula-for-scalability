#!/usr/bin/ruby
require 'rubygems'
require 'pg'




class Calibrator


    DEFAULT_HOST = "localhost"
    DEFAULT_PORT = 5432
    DEFAULT_DBNAME = "calibration"
    DEFAULT_DBUSER = "calibrate"
    DEFAULT_DBPASSWORD = "calibrate"
#    DEFAULT_QUERY_FOLDER = "./queries"



    FILE_MAX_CONTENT = 90000




	def initialize( host = DEFAULT_HOST, port = DEFAULT_PORT, dbname = DEFAULT_DBNAME, dbuser = DEFAULT_DBUSER, dbpassword = DEFAULT_DBPASSWORD)

		@conn = PG.connect( :host => host, :dbname => dbname, :port => port, :user => dbuser, :password => dbpassword ) or
        i            abort "Unable to create a new connection!"

        abort "Connection failed: %s" % [ conn.error_message ] if
                @conn.status == PG::CONNECTION_BAD


    end

    def get_costs(query_file)

        fp = File.open(query_file,"r")

        unless fp
            abort "Unable to open file #{query_file}."
        end

        costs = Array.new
        result = run_analyze_query(fp.sysread(FILE_MAX_CONTENT))
        result.each{ |tuple|
            costs<< get_actual_total_cost(tuple['QUERY PLAN'])
        }
        costs
    end

private
    def run_analyze_query(raw_query)
        query_text = "EXPLAIN ANALYZE "+raw_query;
        @conn.exec(query_text)
    end

    def get_actual_total_cost(tuple)
#        puts tuple
        tuple.split.each{ |word|
            puts word
        }
    end

end



cal = Calibrator.new
cal.get_costs("./queries/seq_scan.sql")
#cal.get_costs("./queries/aggregate_seq_scan.sql")

