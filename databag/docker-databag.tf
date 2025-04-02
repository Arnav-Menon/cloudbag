terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    local = {
      source = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

variable "databag_admin_password" {
  type      = string
  #sensitive = true
}

# Clone the repository (if not already present and update if present)
resource "null_resource" "clone_databag" {
 provisioner "local-exec" {
    command = <<EOT
      #!/bin/bash
      set -e

      if [ ! -d "/opt/databag/.git" ]; then
        echo "Cloning Databag repository..."
        git clone https://github.com/balzack/databag.git /opt/databag
      else
        echo "Databag repository already exists, pulling latest changes..."
        cd /opt/databag && git pull
      fi
EOT
 }
}

# Pull the latest Databag image from Docker Hub
resource "null_resource" "pull_databag_image" {
 provisioner "local-exec" {
    command = "sudo docker pull balzack/databag:latest"
  }

  depends_on = [null_resource.clone_databag] # Ensure repo is cloned first
}

# Build and start the Databag containers
resource "null_resource" "build_and_start_databag" {
  triggers = {
    always_run = timestamp() # Remove this to use Docker caching
  }

  provisioner "local-exec" {
    working_dir = "/opt/databag"
    environment = {
      ADMIN_PASSWORD = var.databag_admin_password
    }
    command = <<EOT
      #!/bin/bash
      set -e

      sudo docker compose build
      sudo docker compose up -d
    EOT
  }

  depends_on = [null_resource.pull_databag_image]  # Ensure image is pulled before building
}