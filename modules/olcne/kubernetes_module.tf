# Copyright 2020, Oracle Corporation and/or affiliates.  
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

data "template_file" "create_kubernetes_module" {
  template = file("${path.module}/scripts/create_kubernetes_module.template.sh")

  vars = {
    environment            = var.olcne_environment.environment_name
    cluster_name           = var.olcne_environment.cluster_name
    container_registry     = lookup(var.container_registry_urls, var.region)
    master_vip             = var.olcne_masters.primary_master_vip
    master_nodes_addresses = join(",", sort(local.master_nodes_addresses))
    worker_nodes_addresses = join(",", sort(local.worker_nodes_addresses))
  }
}

resource null_resource "create_kubernetes_module" {
  connection {
    host        = local.operator_private_ip
    private_key = file(var.ssh_private_key_path)
    timeout     = "40m"
    type        = "ssh"
    user        = "opc"

    bastion_host        = var.bastion_public_ip
    bastion_user        = "opc"
    bastion_private_key = file(var.ssh_private_key_path)
  }

  depends_on = [null_resource.create_environment]

  provisioner "file" {
    content     = data.template_file.create_kubernetes_module.rendered
    destination = "~/create_kubernetes_module.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x $HOME/create_kubernetes_module.sh",
      "$HOME/create_kubernetes_module.sh",
    ]
  }
}

data "template_file" "install_kubernetes_module" {
  template = file("${path.module}/scripts/install_kubernetes_module.template.sh")

  vars = {
    environment  = var.olcne_environment.environment_name
    cluster_name = var.olcne_environment.cluster_name
  }
}

resource null_resource "install_kubernetes_module" {
  connection {
    host        = local.operator_private_ip
    private_key = file(var.ssh_private_key_path)
    timeout     = "40m"
    type        = "ssh"
    user        = "opc"

    bastion_host        = var.bastion_public_ip
    bastion_user        = "opc"
    bastion_private_key = file(var.ssh_private_key_path)
  }

  depends_on = [null_resource.create_kubernetes_module]

  provisioner "file" {
    content     = data.template_file.install_kubernetes_module.rendered
    destination = "~/install_kubernetes_module.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x $HOME/install_kubernetes_module.sh",
      "$HOME/install_kubernetes_module.sh",
    ]
  }
}
