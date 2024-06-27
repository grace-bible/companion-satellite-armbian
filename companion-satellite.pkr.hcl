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

  provisioner "shell" {
    #system setup
    inline = [
      # # enable ssh
      # "touch /boot/ssh",

      # change the hostname
      "CURRENT_HOSTNAME=`cat /etc/hostname | tr -d \" \t\n\r\"`",
      "echo companion-satellite > /etc/hostname",
      "sed -i \"s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\tcompanion-satellite/g\" /etc/hosts",

      # install some dependencies
      "apt-get update -yq",
      "apt-mark hold openssh-server armbian-bsp-cli-orangepizero2 armbian-config armbian-firmware armbian-zsh",
      "apt-get upgrade -yq --option=Dpkg::Options::=--force-confdef",
      "apt-get install -o Dpkg::Options::=\"--force-confold\" -yqq git unzip curl pkg-config make gcc g++ libusb-1.0-0-dev libudev-dev cmake",
      "apt-get clean",
      "curl https://raw.githubusercontent.com/bitfocus/companion-satellite/main/pi-image/install.sh | bash"
    ]
  }
}
