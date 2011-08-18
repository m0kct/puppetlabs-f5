require 'puppet/provider/f5'

Puppet::Type.type(:f5_pool).provide(:f5_pool, :parent => Puppet::Provider::F5) do
  @doc = "Manages f5 pool"

  confine :feature => :posix
  defaultfor :feature => :posix

  F5_WSDL = 'LocalLB.Pool'

  def self.instances
    transport[F5_WSDL].get_list.collect do |name|
      new(:name => name)
    end
  end

  methods = [ 'action_on_service_down',
    'allow_nat_state',
    'allow_snat_state',
    'client_ip_tos',
    'client_link_qos',
    'description',
    'gateway_failsafe_device',
    'gateway_failsafe_unit_id',
    'lb_method',
    'minimum_active_member',
    'minimum_up_member',
    'minimum_up_member_action',
    'minimum_up_member_enabled_state',
    'server_ip_tos',
    'server_link_qos',
    'simple_timeout',
    'slow_ramp_time']

  methods.each do |method|
    define_method(method.to_sym) do
      if transport[F5_WSDL].respond_to?("get_#{method}".to_sym)
        transport[F5_WSDL].send("get_#{method}", resource[:name]).first
      end
    end
  end

  methods.each do |method|
    define_method("#{method}=") do |value|
      if transport[F5_WSDL].respond_to?("set_#{method}".to_sym)
        transport[F5_WSDL].send("set_#{method}", resource[:name], resource[method.to_sym])
      end
    end
  end

  def member
    members = transport[F5_WSDL].get_member(resource[:name]).first

    members.collect { |system|
      "#{system.address}:#{system.port}"
    }
  end

  def member=(value)
    members = transport[F5_WSDL].get_member(resource[:name]).first

    members = members.collect { |system|
      "#{system.address}:#{system.port}"
    }

    # Should add first to avoid clearing all members of the pool.
    (resource[:member]-members).each do |node|
      Puppet.debug "Puppet::Provider::F5_Pool: adding member #{node}"
      #transport["LocalLB.Pool"].add_member(resource[:member],
      #                         [[{:address => node.split(':')[0],
      #                           :port    => node.split(':')[1]}]])
    end

    (members-resource[:member]).each do |node|
      Puppet.debug "Puppet::Provider::F5_Pool: removing member #{node}"
      #transport[F5_WSDL].remove_member(resource[:member],
      #                         [[{:address => node.split(':')[0],
      #                           :port    => node.split(':')[1]}]])
    end
  end

  def monitor_association
    monitor = transport[F5_WSDL].get_monitor_association(resource[:name]).first.monitor_rule

    [ monitor.type, monitor.quorum, monitor.monitor_templates ]
  end

  def monitor_association=(value)
    transport[F5_WSDL].set_monitor_association(resource[:name], resource[:monitor_association])
  end

  def create
    Puppet.debug("Puppet::Provider::F5_Pool: creating F5 pool #{resource[:name]}")
    transport[F5_WSDL].create(resource[:name])
  end

  def destroy
    Puppet.debug("Puppet::Provider::F5_Pool: destroying F5 pool #{resource[:name]}")
    transport[F5_WSDL].delete_pool(resource[:name])
  end

  def exists?
    transport[F5_WSDL].get_list.include?(resource[:name])
  end
end