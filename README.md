# wg-easy Helm chart

Deploys [wg-easy](https://github.com/wg-easy/wg-easy) v15 (WireGuard + web admin UI).

## Install

```sh
helm lint ./wg-easy
helm upgrade --install wg-easy ./wg-easy -n wg-easy --create-namespace -f my-values.yaml
```

## Minimal values for a bare-metal cluster with MetalLB

```yaml
image:
  tag: "15.5.0"            # pin; bump by hand

service:
  wireguard:
    type: LoadBalancer
    loadBalancerIP: 192.168.1.7   # or a MetalLB annotation

init:
  enabled: true
  host: vpn.example.com     # public name/IP clients dial
  existingSecret: wg-easy-admin     # keys: username, password

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: wg.example.com
      paths: [{ path: /, pathType: Prefix }]
  tls:
    - secretName: wg-easy-tls
      hosts: [wg.example.com]
```

Create the admin Secret outside Git:

```sh
kubectl -n wg-easy create secret generic wg-easy-admin \
  --from-literal=username=admin --from-literal=password='change-me'
```

## Notes

- **Single replica, `Recreate`.** State (keys, clients, SQLite DB) lives in `/etc/wireguard` on the PVC.
  The PVC carries `helm.sh/resource-policy: keep`, so uninstalling does not delete your VPN.
- **Sysctls.** WireGuard needs `net.ipv4.ip_forward=1` and `net.ipv4.conf.all.src_valid_mark=1`.
  Kubernetes treats these as unsafe sysctls, so the default `sysctls.mode: initContainer` sets them
  from a privileged busybox init container in the pod's network namespace. If your kubelets run with
  `--allowed-unsafe-sysctls=net.ipv4.ip_forward,net.ipv4.conf.all.src_valid_mark`, use
  `sysctls.mode: securityContext` and drop the privileged container.
- **Pod Security Admission.** The pod needs `NET_ADMIN`, `SYS_MODULE`, a hostPath and (by default) a
  privileged init container, so label the namespace
  `pod-security.kubernetes.io/enforce=privileged` if PSA is enforced.
- **Unattended setup** (`init.*`) only runs on the very first start with an empty volume.
  After that, configuration lives in the web UI; changing `init.*` later has no effect.
- **Port.** `wireguard.port` is both the port wg-easy listens on and the port it tells clients to use.
  If you change the port in the UI, change it here too.
- **HTTPS.** v15 refuses logins over plain HTTP unless `INSECURE=true`. The chart sets
  `web.insecure: true` by default because TLS is expected to end at the Ingress
  (or you use `kubectl port-forward`). Don't expose the web Service directly without TLS.
- **IPv6** is off by default (`disableIPv6: true`) because most clusters have no pod IPv6.
