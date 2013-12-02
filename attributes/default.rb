# Docker Appliance Attributes
# ============================

include_attribute 'ohai'
default['ohai']['plugins']['docker-appliance'] = 'ohai-plugins'

default['docker']['iptables_allow_containers'] = true
