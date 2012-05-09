# -------------------------------------------------------------------------- #
# Copyright 2002-2012, OpenNebula Project Leads (OpenNebula.org)             #
#                                                                            #
# Licensed under the Apache License, Version 2.0 (the "License"); you may    #
# not use this file except in compliance with the License. You may obtain    #
# a copy of the License at                                                   #
#                                                                            #
# http://www.apache.org/licenses/LICENSE-2.0                                 #
#                                                                            #
# Unless required by applicable law or agreed to in writing, software        #
# distributed under the License is distributed on an "AS IS" BASIS,          #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   #
# See the License for the specific language governing permissions and        #
# limitations under the License.                                             #
#--------------------------------------------------------------------------- #


begin # require 'rubygems'
    require 'rubygems'
rescue Exception
end

require 'pg'

require 'OpenDC/Calibration'

module OpenDC

    # The Error Class represents a generic error in the OpenDCLibrary
    # library. It contains a readable representation of the error.
    # Any function in the OpenNebula module will return an Error
    # object in case of error.
    class Error < StandardError
        ENO_EXISTS      = 0x0400
        ENOTDEFINED     = 0x1111

        attr_reader :message, :errno

        # +message+ Description of the error
        # +errno+   OpenNebula code error
        def initialize(message=nil, errno=0x1111)
            @message = message
            @errno   = errno
        end

        def to_str()
            @message
        end
    end

    # This class represents the results obtained after an EXPLAIN ANALZYZE query execution.
    # In OpenDC, only inherent data is filtered.
    class QueryResult <

        Struct::new(:rows, :actual_total_cost)
    end

    # Returns true if the object returned by a method of the OpenDC
    # library is an Error
    def self.is_error?(value)
        value.class==OpenDC::Error
    end

end
