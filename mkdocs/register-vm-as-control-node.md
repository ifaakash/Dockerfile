## Install tailscale
1. Install tailscale on VM
```bash
curl -fsSL https://tailscale.com/install.sh | sh
```
2. Register the VM
```bash
sudo tailscale up
```

3. Copy the login URL shown in the terminal, open it in your browser, and authenticate.


## Register the VM as managed node

1. Get the node token from control plane 
```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

2. Note the server( control node ) endpoint
```bash
https://<server-ip>:6443
```

3. Run the below command on VM that need to be joined as managed node
```bash
curl -sfL https://get.k3s.io | K3S_URL=https://<server-ip>:6443 K3S_TOKEN=<node-token> sh -
```

4. Verify on the control node
```bash
kubectl get nodes
```
