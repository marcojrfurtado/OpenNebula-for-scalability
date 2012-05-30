#!/usr/bin/ruby

require 'thread'

module OpenDC

    class GreedyEnumerationConfiguration



        def initialize(host)

            # Defines when a search can be stopped
            @done = false

            @host = host


            # Avoids concurrent IO to @done
            @semaphore = Mutex.new

            begin
                @cost_estimate = LinearRegression.new(VMDIR+"/#{host.id}"+"/cpu_operator_cost.dat")
            rescue
                OpenNebula.log_error "Data file not found. Exiting "
                exit -1
            end
        end

        def run


            @search_thread = Thread.new {

                until @done




                end

            }
        end

        def finalize
            @semaphore.synchronize {
                @done = true
            }
        end

    end
end
