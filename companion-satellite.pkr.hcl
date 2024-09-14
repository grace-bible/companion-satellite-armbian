packer {
  required_plugins {
    arm-image = {
      version = "0.2.7"
      source  = "github.com/solo-io/arm-image"
    }
  }
}

variable "url" {
  type    = string
  default = ""
}

variable "branch" {
  type    = string
  default = "stable"
}

variable "build" {
  type    = string
  default = "stable"
}

source "arm-image" "satellitepi" {
  iso_checksum              = "none"
  iso_url                   = var.url
  target_image_size         = 5000000000
  output_filename           = "output-satellitepi/armbian-companion-satellite.img"
  qemu_binary               = "qemu-aarch64-static"
  image_mounts              = ["/"]
}

build {
  sources = ["source.arm-image.satellitepi"]

  provisioner "file" {
    source = "companion-satellite/pi-image/install.sh"
    destination = "/tmp/install.sh"
  }

  provisioner "shell" {
    #system setup
    inline = [
      # # enable ssh
      # "touch /boot/ssh",

      # Disable first-login script
      "rm /root/.not_logged_in_yet",

      # change the hostname
      "CURRENT_HOSTNAME=`cat /etc/hostname | tr -d \" \t\n\r\"`",
      "echo companion-satellite > /etc/hostname",
      "sed -i \"s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\tcompanion-satellite/g\" /etc/hosts",

      # Some Armbian images don't have NTP installed by default, needed for apt
      "apt install ntp -yqq",
      "service ntp restart",
      "cat /etc/resolv.conf"
      "ping 8.8.8.8"

      # install some dependencies
      "apt-get update -yq",
      "apt-mark hold openssh-server armbian-bsp-cli-orangepizero2 armbian-config armbian-firmware armbian-zsh",
      "apt-get upgrade -yq --option=Dpkg::Options::=--force-confdef",
      "apt-get install -o Dpkg::Options::=\"--force-confold\" -yqq git unzip curl pkg-config make gcc g++ libusb-1.0-0-dev libudev-dev cmake",
      "apt-get clean",
    ]
  }

  provisioner "shell" {
    # run as root
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} su root -c {{ .Path }}"
    inline_shebang  = "/bin/bash -e"
    inline = [
      
			# run the script
      "export SATELLITE_BRANCH=${var.branch}",
      "export SATELLITE_BUILD=${var.build}",
      "echo $SATELLITE_BRANCH",
      "echo $SATELLITE_BUILD",
      "chmod +x /tmp/install.sh",
      "/tmp/install.sh"
    ]
  }

}
