name             'sbp_gluster'
maintainer       'Biola University, Schuberg Philis'
maintainer_email 'jared.king@biola.edu, rheinen@schubergphilis.com'
license          'Apache 2.0'
description      'Installs and configures Gluster servers and clients'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '2.0.16'

supports         'centos'
supports         'redhat'
supports         'debian'

depends          'apt'
depends          'yum'
