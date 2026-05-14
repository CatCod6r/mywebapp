Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  config.vm.provider "virtualbox" do |v|
    v.name = "lab2-docker"
    v.memory = 2048
    v.cpus = 1
  end

  config.vm.disk :disk, size: "1GB", name: "vm-task"

  # Прокидаємо 80 порт з контейнера Nginx на 8080 порт вашого комп'ютера
  config.vm.network "forwarded_port", guest: 80, host: 8080

  config.vm.provision "shell", inline: <<-SHELL
    # Видаляємо стару папку, якщо вона є, щоб git clone не виводив помилку при перезапуску
    rm -rf mywebapp
    git clone https://github.com/CatCod6r/mywebapp.git
    cd mywebapp
    chmod +x ./setup.sh    
    sudo ./setup.sh
  SHELL

end
