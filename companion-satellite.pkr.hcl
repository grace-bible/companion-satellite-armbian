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
  default = "http://xogium.performanceservers.nl/archive/orangepizero2/archive/Armbian_22.11.3_Orangepizero2_jammy_edge_6.1.4_minimal.img.xz"
}

source "arm-image" "satellitepi" {
  iso_checksum              = "sha256:3cd9574a6e7facd6fc37665a701dc079d0f05ed2ad22e6d0ed8919c224a7e00f"
  iso_url                   = var.url
  last_partition_extra_size = 2147483648
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
      "echo Current hostname: $CURRENT_HOSTNAME",
      "echo companion-satellite > /etc/hostname",
      "sed -i \"s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\tcompanion-satellite/g\" /etc/hosts",

      # add a system user
      "adduser --disabled-password satellite --gecos \"\"",

      # install some dependencies
      "apt-get update",
      "echo Apt repos updated",
      "apt-get install -o Dpkg::Options::=\"--force-confold\" -yqq git unzip curl pkg-config make gcc g++ libusb-1.0-0-dev libudev-dev cmake",
      "echo companion-satellite dependencies installed",
      "apt-get clean",
      "echo Apt cache cleaned",
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