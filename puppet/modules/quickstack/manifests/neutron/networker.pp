
class quickstack::neutron::networker (
  $fixed_network_range          = $quickstack::params::fixed_network_range,
  $floating_network_range       = $quickstack::params::floating_network_range,
  $metadata_proxy_shared_secret = $quickstack::params::metadata_proxy_shared_secret,
  $neutron_db_password          = $quickstack::params::neutron_db_password,
  $nova_db_password             = $quickstack::params::nova_db_password,
  $nova_user_password           = $quickstack::params::nova_user_password,
  $controller_priv_floating_ip  = $quickstack::params::controller_priv_floating_ip,
  $private_interface            = $quickstack::params::private_interface,
  $public_interface             = $quickstack::params::public_interface,
  $verbose                      = $quickstack::params::verbose,
) inherits quickstack::params {

    class { '::neutron':
        verbose               => true,
        allow_overlapping_ips => true,
        rpc_backend           => 'neutron.openstack.common.rpc.impl_qpid',
        qpid_hostname         => $controller_priv_floating_ip,
    }
    
    neutron_config {
        'database/connection': value => "mysql://neutron:${neutron_db_password}@${controller_priv_floating_ip}/neutron";

        'keystone_authtoken/admin_tenant_name': value => 'admin';
        'keystone_authtoken/admin_user':        value => 'admin';
        'keystone_authtoken/admin_password':    value => $admin_password;
        'keystone_authtoken/auth_host':         value => $controller_priv_floating_ip;
    }

    class { '::neutron::plugins::ovs':
        sql_connection      => "mysql://neutron:${neutron_db_password}@${controller_priv_floating_ip}/neutron",
        tenant_network_type => 'gre',
    }

    class { '::neutron::agents::ovs':
        local_ip         => getvar("ipaddress_${private_interface}"),
        enable_tunneling => true,
    }

    class { '::neutron::agents::dhcp': }

    class { '::neutron::agents::l3': }

    class { 'neutron::agents::metadata':
        auth_password => $admin_password,
        shared_secret => $metadata_proxy_shared_secret,
        auth_url      => "http://${controller_priv_floating_ip}:35357/v2.0",
        metadata_ip   => $controller_priv_floating_ip,
    }

    #class { 'neutron::agents::lbaas': }

    #class { 'neutron::agents::fwaas': }
}
