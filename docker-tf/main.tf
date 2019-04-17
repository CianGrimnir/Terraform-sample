provider "docker" {
	host="tcp://127.0.0.1:4243"
}

resource "docker_container" "javabuild" {
	image="${docker_image.java.latest}"
	name="foo"
}

resource "docker_container" "ubuntu_container" {
	image="${docker_image.ubuntu.latest}"
	name="bar"
	depends_on = ["docker_container.javabuild"]
	provisioner "local-exec" {
		command = "echo ${docker_container.javabuild.network_data.0.ip_address} > ip_address.txt"
	}
}

resource "docker_image" "ubuntu" {
	name="ubuntu:latest"
}

resource "docker_image" "java" {
	name="java:latest"
}
