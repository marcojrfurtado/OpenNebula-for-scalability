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

vm_ip = vm.retrieve_elements("/VM/TEMPLATE/NIC/IP")


# Connect to the PostgreSQ service
begin
    cl = Calibration.new( :host => vm_ip )
rescue Error => e
    puts e.message
    puts 'Wasn\'t able to connect to the PostgreSQL inside the VM. Check Network COnfigurations.'
    exit -1
end






exit 0
