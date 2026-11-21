# Manual deployment procedure

Used as the "Manual" baseline in the capstone experiments.
Every run must follow these steps exactly, in this order.

## Preconditions
- `capstone-app` working tree is clean (`git status`)
- Logged in to GHCR (`docker login ghcr.io`)
- `app-manual` namespace is healthy (`kubectl get pods -n app-manual`)

## Steps

1. **Build**
   ```bash
   cd ~/capstone/capstone-app
   docker build -t ghcr.io/inesmo-minyard/capstone-app:<VERSION> \
     --build-arg APP_VERSION=<VERSION> \
     --label org.opencontainers.image.revision=$(git rev-parse HEAD) .
   ```
2. **Push**
   ```bash
   docker push ghcr.io/inesmo-minyard/capstone-app:<VERSION>
   ```
3. **Edit manifest**: set `image:` to `<VERSION>` in `~/capstone/k8s-manual/deployment.yaml`
4. **Apply**
   ```bash
   kubectl apply -f ~/capstone/k8s-manual/deployment.yaml
   ```
5. **Wait until ready** (measured automatically by the timer script)
6. **Record**
   ```bash
   cd ~/capstone/k8s-manual
   git commit -am "Deploy <VERSION>"
   git push
   ```

## Definition of done
`kubectl rollout status` succeeds **and** the Service returns the new version.
