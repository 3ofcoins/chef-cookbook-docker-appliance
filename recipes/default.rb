# Docker Appliance
# ================

include_recipe "ohai"
include_recipe "docker"

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

chef_gem 'docker-api'
chef_gem 'jsonpath'

require 'docker'
require 'jsonpath'

if node['docker']['iptables_allow_containers']
  begin
    iptables_rule "docker-containers"
  rescue NameError
    # no iptables recipe included
  end

  if node['postfix'] && node['postfix']['main']
    node.set['postfix']['main']['inet_interfaces'] =
      Array(node['postfix']['main']['inet_interfaces']).
      map { |iface| iface.sub('loopback-only', '127.0.0.1') } | [
        node['docker']['bridge_ip'] ]

    node.set['postfix']['main']['mynetworks'] =
      Array(node['postfix']['main']['mynetworks']) | [
        node['docker']['bridge_network'] ]
  end
end

node['docker_appliance'].to_hash.each do |name, attr|
  next unless attr['image']

  attr = JSON.load(JSON.dump(attr)) # full recursive to_hash
  attr['env'] ||= {}

  if attr['postgresql_db']
    include_recipe 'docker-appliance::postgresql'

    node.set_unless['docker_appliance'][name]['postgresql_password'] = secure_password

    db_name = attr['postgresql_db'] == true ? "docker_#{name}" : attr['postgresql_db']
    db_password = node['docker_appliance'][name]['postgresql_password']
    db_username = attr['postgresql_username'] || "docker_#{name}"

    pg_conn = {
      host: '127.0.0.1',
      port: node['postgresql']['config']['port'],
      username: 'postgres',
      password: node['postgresql']['password']['postgres'] }

    postgresql_database_user db_username do
      connection pg_conn
      password db_password
      action :create
    end

    postgresql_database db_name do
      connection pg_conn
      owner db_username
      action :create
    end

    attr['env'].merge! 'PGHOST' => node['docker']['bridge_ip'],
                       'PGDATABASE' => db_name,
                       'PGUSER' => db_username,
                       'PGPASSWORD' => db_password,
                       'PGPORT' => node['postgresql']['config']['port'].to_s
  end

  docker_container name do
    image attr['image']
    command attr['command'] if command
    detach true
    hostname name
    container_name name
    publish_exposed_ports attr['publish_exposed_ports'] if attr['publish_exposed_ports'] != nil
    port attr['port'] if attr['port']
    env attr['env'].reject { |k,v| v == nil }.map { |k,v| "#{k}=#{v.to_s.gsub('@HOST_IP@', node['docker']['bridge_ip'])}" }.sort unless attr['env'].empty?
    link attr['link'].map { |k,v| "#{v}:#{k}" }.sort.join(',') if attr['link']
  end

  if attr['apache2_proxy']
    include_recipe 'apache2'
    include_recipe 'apache2::mod_proxy'
    include_recipe 'apache2::mod_proxy_http'
    include_recipe 'apache2::mod_ssl' if attr['apache2_proxy']['ssl_key_path']
    web_app "docker-appliance-#{name}" do
      container_name name
      appliance_attributes attr
    end
  end
end
