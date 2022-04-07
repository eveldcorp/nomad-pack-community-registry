job [[ template "full_job_name" . ]] {

  region      = [[ .vector.region | quote ]]
  datacenters = [[ .vector.datacenters | toPrettyJson ]]
  namespace   = [[ .vector.namespace | quote ]]

  type        = "system"

  [[- if .vector.constraints ]]
  [[- range $idx, $constraint := .vector.constraints ]]
  constraint {
    attribute = [[ $constraint.attribute | quote ]]
    value     = [[ $constraint.value | quote ]]
    [[- if ne $constraint.operator "" ]]
    operator = [[ $constraint.operator | quote ]]
    [[- end ]]
  }
  [[- end ]]
  [[- end ]]

  group "vector" {

    network {
      mode = [[ .vector.network.mode | quote ]]
      [[- range $label, $to := .vector.network.ports ]]
        port [[ $label | quote ]] {
        to = [[ $to ]]
      }
      [[- end ]]
    }

    [[- if .vector.services ]]
    [[- $ports := .vector.network.ports ]]
    [[- range $idx, $service := .vector.services ]]
    service {
      name = [[ $service.service_name | quote ]]
      port = [[ index $ports $service.service_port_label | quote ]]
      tags = [[ $service.service_tags | toPrettyJson ]]

      [[- if $service.sidecar_enabled ]]
      connect {
        sidecar_service {
          proxy {
            [[- if $service.sidecar_upstreams]]
            [[- range $uidx, $upstream := $service.sidecar_upstreams ]]
            upstreams {
              destination_name = [[ $upstream.name | quote ]]
              local_bind_port  = [[ $upstream.port ]]
            }
            [[- end]]
            [[- end]]
          }
        }
      }
      [[- end ]]

      [[- if not $service.sidecar_enabled ]]
      check {
        type     = "http"
        path     = [[ $service.check_path | quote ]]
        interval = [[ $service.check_interval | quote ]]
        timeout  = [[ $service.check_timeout | quote ]]
      }
      [[- end ]]
    }
    [[- end ]]
    [[- end ]]

    [[- if .vector.volumes ]]
    [[- range $idx, $volume := .vector.volumes ]]
    volume "[[ $volume.name ]]" {
      type      = "[[ $volume.type ]]"
      source    = "[[ $volume.source ]]"
      read_only = [[ $volume.read_only ]]
    }
    [[- end ]]
    [[- end ]]

    task "vector" {
      driver = "docker"

      env {
        VECTOR_CONFIG          = "local/vector.toml"
        VECTOR_REQUIRE_HEALTHY = "true"
      }

      [[- if .vector.volume_mounts ]]
      [[- range $idx, $mount := .vector.volume_mounts ]]
      volume_mount {
        volume      = "[[ $mount.volume ]]"
        destination = "[[ $mount.destination ]]"
        read_only   = [[ $mount.read_only ]]
      }
      [[- end ]]
      [[- end ]]

      config {
        image = "timberio/vector:[[ .vector.image_version ]]"
      }

      resources {
        cpu    = [[ .vector.resources.cpu ]]
        memory = [[ .vector.resources.memory ]]
      }

      [[- if ne .vector.config_toml "" ]]
      template {
        data = <<EOH
[[ .vector.config_toml ]]
EOH
        left_delimiter = "(("
        right_delimiter = "))"
        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination = "local/vector.toml"
      }
      [[- end ]]
    }
  }
}
