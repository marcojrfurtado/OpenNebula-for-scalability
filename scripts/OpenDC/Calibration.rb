#!/usr/bin/ruby



module OpenDC
	class Calibration


	    DEFAULT_HOST = "127.0.0.1"
	    DEFAULT_PORT = 5432
	    DEFAULT_DBNAME = "calibration"
	    DEFAULT_DBUSER = "calibrate"
	    DEFAULT_DBPASSWORD = "calibrate"
	#    DEFAULT_QUERY_FOLDER = "./queries"



	    FILE_MAX_CONTENT = 90000


	    def initialize( hostaddr = DEFAULT_HOST, port = DEFAULT_PORT, dbname = DEFAULT_DBNAME, dbuser = DEFAULT_DBUSER, dbpassword = DEFAULT_DBPASSWORD)

#		@conn = PG.connect( :host => host, :dbname => dbname, :port => port, :user => dbuser, :password => dbpassword ) or
#		            abort "Unable to create a new connection!"

		@conn = PG.connect( :hostaddr => hostaddr, :dbname => dbname, :port => port, :user => dbuser, :password => dbpassword )

		unless @conn
			raise Error "Couldn't connect to specified database"
		end


	    end

	    def process(query_file)

    		fp = File.open(query_file,"r")

	    	unless fp
		        Error "Unable to open file #{query_file}."
    		end

	    	formatted_result_set = Array.new
    		result = run_analyze_query(fp.sysread(FILE_MAX_CONTENT))
    		result.each{ |tuple|
                formatted_result = QueryResult.new
		        new_cost = get_actual_total_cost(tuple['QUERY PLAN'])
                new_nominal_cost = get_nominal_total_cost(tuple['QUERY PLAN'])
                num_rows = get_total_rows(tuple['QUERY PLAN'])
                if new_cost and num_rows
                    formatted_result.rows = num_rows
                    formatted_result.actual_total_cost = new_cost
                    formatted_result.nominal_total_cost = new_nominal_cost
#                    formatted_result.pages = new_nominal_cost - ( num_rows * get_cpu_tuple_cost )
    			    formatted_result_set << formatted_result
                end
		    }
    		formatted_result_set
	    end

	private
	    def run_analyze_query(raw_query)
		query_text = "EXPLAIN ANALYZE "+raw_query;
		@conn.exec(query_text)
	    end

	    def get_actual_total_cost(tuple)
    		match = tuple[/actual time=([0-9]*\.[0-9]+|[0-9]+)\.\.([0-9]*\.[0-9]+|[0-9]+)/, 2]
		    if match
		    match.to_f
    		else
	    	    nil
		    end
	    end

        def get_nominal_total_cost(tuple)
    		match = tuple[/cost=([0-9]*\.[0-9]+|[0-9]+)\.\.([0-9]*\.[0-9]+|[0-9]+)/, 2]
		    if match
		    match.to_f
    		else
	    	    nil
		    end
        end

        def get_total_rows(tuple)
            match= tuple[/rows=([0-9]*)/,1]
            if match
                match.to_i
            else
                nil
            end
        end

        def get_cpu_tuple_cost()
            dir = OPENDC_LOCATION + "/queries/SHOW_cpu_tuple_cost.sql"
		    fp = File.open(dir)

    		unless fp
	    	    raise Error "Unable to open file #{query_file}."
                exit -1
    		end

	    	formatted_result_set = Array.new
		    result = @conn.exec(fp.sysread(FILE_MAX_CONTENT))
            result.values.first.first.to_f
        end

	end

end



#cal = Calibration.new
#puts cal.get_costs("./queries/seq_scan.sql")
#cal.get_costs("./queries/aggregate_seq_scan.sql")

