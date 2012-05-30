#!/usr/bin/ruby

module OpenDC


    class CPULimitation


        VIRSH_COMMAND="/usr/bin/virsh -c qemu:///system"
        SCHEDINFO_SUBCOMMAND="schedinfo"
        VIRSH_OPTS="--live"


        DEFAULT_REMOTE_DIR="~"

        Virsh_info = Struct.new(:quota,:period,:shares)

        def self.get_quota(vm,host)
            begin
                ret = self.get_info(vm,host)
            rescue Error => e
                puts e.message
                puts "Failed to get info from running domain."
                exit -1
            end

            ret.quota
        end


        def self.get_shares(vm,host)
            begin
                ret = self.get_info(vm,host)
            rescue Error => e
                puts e.message
                puts "Failed to get info from running domain."
                exit -1
            end

            ret.shares
        end

        def self.set_hardlimit(vm,host,ratio)

            begin
                ret = self.get_info(vm,host)
            rescue Exception => e
                puts "Failed to get info from running domain."
                exit -1
            end

            actual_value = ( ratio <= 0 or ratio >= 1)?-1:(ratio * ret.period).to_i

            deploy_id = vm.retrieve_elements('/VM/DEPLOY_ID').first

            cmd = VIRSH_COMMAND + " " + SCHEDINFO_SUBCOMMAND + " " + deploy_id + " --set vcpu_quota=#{actual_value} " + " " + VIRSH_OPTS


            ret = RemotesCommand.run(cmd,host.name,DEFAULT_REMOTE_DIR)

            if ( exit_code(ret.stderr) == 0 )
                puts "CPU has been succesfully limited to #{ratio}."
            else
                puts ret.stderr
                exit -1
            end

        end

        def self.set_softlimit(vm,host,desired_share)

            deploy_id = vm.retrieve_elements('/VM/DEPLOY_ID').first

            cmd = VIRSH_COMMAND + " " + SCHEDINFO_SUBCOMMAND + " " + deploy_id + " --set vcpu_shares=#{desired_share} " + " " + VIRSH_OPTS

            ret = RemotesCommand.run(cmd,host.name,DEFAULT_REMOTE_DIR)

            if ( exit_code(ret.stderr) == 0 )
                puts "CPU has been succesfully limited to #{ratio}."
            else
                puts ret.stderr
                exit -1
            end

        end

        private



        def self.exit_code(cmd)
            cmd[/ExitCode: ([0-9]+)/,1].to_i
        end

        def self.get_info(vm,host)

            deploy_id = vm.retrieve_elements('/VM/DEPLOY_ID').first

            cmd = VIRSH_COMMAND + " " + SCHEDINFO_SUBCOMMAND + " " + deploy_id + " "    + VIRSH_OPTS

            cmd_result = RemotesCommand.run(cmd,host.name,DEFAULT_REMOTE_DIR)

            ex_code = self.exit_code(cmd_result.stderr)

            if ( ex_code != 0 )
                puts cmd_result.stderr
                err = Error.new "Exiting with code #{ex_code}."
                puts err.to_str
                raise err
            end
            ret = Virsh_info.new

            ret.shares = cmd_result.stdout[/cpu_shares.*: ([0-9]+)/,1].to_i
            ret.period = cmd_result.stdout[/vcpu_period.*: ([0-9]+)/,1].to_i
            ret.quota = cmd_result.stdout[/vcpu_quota.*: (-*[0-9]+)/,1].to_i

            ret
        end


    end

end

