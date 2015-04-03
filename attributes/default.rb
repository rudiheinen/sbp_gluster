#
# Cookbook Name:: gluster
# Attributes:: default
#
# Copyright (C) 2015 Schuberg Philis
# 
# Created by: Rudi Heinen <rheinen@schubergphilis.com>
#

# Pin version of gluster
default['gluster']['version'] = "3.6.3"
default['gluster']['build'] = "1.el7"
# Switch to use public or private repo, if you use private repo, please use yum cookbook to manage your repo with a cookbook role
default['gluster']['repo'] = "public"

default['gluster']['server']['nagios_plugin_dir'] = "/var/lib/glusterd"
default['gluster']['server']['nrpe_user'] = "nrpe"
default['gluster']['server']['nrpe_group'] = "nrpe"
