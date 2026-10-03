resource "kubernetes_namespace" "metallb" {
  depends_on = [talos_cluster_kubeconfig.this]

  metadata {
    name = "metallb-system"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

resource "helm_release" "metallb" {
  depends_on = [kubernetes_namespace.metallb]

  name             = "metallb"
  repository       = "https://metallb.github.io/metallb"
  chart            = "metallb"
  version          = "0.15.2"
  namespace        = "metallb-system"
  create_namespace = false
  atomic           = true
}

resource "kubernetes_manifest" "metallb_ipaddresspool" {
  depends_on = [helm_release.metallb]

  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "IPAddressPool"
    metadata = {
      name      = "private-pool"
      namespace = "metallb-system"
    }
    spec = {
      addresses = [
        "10.10.10.80-10.10.10.99"
      ]
    }
  }
}

resource "kubernetes_manifest" "metallb_l2advertisement" {
  depends_on = [helm_release.metallb]

  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "L2Advertisement"
    metadata = {
      name      = "private"
      namespace = "metallb-system"
    }
    spec = {
      ipAddressPools = [
        "private-pool"
      ]
    }
  }
}
