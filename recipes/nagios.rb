#
# Cookbook Name:: gluster
# Recipe:: nagios
#
# Copyright 2015, Schuberg Philis
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
extend Chef::Util::Selinux
selinux_enabled = selinux_enabled?

%w(checkpolicy policycoreutils-python).each do | p |
  package p do
    only_if { selinux_enabled }
  end
end

sudo 'glusterfsd' do
  user      'nagios'
  runas     'root'
  nopasswd  true
  commands  ['/usr/sbin/gluster volume status [[\:graph\:]]* detail','/usr/sbin/gluster volume heal [[\:graph\:]]* info']
end

# Create and start volumes
node['gluster']['server']['volumes'].each do |volume_name, volume_values|
  check_name = "check_gluster_"+volume_name
  node.set['nagios']['nrpe_commands'][check_name.downcase] = {
    "command" => "#{node['gluster']['server']['nagios_plugin_dir']}/check_glusterfs -v #{volume_name} -n #{volume_values['replica_count']}",
    "display_name" => "Check status of volume #{volume_name}"
  }
end

# Adding custom plugins
cookbook_file "check_glusterfs" do 
   path "#{node['gluster']['server']['nagios_plugin_dir']}/check_glusterfs"
   owner "#{node['gluster']['server']['nrpe_user']}"
   group "#{node['gluster']['server']['nrpe_group']}"
   mode 0755
end

file '/etc/selinux/local/gluster.te' do
  owner 'root'
  group 'root'
  mode 0644
  only_if { selinux_enabled }
  content <<-EOF
module gluster 1.0;

require {
  type nrpe_t;
  type sudo_exec_t;
  type nagios_system_plugin_t;
  type nrpe_exec_t;
  type glusterd_conf_t;
  type glusterd_log_t;
  type glusterd_var_lib_t;
  type glusterd_var_run_t;
  type ldconfig_exec_t;
  type glusterd_t;
  type gluster_port_t;
  type hi_reserved_port_t;
  type sysctl_net_t;
  type virt_migration_port_t;
  class netlink_audit_socket { create read };
  class file {execute getattr open read execute_no_trans};
  class dir {search getattr open read};
  class sock_file write;
  class capability2 block_suspend;
  class unix_stream_socket connectto;
  class tcp_socket { name_connect name_bind};
}

#============= nrpe_t ==============
allow nrpe_t sudo_exec_t:file {getattr execute read open execute_no_trans};
allow nrpe_t self:netlink_audit_socket create;
allow nrpe_t glusterd_conf_t:dir search;
allow nrpe_t glusterd_log_t:dir search;
allow nrpe_t glusterd_var_lib_t:dir search;
allow nrpe_t glusterd_log_t:file {read open};
allow nrpe_t glusterd_var_run_t:sock_file write;
allow nrpe_t ldconfig_exec_t:file { execute getattr open read execute_no_trans};
allow nrpe_t self:capability2 block_suspend;
allow nrpe_t glusterd_t:unix_stream_socket connectto;
allow nrpe_t gluster_port_t:tcp_socket name_connect;
allow nrpe_t hi_reserved_port_t:tcp_socket name_bind;
allow nrpe_t sysctl_net_t:file { open read };
allow nrpe_t virt_migration_port_t:tcp_socket name_connect;

#============= nagios_system_plugin_t ==============
allow nagios_system_plugin_t nrpe_exec_t:file {execute getattr read open execute_no_trans};

  EOF
  notifies :run, 'execute[selinux_gluster_policy_install]', :immediately
end

execute 'selinux_gluster_policy_install' do
  command '/usr/bin/checkmodule -m -M -o /etc/selinux/local/gluster.mod /etc/selinux/local/gluster.te && /usr/bin/semodule_package -o /etc/selinux/local/gluster.pp -m /etc/selinux/local/gluster.mod && /usr/sbin/semodule -i /etc/selinux/local/gluster.pp'
  action :nothing
  only_if { selinux_enabled }
end
