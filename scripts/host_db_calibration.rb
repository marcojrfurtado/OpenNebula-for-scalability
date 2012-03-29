#!/usr/bin/env ruby

####################################################
# Script to implement host database calibration
####################################################

ONE_LOCATION=ENV["ONE_LOCATION"]

DEPLOY_TIMEOUT=10
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

# Search for Image Template
images = ImagePool.new(client)
exit -1 if OpenNebula.is_error?(images)
images.info_all
image_ids_array = images.retrieve_elements("/IMAGE_POOL/IMAGE[NAME='CentOS 6 with PostgreSQL databases']/ID")


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
    template_ids_array.each do |template_id|
    	template = OpenNebula::Template.new_with_id(template_id, client)
    	template.info

        vm_id=template.instantiate("calib-host:#{host_id}")
    	exit -1 if OpenNebula.is_error?(vm_id)

    	vm = OpenNebula::VirtualMachine.new_with_id(vm_id)
        vm.info

        vm.hold

    	vm.deploy(host_id)

    	sleep DEPLOY_TIMEOUT.seconds
    	att = 1
    	vm.info
    	while (  OpenNebula::VM_STATE[vm.state] != 'ACTIVE'   )
    		if  ( att >= DEPLOY_CHECK )
    			puts "Couldn't deploy VM."
    			exit -1;
    		end
            if ( OpenNebula::VM_STATE[vm.state] == 'FAILED' )
                puts "Deployment failed."
            end
    		att+=1
            sleep DEPLOY_TIMEOUT.seconds
            vm.info
    	end

    end
end


exit 0
