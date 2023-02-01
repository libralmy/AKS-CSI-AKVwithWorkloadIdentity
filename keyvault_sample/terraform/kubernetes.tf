resource "kubernetes_service_account" "keyvault_client" {
  metadata {
    name      = var.kubernetes_service_account_name
    namespace = var.keyvault_client_namespace
    annotations = {
      "azure.workload.identity/client-id" = azurerm_user_assigned_identity.keyvault_client.client_id
    }
    labels = {
      "azure.workload.identity/use" : "true"
    }
  }
}

resource "kubernetes_namespace" "keyvault_client" {
  metadata {
    annotations = {
      name = var.keyvault_client_namespace
    }

    name = var.keyvault_client_namespace
  }
}


resource "kubectl_manifest" "secret_provider_class" {
  depends_on = [
    azurerm_federated_identity_credential.keyvault,
    data.azurerm_kubernetes_cluster.main
  ]
  # manifest = yamldecode(<<-EOF
  #             apiVersion: secrets-store.csi.x-k8s.io/v1
  #             kind: SecretProviderClass
  #             metadata:
  #               name: "${local.secret_provider_class_name}"  # needs to be unique per namespace
  #               namespace: "${var.keyvault_client_namespace}"
  #             spec:
  #               provider: azure
  #               secretObjects:                            # secretObjects defines the desired state of synced K8s secret objects
  #               - secretName: ingress-tls-csi
  #                 type: kubernetes.io/tls
  #                 data: 
  #                 - objectName: "${local.cert_name}"
  #                   key: tls.key
  #                 - objectName: "${local.cert_name}"
  #                   key: tls.crt
  #               parameters:
  #                 usePodIdentity: "false"
  #                 useVMManagedIdentity: "false"          
  #                 clientID: "${azurerm_user_assigned_identity.keyvault_client.client_id}" # Setting this to use workload identity
  #                 keyvaultName: "${var.keyvault_name}"       # Set to the name of your key vault
  #                 cloudName: ""                         # [OPTIONAL for Azure] if not provided, the Azure environment defaults to AzurePublicCloud
  #                 objects: |
  #                   array:
  #                     - |
  #                       objectName: "${local.cert_name}"
  #                       objectType: secret
  #                 tenantId: "${data.azurerm_client_config.current.tenant_id}"        # The tenant ID of the key vault
  #               EOF
  # )
   yaml_body  = templatefile("../keyvault_sample/templates/secret-provider-class.yaml", 
           {
                class_name = "azure-tls-keys"
                namespace_name = var.keyvault_client_namespace,
                key_vault_name = var.keyvault_name,
                cert_name      = local.cert_name,
                clientID = azurerm_user_assigned_identity.keyvault_client.client_id,
                tenant_id      = data.azurerm_client_config.current.tenant_id
           })

  # manifest = {
  #   apiVersion = "secrets-store.csi.x-k8s.io/v1"
  #   kind       = "SecretProviderClass"
  #   metadata = {
  #     namespace = var.keyvault_client_namespace
  #     name = local.secret_provider_class_name
  #   }

  #   spec = {
  #     provider = "azure"
  #     secretObjects = {
  #       secretName = "ingress-tls-csi"
  #       type = "kubernetes.io/tls"
  #       data = {
  #         objectName = "samplecert"
  #       }
  #     }
  #     parameters = {
  #       usePodIdentity = "false"
  #       useVMManagedIdentity = "false"     
  #       tenantID = data.azurerm_client_config.current.tenant_id
  #       clientID = azurerm_user_assigned_identity.keyvault_client.client_id
  #       keyvaultName = var.keyvault_name
  #       objects = <<EOF
  #         array:
  #           - |
  #             objectName: samplecert
  #             objectType: secret
  #       EOF
  #     }
  #   }
  # }
}

# Need a delay because federated identity credentials shouldn't be used right after creation (must wait a few seconds)
resource "time_sleep" "wait_20_seconds" {
  depends_on = [azurerm_federated_identity_credential.keyvault]
  create_duration = "20s"
}


resource "helm_release" "application" {
  depends_on = [
    azurerm_federated_identity_credential.keyvault,
    data.azurerm_kubernetes_cluster.main,
    kubectl_manifest.secret_provider_class
  ]
  name             = "ingress-nginx-app-1"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.2.1"
  namespace        = var.keyvault_client_namespace
  create_namespace = false
  verify           = false

  values = [
    templatefile("../keyvault_sample/templates/ingress-controller.yaml", {
      serviceaccount_name         = var.kubernetes_service_account_name
      secret_provider_class_name  = local.secret_provider_class_name
      ingress_class_name          = local.ingress_class_name
    })
  ]
 
}

# resource "kubernetes_deployment" "keyvault_client" {
#   depends_on = [
#     azurerm_key_vault_secret.main,
#     time_sleep.wait_20_seconds
#   ]

#   metadata {
#     name = "keyvault-client"
#     labels = {
#       "app" = "nginx"
#       "azure.workload.identity/use" = "true"
#     }
#     namespace = kubernetes_namespace.keyvault_client.id
#   }

#   spec {
#     replicas = 1

#     selector {
#       match_labels = {
#         app = "nginx"
#       }
#     }
    
#     template {
#       metadata {
#         labels = {
#           app = "nginx"
#         }
#       }

#       spec {
#         service_account_name = kubernetes_service_account.keyvault_client.metadata[0].name
#         container {
#           name = "main"
#           image = "nginx:latest"
#           image_pull_policy = "Always"
#           volume_mount {
#             mount_path = "mnt/secrets-store"
#             name = "secrets-mount"
#             read_only = true
#           }
#         }
#         volume {
#           name = "secrets-mount"
#           csi {
#             driver = "secrets-store.csi.k8s.io"
#             read_only = true
#             volume_attributes = {
#               secretProviderClass = local.secret_provider_class_name
#             }
#           }
#         }
#       }
#     }
#   }
# }
