#!/usr/bin/env ruby

####################################################
# Script to implement host database calibration
####################################################

ONE_LOCATION=ENV["ONE_LOCATION"]

DEPLOY_TIMEOUT=15
DEPLOY_CHECK=4

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


# Connect to the PostgreSQ service
begin
    cl = Calibration.new(  "192.168.122.2" )
rescue Error => e
    puts e.message
    puts 'Wasn\'t able to connect to the PostgreSQL inside the VM. Check Network Configurations.'
    exit -1
end


result_set = cl.get_costs('./queries/seq_scan.sql')

puts result_set.inspect

#cl.get_costs('./queries/aggregate_seq_scan.sql')
