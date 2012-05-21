#!/usr/bin/env ruby

####################################################
# Script to implement host database calibration
####################################################

ONE_LOCATION=ENV["ONE_LOCATION"]

DEPLOY_TIMEOUT=DB_TIMEOUT=15
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

if !(host_id=ARGV[0])
    puts "No host informed"
    exit -1
end
1
begin
    client = Client.new()
rescue Exception => e
    puts "Error: #{e}"
    exit -1
end

# Retrieve hostname
host  =  OpenNebula::Host.new_with_id(host_id, client)
exit -1 if OpenNebula.is_error?(host)
host.info
host_name = host.name


# Check wheteher there is already a Calibration VM to be used
#
vms = VirtualMachinePool.new(client)
exit -1 if OpenNebula.is_error?(vms)
vms.info_all
vm_ids_array = vms.retrieve_elements("/VM_POOL/VM[STATE=1 and contains(NAME,\"calib-host\")]/ID")

if vm_ids_array
    vm_id = vm_ids_array.first
    vm = OpenNebula::VirtualMachine.new_with_id(vm_id,client)
    vm.info
else
    # Search for Image Template
    images = ImagePool.new(client)
    exit -1 if OpenNebula.is_error?(images)
    images.info_all
    image_ids_array = images.retrieve_elements("/IMAGE_POOL/IMAGE[NAME='Debian Calibration']/ID")


    unless image_ids_array
    	puts "Couldn't find calibration image."
    	exit(-1)
    end

    image = OpenNebula::Image.new_with_id(image_ids_array.first,client)

    image.info

    state = OpenNebula::Image::IMAGE_STATES[image.state]
    if  state == 'DISABLED'
    	image.enable
    end



    # Loop through all templates
    templates = TemplatePool.new(client)
    exit -1 if OpenNebula.is_error?(templates)

    templates.info_all
    template_ids_array = templates.retrieve_elements("/VMTEMPLATE_POOL/VMTEMPLATE/TEMPLATE/DISK[IMAGE_ID=\"#{image.id}\"]/../../ID")



    if template_ids_array
        template_id = template_ids_array.first
    	template = OpenNebula::Template.new_with_id(template_id, client)
    	template.info

        vm_id=template.instantiate("calib-host:#{host_id}")
    	exit -1 if OpenNebula.is_error?(vm_id)

    	vm = OpenNebula::VirtualMachine.new_with_id(vm_id,client)
        vm.info
    end
end
#vm.hold


# Deploy this VM
vm.deploy(host_id)
exit -1 if OpenNebula.is_error?(templates)
if ( vm.nil?  )
    puts "Wasn't able to deploy this VM."
    exit -1
end

# We wait for some time, so it can boot.
sleep DEPLOY_TIMEOUT
att = 1
vm.info
while (  OpenNebula::VirtualMachine::VM_STATE[vm.state] != 'ACTIVE' or OpenNebula::VirtualMachine::LCM_STATE[vm.lcm_state] != 'RUNNING'  )
        if  ( att >= DEPLOY_CHECK )
            puts "Deployment timeout expired."
            exit -1;
        end
        if ( OpenNebula::VirtualMachine::VM_STATE[vm.state] == 'FAILED' or OpenNebula::VirtualMachine::LCM_STATE[vm.lcm_state] == 'FAILURE' )
            puts "Deployment failed."
        end
        att+=1
        sleep DEPLOY_TIMEOUT
        vm.info
end



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


ratio = 0.1
x = Array.new
y = Array.new

while ratio < 1
    begin
        OpenDC::CPULimitation.set_hardlimit(vm,host,ratio)
    rescue Error => e
        puts e.message
        exit -1
    end

    sleep 0.5
    result_set = cl.process('./queries/aggregate_seq_scan.sql')

    agg = result_set.first
    seq = result_set.second

    # The second result constains the SEQ_SCAN, in which the cost is expressed as "num_pages + cpu_tuple_cost * rows"
    # The first contains the AGGREGATE, as the page scans has already been calculated in the SEQ_SCAN, we express this aggregate as follows:
    # "cpu_operator_cost * num_rows - SEQ_SCAN"
    #
    # We collect all the points and perform a linear regression.
    #

    cpu_operator_cost = (agg.actual_total_cost - seq.actual_total_cost)/agg.rows

    x << ratio
    y << cpu_operator_cost

    puts "#{ratio} #{cpu_operator_cost}"

    ratio+=0.1
end

#lr = OpenDC::LinearRegression.new(x,y)






exit 0
