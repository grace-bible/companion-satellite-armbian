packer {
  required_plugins {
    arm-image = {
      version = "0.2.7"
      source  = "github.com/solo-io/arm-image"
    }
  }
}

variable "branch" {
  type    = string
  default = "master"
}

variable "url" {
  type    = string
  default = "https://armbian.tnahosting.net/archive/orangepizero2/archive/Armbian_22.05.3_Orangepizero2_jammy_edge_5.17.11.img.xz"
}

source "arm-image" "satellitepi" {
  iso_checksum              = "none"
  iso_url                   = var.url
  target_image_size         = 4000000000
  output_filename           = "output-satellitepi/armbian-companion-satellite.img"
  qemu_binary               = "qemu-aarch64-static"
  image_mounts              = ["/"]
}

build {
  sources = ["source.arm-image.satellitepi"]

  provisioner "shell" {
    #system setup
    inline = [
      # # enable ssh
      # "touch /boot/ssh",

      # change the hostname
      "CURRENT_HOSTNAME=`cat /etc/hostname | tr -d \" \t\n\r\"`",
      "echo companion-satellite > /etc/hostname",
      "sed -i \"s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\tcompanion-satellite/g\" /etc/hosts",

      # add a system user
      "adduser --disabled-password satellite --gecos \"\"",

      # install some dependencies
      "apt-get update",
      "apt-get install -o Dpkg::Options::=\"--force-confold\" -yqq git unzip curl pkg-config make gcc g++ libusb-1.0-0-dev libudev-dev cmake",
      "apt-get clean",
    ]
  }

  provisioner "shell" {
    # run as root
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} su root -c {{ .Path }}"
    inline_shebang  = "/bin/bash -e"
    inline = [
      # install fnm to manage node version
      # we do this to /opt/fnm, so that the satellite user can use the same installation
      "export FNM_DIR=/opt/fnm",
      "echo \"export FNM_DIR=/opt/fnm\" >> /root/.bashrc",
      "curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir /opt/fnm",
      "export PATH=/opt/fnm:$PATH",
      "eval \"`fnm env --shell bash`\"",
      
			# clone the repository
      "git clone https://github.com/bitfocus/companion-satellite.git -b ${var.branch} /usr/local/src/companion-satellite",
      "cd /usr/local/src/companion-satellite",
      
			# configure git for future updates
      "git config --global pull.rebase false",
	    
      "mkdir /etc/udev/rules.d/",
      
			# run the update script
      "./pi-image/update.sh ${var.branch}",
      
			# enable start on boot
      "systemctl enable satellite",

			# copy config file into place
			"cp ./pi-image/satellite-config /boot/satellite-config"
    ]
  }

  provisioner "shell" {
    # run as satellite user
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} su satellite -c {{ .Path }}"
    inline_shebang  = "/bin/bash -e"
    inline = [
      "cd /usr/local/src/companion-satellite",

      # add the fnm node to this users path
      "echo \"export PATH=/opt/fnm/aliases/default/bin:\\$PATH\" >> ~/.bashrc"

    ]
  }

}
