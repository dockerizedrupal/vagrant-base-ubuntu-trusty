VERSION = "0.4.8"

require 'yaml'

required_plugins = %w(vagrant-vbguest)

required_plugins.each do |plugin|
  system "vagrant plugin install #{plugin}" unless Vagrant.has_plugin? plugin
end

vm_config = YAML.load_file("config.yml")

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.hostname = vm_config["server_name"]

  config.vm.network "private_network", ip: vm_config["ip_address"]

  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder ".", "/var/www"

  config.vm.synced_folder File.expand_path("system32/drivers/", ENV["windir"]), "/winhost"

  config.vm.provider "virtualbox" do |v|
    name = "dockerizedrupal-base-ubuntu-trusty-" + VERSION

    name.gsub!(".", "-")

    v.name = name
    v.cpus = vm_config["cpus"]
    v.memory = vm_config["memory_size"]
  end

  config.vm.provision "shell", inline: "initctl emit vagrant-ready", run: "always"

  config.vm.provision "shell" do |s|
    s.inline = <<-SHELL
      MEMORY_SIZE="${1}"
      SERVER_NAME="${2}"
      IP_ADDRESS="${3}"

      swap_create() {
        local memory_size="${1}"
        local swap_size=$((${memory_size}*2))

        swapoff -a

        fallocate -l "${swap_size}m" /swapfile

        chmod 600 /swapfile

        mkswap /swapfile
        swapon /swapfile

        echo "/swapfile none swap sw 0 0" >> /etc/fstab

        sysctl vm.swappiness=10
        echo "vm.swappiness=10" >> /etc/sysctl.conf

        sysctl vm.vfs_cache_pressure=50
        echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
      }

      updater_install() {
        curl -L https://raw.githubusercontent.com/dockerizedrupal/updater/master/updater.sh > /usr/local/bin/updater

        chmod +x /usr/local/bin/updater

        updater

        sed -i "s/^start on (filesystem and net-device-up IFACE!=lo)/start on vagrant-ready/" /etc/init/docker.conf

        usermod -aG docker vagrant
      }

      vhost_install() {
        local server_name="${1}"
        local tmp="$(mktemp -d)"

        git clone https://github.com/dockerizedrupal/vhost.git "${tmp}"

        cd "${tmp}"

        git checkout 1.1.8

        cp ./docker-compose.yml /opt/vhost.yml

        sed -i "s/SERVER_NAME=localhost/SERVER_NAME=${server_name}/" /opt/vhost.yml
        sed -i "s/HOSTS_IP_ADDRESS=127.0.0.1/HOSTS_IP_ADDRESS=${IP_ADDRESS}/" /opt/vhost.yml
        sed -i "s|/etc/hosts|/winhost/etc/hosts|" /opt/vhost.yml

        docker-compose -f /opt/vhost.yml up -d
      }

      nodejs_install() {
        curl -sL https://deb.nodesource.com/setup_4.x | bash -

        apt-get install -y nodejs
      }

      grunt_install() {
        npm install -g grunt-cli
      }

      bats_install() {
        local tmp="$(mktemp -d)"

        git clone https://github.com/sstephenson/bats.git "${tmp}"

        cd "${tmp}"

        ./install.sh /usr/local
      }

      mysql_client_install() {
        apt-get install -y mysql-client
      }

      swap_create "${MEMORY_SIZE}"
      updater_install
      vhost_install "${SERVER_NAME}"
      nodejs_install
      grunt_install
      bats_install
      mysql_client_install
    SHELL

    s.args = [
      vm_config["memory_size"],
      vm_config["server_name"],
      vm_config["ip_address"],
    ]
  end
end
