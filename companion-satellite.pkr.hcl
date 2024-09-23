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

source "arm-image" "armbian" {
  iso_checksum              = "none"
  iso_url                   = var.url
  target_image_size         = 5000000000
  output_filename           = "output-satellitepi/armbian-companion-satellite.img"
  qemu_binary               = "qemu-aarch64-static"
  image_mounts              = ["/"]
  # needed on newer Armbian images for DNS to work for some reason, no resolv-conf option seems to work
  additional_chroot_mounts  = [["bind", "/run/systemd", "/run/systemd"]]
}

build {
  sources = ["source.arm-image.armbian"]

  provisioner "file" {
    source = "companion-satellite/pi-image/install.sh"
    destination = "/tmp/install.sh"
  }

  provisioner "shell" {
    #system setup
    inline = [
      # disable ssh
      # TODO: This doesn't work for some reason
      "sudo systemctl disable ssh",

      # Disable first-login script
      "rm /root/.not_logged_in_yet",

      # change the hostname
      "CURRENT_HOSTNAME=`cat /etc/hostname | tr -d \" \t\n\r\"`",
      "echo companion-satellite > /etc/hostname",
      "sed -i \"s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\tcompanion-satellite/g\" /etc/hosts",
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
