# -*- mode: ruby -*-
# # vi: set ft=ruby :


$project_name = 'notifications'


# ============================================================================
# PLUGINS & DEPENDENCIES
#

require 'fileutils'

unless Vagrant.has_plugin?('vagrant-docker-env') && (ENV['SKIP'] || ENV['SKIP'] != '')
  raise "Plugin docker-env is not installed!\n\n" \
    + 'vagrant plugin install vagrant-docker-env'
end
unless Vagrant.has_plugin?('vagrant-triggers') && (ENV['SKIP'] || ENV['SKIP'] != '')
  raise "Plugin triggers is not installed!\n\n" \
    + 'vagrant plugin install vagrant-triggers'
end


# ============================================================================
# COREOS OPTIONS
#

CLOUD_CONFIG_PATH = File.join(File.dirname(__FILE__), 'user-data')
CONFIG = File.join(File.dirname(__FILE__), 'config.rb')

# Defaults for config options defined in CONFIG
$update_channel        = 'stable'
$enable_serial_logging = false
$vb_gui                = false
$vb_memory             = 1024
$vb_cpus               = 1
$expose_docker_tcp     = 2375
$expose_docker_ip      = '172.17.8.102' # should be unique per-project


# This exposes a new vagrant command, `docker-env`, to correctly set the
# environment for this host. Use it like this:
#
#   eval $(vagrant docker-env)

# TODO: DNS, not IP?

$DOCKER_ENV = {
  DOCKER_TLS_VERIFY: '',
  DOCKER_HOST: "tcp://#{$expose_docker_ip}:#{$expose_docker_tcp}"
}

if File.exist?(CONFIG)
  require CONFIG
end



# ============================================================================
# VAGRANT CONFIGURATION
#

VAGRANTFILE_API_VERSION = '2'
Vagrant.require_version '>= 1.6.5'


Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # always use Vagrants insecure key
  config.ssh.insert_key = false

  # ==========================================================================
  # VM CONFIGURATION
  #

  config.vm.box         = 'coreos-%s' % $update_channel
  config.vm.box_version = '>= 308.0.1'
  config.vm.box_url     = 'http://%s.release.core-os.net/amd64-usr/current/coreos_production_vagrant.json' % $update_channel

  config.vm.provider :vmware_fusion do |vb, override|
    override.vm.box_url = 'http://%s.release.core-os.net/amd64-usr/current/coreos_production_vagrant_vmware_fusion.json' % $update_channel
  end

  config.vm.provider :virtualbox do |v|
    # On VirtualBox, we don't have guest additions or a functional vboxsf
    # in CoreOS, so tell Vagrant that so it can be smarter.
    v.check_guest_additions = false
    v.functional_vboxsf     = false
  end

  # plugin conflict
  if Vagrant.has_plugin?('vagrant-vbguest') then
    config.vbguest.auto_update = false
  end


  # ==========================================================================
  # BOX CONFIGURATION
  #

  (1..1).each do |i|

    config.vm.define vm_name = 'core-%02d' % i do |config|

      config.vm.hostname = vm_name

      config.vm.provider :vmware_fusion do |vb|
        vb.gui = $vb_gui
      end

      config.vm.provider :virtualbox do |vb|
        vb.gui = $vb_gui
        vb.memory = $vb_memory
        vb.cpus = $vb_cpus
      end


      # ======================================================================
      # RANDOM COREOS STUFF
      #

      if $enable_serial_logging
        logdir = File.join(File.dirname(__FILE__), 'log')
        FileUtils.mkdir_p(logdir)

        serialFile = File.join(logdir, '%s-serial.txt' % vm_name)
        FileUtils.touch(serialFile)

        config.vm.provider :vmware_fusion do |v, override|
          v.vmx['serial0.present'] = 'TRUE'
          v.vmx['serial0.fileType'] = 'file'
          v.vmx['serial0.fileName'] = serialFile
          v.vmx['serial0.tryNoRxLoss'] = 'FALSE'
        end

        config.vm.provider :virtualbox do |vb, override|
          vb.customize ['modifyvm', :id, '--uart1', '0x3F8', '4']
          vb.customize ['modifyvm', :id, '--uartmode1', serialFile]
        end
      end

      if File.exist?(CLOUD_CONFIG_PATH)
        config.vm.provision :file,
          :source => "#{CLOUD_CONFIG_PATH}",
          :destination => '/tmp/vagrantfile-user-data'
        config.vm.provision :shell,
          :inline => 'mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/',
          :privileged => true

      end


      # ======================================================================
      # DOCKER INTEGRATION
      #

      # Networking

      if $expose_docker_tcp
        config.vm.network 'forwarded_port',
          guest: 2375,
          host: ($expose_docker_tcp + i - 1),
          auto_correct: true
      end

      config.vm.network :private_network, ip: $expose_docker_ip

      # Sync the project folder, keeping the same path.
      pwd = File.expand_path('..', __FILE__)
      config.vm.synced_folder pwd, pwd,
        id: 'core',
        nfs: true,
        mount_options: ['nolock,vers=3,udp']

      # Configure Docker on guest to listen for remote commands
      config.vm.provision :shell, inline: <<-BASH, privileged: true

        echo '[Unit]'                                >  /tmp/docker-tcp-socket
        echo 'Description=Docker Socket for the API' >> /tmp/docker-tcp-socket
        echo ''                                      >> /tmp/docker-tcp-socket
        echo '[Socket]'                              >> /tmp/docker-tcp-socket
        echo 'ListenStream=2375'                     >> /tmp/docker-tcp-socket
        echo 'BindIPv6Only=both'                     >> /tmp/docker-tcp-socket
        echo 'Service=docker.service'                >> /tmp/docker-tcp-socket
        echo ''                                      >> /tmp/docker-tcp-socket
        echo '[Install]'                             >> /tmp/docker-tcp-socket
        echo 'WantedBy=sockets.target'               >> /tmp/docker-tcp-socket

        mv /tmp/docker-tcp-socket /etc/systemd/system/docker-tcp.socket

        systemctl enable docker-tcp.socket
        systemctl stop docker
        systemctl start docker-tcp.socket
        systemctl start docker
      BASH

      # ======================================================================
      # DNS AUTOMATION
      #

      # This section is only relevant if you have dnsmasq installed and are
      # using it to automate *.dev domains. Since VMs have custom IPs, this can
      # be particularly helpful when you're running Docker containers that
      # expose particular ports.
      #
      # This requires `dnsmasq` to be present locally and reading custom hosts
      # from /tmp/hosts/*. Additionally, you'll want to add 127.0.0.1 to your
      # list of DNS servers in System Preferences.

      config.trigger.after :up do
        cmd = <<-BASH
          mkdir -p /tmp/hosts
          echo "#{$expose_docker_ip} #{$project_name}.dev" > "/tmp/hosts/#{$project_name}"
          sudo /usr/bin/killall -1 dnsmasq
        BASH
        run "bash -c '#{cmd}'"
      end

      config.trigger.before :halt do
        cmd = <<-BASH
          rm "/tmp/hosts/#{$project_name}"
          sudo /usr/bin/killall -1 dnsmasq
        BASH
        run "bash -c '#{cmd}'"
      end

    end
  end
end

