variable "job_name" {
  description = "The name to use as the job name which overrides using the pack name."
  type        = string
  default     = ""
}

variable "datacenters" {
  description = "A list of datacenters in the region which are eligible for job placement."
  type        = list(string)
  default     = ["dc1"]
}

variable "region" {
  description = "The region where the job should be placed."
  type        = string
  default     = "global"
}

variable "namespace" {
  description = "The namespace where the job should be placed."
  type        = string
  default     = "default"
}

variable "constraints" {
  description = "Constraints to apply to the entire job."
  type = list(object({
    attribute = string
    operator  = string
    value     = string
  }))
  default = [
    {
      attribute = "$${attr.kernel.name}",
      value     = "linux",
      operator  = "",
    },
  ]
}

variable "network" {
  description = "The Vector network configuration options."
  type = object({
    mode  = string
    ports = map(number)
  })
  default = {
    mode = "bridge",
    ports = {
      "http" = 8686,
    },
  }
}

variable "config_toml" {
  description = "The Vector configuration to pass to the task."
  type        = string
  default     = <<EOF
  data_dir = "alloc/data/vector/"
  [api]
    enabled = true
    address = "0.0.0.0:8686"
    playground = false
  [sources.logs]
    type = "docker_logs"
  [sinks.loki]
    type = "loki"
    inputs = [ "logs" ]
    endpoint = "http://localhost:3100"
    encoding.codec = "json"
    healthcheck.enabled = true
    labels.job = "{{ label.com\\.hashicorp\\.nomad\\.job_name }}"
    labels.task = "{{ label.com\\.hashicorp\\.nomad\\.task_name }}"
    labels.group = "{{ label.com\\.hashicorp\\.nomad\\.task_group_name }}"
    labels.namespace = "{{ label.com\\.hashicorp\\.nomad\\.namespace }}"
    labels.node = "{{ label.com\\.hashicorp\\.nomad\\.node_name }}"
    remove_label_fields = true
EOF
}

variable "volumes" {
  type = list(object({
    name      = string
    type      = string
    source    = string
    read_only = bool
  }))
  default = [{
    name      = "docker-sock"
    type      = "host"
    source    = "docker-sock-ro"
    read_only = true
  }]
}

variable "volume_mounts" {
  type = list(object({
    volume      = string
    destination = string
    read_only   = bool
  }))
  default = [{
    volume      = "docker-sock"
    destination = "/var/run/docker.sock"
    read_only   = true
  }]
}

variable "image_version" {
  description = "The version of the Vector image to use."
  type        = string
  default     = "0.14.X-alpine"
}

variable "resources" {
  description = "The resource to assign to the Vector task."
  type = object({
    cpu    = number
    memory = number
  })
  default = {
    cpu    = 500,
    memory = 256,
  }
}

variable "services" {
  description = "Configuration options of the Vector services and checks."
  type = list(object({
    service_port_label = string
    service_name       = string
    service_tags       = list(string)
    sidecar_enabled    = bool
    sidecar_upstreams = list(object({
      name = string
      port = number
    }))
    check_enabled  = bool
    check_path     = string
    check_interval = string
    check_timeout  = string
  }))
  default = [{
    service_port_label = "http",
    service_name       = "vector",
    service_tags       = [],
    sidecar_enabled    = true
    sidecar_upstreams = [{
      name = "loki"
      port = 3100
    }]
    check_enabled  = true,
    check_path     = "/health",
    check_interval = "3s",
    check_timeout  = "1s",
  }]
}