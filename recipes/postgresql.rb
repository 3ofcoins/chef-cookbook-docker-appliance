
node.set['postgresql']['pg_hba'] = Array(node['postgresql']['pg_hba']).
  reject { |hba| hba['docker_appliance'] }
node.set['postgresql']['pg_hba'] << {
  type: 'host',
  db: 'all',
  user: 'all',
  addr: node['docker']['bridge_network'],
  method: 'md5',
  docker_appliance: true
}

node.set['postgresql']['config']['listen_addresses'] = ( node['postgresql']['config']['listen_addresses'].split(',') | [ node['docker']['bridge_ip'] ] ).join(',')

include_recipe 'database::postgresql'
include_recipe 'postgresql::server'
