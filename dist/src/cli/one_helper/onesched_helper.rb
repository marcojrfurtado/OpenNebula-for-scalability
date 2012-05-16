require 'one_helper'

class OneSchedHelper < OpenNebulaHelper::OneHelper
  
  
  private
  
  
  def factory(id=nil)
          if id
              OpenNebula::VirtualMachine.new_with_id(id, @client)
          else
              xml=OpenNebula::VirtualMachine.build_xml
              OpenNebula::VirtualMachine.new(xml, @client)
          end
  end
end
