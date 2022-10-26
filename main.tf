locals {
  size = {
    small = {
      cpu     = "250m"
      memory  = "250Mi"
    },
    medium = {
      cpu     = "500m"
      memory  = "500Mi"
    }
    large = {
      cpu     = "1"
      memory  = "1Gi"
    }
  }
}

resource "kubernetes_namespace" "comun" {
  metadata {
    name = var.entity
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_persistent_volume_claim" "jenkinsmaster" {
  metadata {
    name      = var.servername
    namespace = var.entity

    labels = {
      "app.kubernetes.io/component"  = "jenkins-controller"
      "app.kubernetes.io/instance"   = var.servername
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/name"       = "jenkins"
      "em.terraform.module/module"   = "jenkins-1.0.0"
    }

  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "8Gi"
      }
    }
    storage_class_name = "ceph-block-prod"
  }
}

resource "kubernetes_secret" "jenkinsmaster" {
  metadata {
    namespace = var.entity
    name      = var.servername

    labels = {
      "app.kubernetes.io/component"  = "jenkins-controller"
      "app.kubernetes.io/instance"   = var.servername
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/name"       = "jenkins"
      "em.terraform.module/module"   = "jenkins-1.0.0"
    }
  }


  data = {
    "jenkins-admin-password" = random_password.password.result
    "jenkins-admin-user"     = "admin"
  }
}

resource "kubernetes_service_account" "jenkinsmaster" {
  metadata {
    name      = var.servername
    namespace = var.entity

    labels = {
      "app.kubernetes.io/component"  = "jenkins-controller"
      "app.kubernetes.io/instance"   = var.servername
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/name"       = "jenkins"
      "em.terraform.module/module"   = "jenkins-1.0.0"
    }
  }

  secret {
    name = kubernetes_secret.jenkinsmaster.metadata[0].name
  }
}

resource "kubernetes_config_map" "jenkinsmaster" {
  metadata {
    name      = var.servername
    namespace = var.entity

    labels = {
      "app.kubernetes.io/component"  = "jenkins-controller"
      "app.kubernetes.io/instance"   = var.servername
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/name"       = "jenkins"
      "em.terraform.module/module"   = "jenkins-1.0.0"
    }
  }

  data = {
    "apply_config.sh" = "set -e\necho \"disable Setup Wizard\"\n# Prevent Setup Wizard when JCasC is enabled\necho $JENKINS_VERSION > /var/jenkins_home/jenkins.install.UpgradeWizard.state\necho $JENKINS_VERSION > /var/jenkins_home/jenkins.install.InstallUtil.lastExecVersion\necho \"download plugins\"\n# Install missing plugins\ncp /var/jenkins_config/plugins.txt /var/jenkins_home;\nrm -rf /usr/share/jenkins/ref/plugins/*.lock\nversion () { echo \"$@\" | awk -F. '{ printf(\"%d%03d%03d%03d\\n\", $1,$2,$3,$4); }'; }\nif [ -f \"/usr/share/jenkins/jenkins.war\" ] && [ -n \"$(command -v jenkins-plugin-cli)\" 2>/dev/null ] && [ $(version $(jenkins-plugin-cli --version)) -ge $(version \"2.1.1\") ]; then\n  jenkins-plugin-cli --verbose --war \"/usr/share/jenkins/jenkins.war\" --plugin-file \"/var/jenkins_home/plugins.txt\" --latest true;\nelse\n  /usr/local/bin/install-plugins.sh `echo $(cat /var/jenkins_home/plugins.txt)`;\nfi\necho \"copy plugins to shared volume\"\n# Copy plugins to shared volume\nyes n | cp -i /usr/share/jenkins/ref/plugins/* /var/jenkins_plugins/;\necho \"finished initialization\""
    "plugins.txt"     = "kubernetes:3706.vdfb_d599579f3\nworkflow-aggregator:590.v6a_d052e5a_a_b_5\ngit:4.11.5\nconfiguration-as-code:1512.vb_79d418d5fc8"
  }
}

resource "kubernetes_stateful_set" "jenkinsmaster" {
  metadata {
    name      = var.servername
    namespace = var.entity

    labels = {
      "app.kubernetes.io/component"  = "jenkins-controller"
      "app.kubernetes.io/instance"   = var.servername
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/name"       = "jenkins"
      "em.terraform.module/module"   = "jenkins-1.0.0"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/component" = "jenkins-controller"
        "app.kubernetes.io/instance"  = var.servername
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/component"  = "jenkins-controller"
          "app.kubernetes.io/instance"   = var.servername
          "app.kubernetes.io/managed-by" = "terraform"
          "app.kubernetes.io/name"       = "jenkins"
        }
      }

      spec {
        volume {
          name = "plugins"
          empty_dir {}
        }

        volume {
          name = "jenkins-config"

          config_map {
            name         = kubernetes_config_map.jenkinsmaster.metadata[0].name
            default_mode = "0644"
          }
        }

        volume {
          name = "plugin-dir"
          empty_dir {}
        }

        volume {
          name = "jenkins-secrets"

          projected {
            sources {
              secret {
                name = var.servername

                items {
                  key  = "jenkins-admin-user"
                  path = "chart-admin-username"
                }

                items {
                  key  = "jenkins-admin-password"
                  path = "chart-admin-password"
                }
              }
            }

            default_mode = "0644"
          }
        }

        volume {
          name = "jenkins-cache"
          empty_dir {}
        }

        volume {
          name = "jenkins-home"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.jenkinsmaster.metadata[0].name
          }
        }

        volume {
          name = "sc-config-volume"
          empty_dir {}
        }

        volume {
          name = "tmp-volume"
          empty_dir {}
        }

        init_container {
          name    = "init"
          image   = "jenkins/jenkins:2.361.2-jdk11"
          command = ["sh", "/var/jenkins_config/apply_config.sh"]

          resources {
            limits = {
              cpu    = local.size[var.size].cpu
              memory = local.size[var.size].memory
            }

            requests = {
              cpu    = local.size[var.size].cpu
              memory = local.size[var.size].cpu
            }
          }

          volume_mount {
            name       = "jenkins-home"
            mount_path = "/var/jenkins_home"
          }

          volume_mount {
            name       = "jenkins-config"
            mount_path = "/var/jenkins_config"
          }

          volume_mount {
            name       = "plugins"
            mount_path = "/usr/share/jenkins/ref/plugins"
          }

          volume_mount {
            name       = "plugin-dir"
            mount_path = "/var/jenkins_plugins"
          }

          volume_mount {
            name       = "tmp-volume"
            mount_path = "/tmp"
          }

          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          image_pull_policy          = "Always"

          security_context {
            run_as_user               = 1000
            run_as_group              = 1000
            read_only_root_filesystem = true
          }
        }

        container {
          name  = "jenkins"
          image = "jenkins/jenkins:2.361.2-jdk11"
          args  = ["--httpPort=8080"]

          port {
            name           = "http"
            container_port = 8080
            protocol       = "TCP"
          }

          port {
            name           = "agent-listener"
            container_port = 50000
            protocol       = "TCP"
          }

          env {
            name  = "SECRETS"
            value = "/run/secrets/additional"
          }

          env {
            name = "POD_NAME"

            value_from {
              field_ref {
                api_version = "v1"
                field_path  = "metadata.name"
              }
            }
          }

          env {
            name  = "JAVA_OPTS"
            value = "-Dcasc.reload.token=$(POD_NAME) "
          }

          env {
            name  = "JENKINS_OPTS"
            value = "--webroot=/var/jenkins_cache/war "
          }

          env {
            name  = "JENKINS_SLAVE_AGENT_PORT"
            value = "50000"
          }

          env {
            name  = "CASC_JENKINS_CONFIG"
            value = "/var/jenkins_home/casc_configs"
          }

          resources {
            limits = {
              cpu    = local.size[var.size].cpu
              memory = local.size[var.size].memory
            }

            requests = {
              cpu    = local.size[var.size].cpu
              memory = local.size[var.size].memory
            }
          }

          volume_mount {
            name       = "jenkins-home"
            mount_path = "/var/jenkins_home"
          }

          volume_mount {
            name       = "jenkins-config"
            read_only  = true
            mount_path = "/var/jenkins_config"
          }

          volume_mount {
            name       = "plugin-dir"
            mount_path = "/usr/share/jenkins/ref/plugins/"
          }

          volume_mount {
            name       = "sc-config-volume"
            mount_path = "/var/jenkins_home/casc_configs"
          }

          volume_mount {
            name       = "jenkins-secrets"
            read_only  = true
            mount_path = "/run/secrets/additional"
          }

          volume_mount {
            name       = "jenkins-cache"
            mount_path = "/var/jenkins_cache"
          }

          volume_mount {
            name       = "tmp-volume"
            mount_path = "/tmp"
          }

          liveness_probe {
            http_get {
              path   = "/login"
              port   = "http"
              scheme = "HTTP"
            }

            timeout_seconds   = 5
            period_seconds    = 10
            success_threshold = 1
            failure_threshold = 5
          }

          readiness_probe {
            http_get {
              path   = "/login"
              port   = "http"
              scheme = "HTTP"
            }

            timeout_seconds   = 5
            period_seconds    = 10
            success_threshold = 1
            failure_threshold = 3
          }

          startup_probe {
            http_get {
              path   = "/login"
              port   = "http"
              scheme = "HTTP"
            }

            timeout_seconds   = 5
            period_seconds    = 10
            success_threshold = 1
            failure_threshold = 12
          }

          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          image_pull_policy          = "Always"

          security_context {
            run_as_user               = 1000
            run_as_group              = 1000
            read_only_root_filesystem = true
          }
        }

        container {
          name  = "config-reload"
          image = "kiwigrid/k8s-sidecar:1.15.0"

          env {
            name = "POD_NAME"

            value_from {
              field_ref {
                api_version = "v1"
                field_path  = "metadata.name"
              }
            }
          }

          env {
            name  = "LABEL"
            value = "jenkinsmaster-jenkins-config"
          }

          env {
            name  = "FOLDER"
            value = "/var/jenkins_home/casc_configs"
          }

          env {
            name  = "NAMESPACE"
            value = "cicd"
          }

          env {
            name  = "REQ_URL"
            value = "http://localhost:8080/reload-configuration-as-code/?casc-reload-token=$(POD_NAME)"
          }

          env {
            name  = "REQ_METHOD"
            value = "POST"
          }

          env {
            name  = "REQ_RETRY_CONNECT"
            value = "10"
          }

          volume_mount {
            name       = "sc-config-volume"
            mount_path = "/var/jenkins_home/casc_configs"
          }

          volume_mount {
            name       = "jenkins-home"
            mount_path = "/var/jenkins_home"
          }

          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          image_pull_policy          = "IfNotPresent"

          security_context {
            read_only_root_filesystem = true
          }
        }

        restart_policy                   = "Always"
        termination_grace_period_seconds = 30
        dns_policy                       = "ClusterFirst"
        service_account_name             = kubernetes_service_account.jenkinsmaster.metadata[0].name

        security_context {
          run_as_user     = 1000
          run_as_non_root = true
          fs_group        = 1000
        }
      }
    }

    service_name          = var.servername
    pod_management_policy = "OrderedReady"

    update_strategy {
      type = "RollingUpdate"
    }
  }

  depends_on = [kubernetes_service_account.jenkinsmaster]
}

resource "random_password" "password" {
  length  = 16
  special = false
}

resource "kubernetes_service" "jenkinsmaster" {
  metadata {
    name      = var.servername
    namespace = var.entity

    labels = {
      "app.kubernetes.io/component"  = "jenkins-controller"
      "app.kubernetes.io/instance"   = var.servername
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/name"       = "jenkins"
      "em.terraform.module/module"   = "jenkins-1.0.0"
    }
  }

  spec {
    port {
      name        = "http"
      protocol    = "TCP"
      port        = 8080
      target_port = "8080"
    }

    selector = {
      "app.kubernetes.io/component" = "jenkins-controller"
      "app.kubernetes.io/instance"  = var.servername
    }

    type = "LoadBalancer"
  }
}

output "pod_size" {
  value       = local.size[var.size].cpu
  description = "Size Sample"
}