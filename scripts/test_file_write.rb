#!/usr/bin/env ruby

####################################################
# Script to implement host database calibration
####################################################

ONE_LOCATION=ENV["ONE_LOCATION"]

DEPLOY_TIMEOUT=15
DB_TIMEOUT=10
DEPLOY_CHECK=DB_CHECK=4

if !ONE_LOCATION
    RUBY_LIB_LOCATION="/usr/lib/one/ruby"
    VMDIR="/var/lib/one"
else
    RUBY_LIB_LOCATION=ONE_LOCATION+"/lib/ruby"
    VMDIR=ONE_LOCATION+"/var"
end

$: << RUBY_LIB_LOCATION

require 'OpenNebula'
include OpenNebula

require 'OpenDC'
include OpenDC

client = Client.new

host  =  OpenNebula::Host.new_with_id(1, client)
host.info

vm = OpenNebula::VirtualMachine.new_with_id(95,client)
vm.info


# Get this VM's IP

vm_ip = vm.retrieve_elements("/VM/TEMPLATE/NIC/IP").first


# Connect to the PostgreSQ service
sleep DB_TIMEOUT
att = 1
cl = nil
puts vm_ip
while ( cl.nil? )
    begin
        cl = Calibration.new( vm_ip )
    rescue Error => e
        if ( att < DB_CHECK)
            att+=1
        else
            puts e.message
            puts 'Wasn\'t able to connect to the PostgreSQL inside the VM after #{att} attempts. Check Network Configurations.'
            exit -1
        end
    end
    sleep DB_TIMEOUT
end

# Start executing queries at different resource levels
#
# First, let's create a file to store these results to be used later.


dest_dir = VMDIR + "/" + "calibration_results" + "/" + host.id.to_s

unless FileTest::directory? dest_dir
    begin
        FileUtils::mkdir_p(dest_dir)
    rescue Exception => e
        puts e.message
        puts "Was not able to create the calibration results directory."
        exit -1
    end
end

fp = File.new(dest_dir+"/"+"cpu_operator_cost.dat","w")
fp.truncate(0)

ratio = 0.2
x = Array.new
y = Array.new

result_set = cl.process('./queries/aggregate_seq_scan.sql')
while ratio < 0.8
    begin
        OpenDC::CPULimitation.set_hardlimit(vm,host,ratio)
    rescue Error => e
        puts e.message
        exit -1
    end

    sleep 0.5

    for i in 1..5 do
        result_set = cl.process('./queries/aggregate_seq_scan.sql')

        agg = result_set[0]
        seq = result_set[1]

        # The second result constains the SEQ_SCAN, in which the cost is expressed as "num_pages + cpu_tuple_cost * rows"
        # The first contains the AGGREGATE, as the page scans has already been calculated in the SEQ_SCAN, we express this aggregate as follows:
        # "cpu_operator_cost * num_rows - SEQ_SCAN"
        #
        # We collect all the points and perform a linear regression.
        #

        cpu_operator_cost = (agg.actual_total_cost - seq.actual_total_cost)/seq.rows

    #    x << ratio
    #    y << cpu_operator_cost
        #



        fp.puts "#{ratio} #{cpu_operator_cost}"
    end

    ratio+=0.1
end

begin
      OpenDC::CPULimitation.set_hardlimit(vm,host,-1)
rescue Error => e
      puts e.message
      exit -1
end

#lr = OpenDC::LinearRegression.new(x,y)




exit 0
