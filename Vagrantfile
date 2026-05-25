Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  config.vm.provider "virtualbox" do |v|
    v.name = "lab3"
    v.memory = 2048
    v.cpus = 1
  end

  config.vm.disk :disk, size: "1GB", name: "vm-task"

  # Прокидаємо 80 порт з контейнера Nginx на 8080 порт вашого комп'ютера
  config.vm.network "forwarded_port", guest: 80, host: 8080

  config.vm.provision "shell", inline: <<-SHELL
  SHELL

end
