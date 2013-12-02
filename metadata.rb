name             "docker-appliance"
maintainer       "Maciej Pasternacki"
maintainer_email "maciej@3ofcoins.net"
license          'MIT'
description      "Docker Appliance"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends "apache2"
depends "docker", "~> 0.14"
depends "ohai"
