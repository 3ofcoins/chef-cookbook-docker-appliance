provides 'docker'
require_plugin "network"
require_plugin "#{os}::network"

docker Mash.new
docker[:bridge_iface] = network[:interfaces].keys.find { |iface| iface.to_s =~ /^docker/ }

if docker[:bridge_iface]
  _iface = network['interfaces'][ docker[:bridge_iface] ]

  docker['bridge_ip']  = _iface['addresses'].
    select { |k,v| v['family'] == 'inet' }.
    keys.
    first

  docker['bridge_network'] = _iface['routes'].
    find { |r| r['family'] == 'inet' }['destination']
end
