Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  config.vm.provider "virtualbox" do |v|
    v.name = "lab1"
    v.memory = 2048
    v.cpus = 1
  end

  # require VAGRANT_EXPERIMENTAL="disks"
  config.vm.disk :disk, size: "1GB", name: "vm-task"

  config.vm.provision "shell", inline: <<-SHELL
    git clone https://github.com/CatCod6r/mywebapp.git
    cd mywebapp
    chmod +x ./script.sh    
  SHELL

  config.trigger.after :up do |trigger|
    trigger.run_remote = { inline: "echo 'VM is up and running'" }
  end

end
