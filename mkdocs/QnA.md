# Project 1 — Internal Documentation Platform (Meridian)

**Mentorship track:** Platform Engineering — building capability, not collecting tools.
**Status at end of session:** Full CI/CD pipeline designed and defended; Docker image built and verified; registry push proven. Deploy step assembled, pending live verification. Interview questions issued.

---

## 1. The problem (why this platform exists)

Meridian is a 40-person startup hiring 3–4 engineers/month. Knowledge is scattered (stale Google Docs, runbooks in one person's head, docs across Slack/Notion/READMEs). When the one person who knows something is out, deploys break and on-call is stuck.

**Brief:** build an internal docs platform — one place all engineering knowledge lives, reachable by everyone, that stays current and doesn't fall apart when one person is away.

The two hardest requirements, easy to miss: **stay current** and **survive one person being out**. Access and uptime are the easy half.

---

## 2. Architecture (end to end)

```
Engineer writes markdown → push to GitHub (main)
   → triggers GitHub Actions
      → job runs on SELF-HOSTED runner (same private network as server)
         → multi-stage Docker build (MkDocs builds markdown → static HTML, baked into image)
         → push image to SELF-HOSTED registry (separate box, tagged by commit SHA)
   → deploy job SSHes to server over the PRIVATE network
      → server pulls image → stops+removes old container → runs new one
   → engineers hit internal-only URL, nginx serves the static site
```

---

## 3. Decisions made and *why* (each one defended, not defaulted)

- **MkDocs** as the static site generator. Engineers write markdown; `mkdocs build` emits a `site/` folder of static HTML. Cheap, open-source, right for docs. Material theme config lives *inside* `mkdocs.yml` (no separate `theme.yml`).
- **Static site → nginx at runtime.** No Python/MkDocs needed at runtime; nginx just serves pre-built HTML from its default docroot `/usr/share/nginx/html/`. Zero nginx config needed for the basic case.
- **Bake HTML into the image, do NOT volume-mount it.** The image is the versioned, immutable artifact — "what's live" is answered by an image tag, not by mutable host disk state. Volumes are for data that must outlive/change independently of the container; docs are rebuilt every pipeline run, so they belong baked in.
- **Multi-stage Docker build.** Stage 1 (python:3.12-slim) installs the heavy MkDocs toolchain and builds. Stage 2 (nginx) copies only the finished `site/`. Final image stays lean — no build tools shipped to runtime, smaller attack surface, faster pulls.
- **Containers vs VMs:** a container shares the *host kernel* (isolated via namespaces + cgroups); it does NOT bundle its own OS. That's why they're tiny and start in ms. Rule isn't just "match amd64/arm64" — also need a compatible (Linux) kernel underneath.
- **Self-hosted runner** (not GitHub-hosted). Chosen for a *positive* reason: persistent Docker layer cache → faster builds/deploys. NOT because "no inbound forces it" — server has outbound, so pull-based deploy was available; self-hosted was a choice. Cost taken on: you now operate that runner (patching, disk hygiene, security; stale cache can rot).
- **Registry on a SEPARATE box** from the deploy server. Co-locating means one box death loses both the running site AND the images needed to rebuild it — reintroduces the single-point-of-failure the whole project fights. Principle: *the place you store recovery material must not share a fate with the thing it recovers.*
- **Self-hosted `registry:2`** for learning (full control, see every part). Caveat: you now own its TLS, auth, storage, backups. A managed free registry (ghcr.io) makes that someone else's problem — chose the educational path knowingly.
- **Registry needs TLS before push works** — Docker refuses plain HTTP by default. Not a "later polish"; it's blocking. (`insecure-registries` is a lab-only hack.)
- **Tag by commit SHA, not `latest`.** SHA makes every build permanently addressable → rollback = run the previous SHA. `latest` is a moving pointer, so "previous latest" is unrecoverable once overwritten.
- **Two jobs (build+push / deploy), not one.** Clean boundary: if build fails, deploy never runs (`needs:`). Consequence to handle: separate jobs are isolated worlds — values must be passed via `outputs:` + `$GITHUB_OUTPUT` + `needs.<job>.outputs.*`.
- **Push-over-SSH deploy.** Runner SSHes to server and runs docker commands remotely. Legitimate pattern for this scale. (Alternative: an agent that watches the registry — the seed of GitOps, deferred to Project 4.)
- **SSH key in GitHub Actions Secrets**, injected at runtime (write to file + `chmod 600`). Secrets are write-only from the UI and auto-masked in logs. Never the person who knows everyone's password. Note: on a persistent self-hosted runner the key file lingers on disk — consider cleanup or ssh-agent.
- **Same private network** for runner ↔ server means the deploy hop never touches the public internet — no inbound hole, nothing exposed. A choice made for cache locality also paid off in security.

---

## 4. Hard-won lessons / principles

- **Prove it, don't assume it.** A correct-looking Dockerfile/workflow is a hypothesis. Run `ls` inside the container, `curl` the registry catalog, deploy twice. The engineer who verifies is the one who isn't surprised at 2 AM.
- **"Which machine is this line running on?"** CI has several isolated execution contexts: build runner, deploy runner (separate world — nothing carries over), and inside the SSH session on the server. Most pipeline bugs are a value or command landing in the wrong world.
  - `$GITHUB_ENV` → persists to later *steps in the same job* as `$VAR`.
  - `$GITHUB_OUTPUT` → read as `${{ steps.<id>.outputs.<name> }}`, NOT as a shell var.
  - Job outputs cross to dependent jobs via `outputs:` + `needs.<job>.outputs.*`.
  - `$(...)` in an ssh string is evaluated by the *runner* before sending; escape it (`\$(...)`) to run on the server.
  - Unquoted `<< EOF` → runner expands `$VAR` before sending. Quoted `<< 'EOF'` → literal `$VAR` travels to the server and expands there.
- **Absolute paths across Docker stages.** `COPY --from` resolves from the stage's filesystem root, not your WORKDIR. Relative paths "work by luck" until they don't.
- **`docker run` flags go BEFORE the image name.** Anything after the image is the container's command, not a flag.
- **Idempotent deploy step:** `docker rm -f <name> || true` survives the first-ever run and reboots.
- **Engineering is magnitude, not just direction.** Spotting a cost (latency, wasted minutes) isn't the skill; *sizing* it for the actual workload is. A docs site deploying a few times/day doesn't care about a 9-second pull difference.
- **Pinning trade-off:** tag pin (`nginx:1.27-alpine`) can be repointed; digest pin (`nginx@sha256:...`) is immutable but opaque and silently misses security patches unless a bot (Dependabot/Renovate) bumps it. Hand-managed digest = stale-patch trap. Deferred to a later project.
- **Dead config/steps are liabilities.** Delete WORKDIR/steps that do nothing; the next engineer wastes time wondering what they're for.

---

## 5. Known limits of the Project 1 design (the motivation for Project 2)

- **Deploy has an unavoidable downtime window.** Stop-old-then-start-new on a single host, single port (`:80`) means a gap where nothing answers. You CANNOT start-new-first because the old container still holds `:80` (port conflict).
- **No rollback if the new image is broken** — the old container is already gone. Real deploys pull+verify new *before* killing old.
- **Zero-downtime is structurally impossible here.** Fix needs a **reverse proxy** (nginx-front / Traefik / Caddy): bring new container up on a fresh port, health-check it, atomically flip traffic, then kill old. That "bring up new → verify → switch → tear down old" IS what a Kubernetes rolling update automates.
- These pains are the intended, earned motivation for **Project 2: Kubernetes**.

---

## 6. Verified so far

- [x] Multi-stage image builds; `ls /usr/share/nginx/html/` shows `index.html`, `assets/`, page folders.
- [x] Image pushed to self-hosted registry; catalog shows `meridian:<sha>`.
- [ ] Site actually serves at `http://<server-ip>` (pull + run by hand).
- [ ] Second deploy (new commit) cleanly replaces the container on `:80`.

---

## 7. Interview questions (grounded in what was built)

### Beginner — fundamentals
1. What's the difference between a Docker image and a container?
2. Why does a multi-stage build produce a smaller final image than a single-stage one?
3. What does `EXPOSE 80` actually do — and not do?

### Intermediate — design reasoning
4. You tagged images by commit SHA instead of `latest`. Walk through a rollback with each. Why does SHA make rollback possible and `latest` doesn't?
5. Why does your registry run on a separate box from the deploy server? What specifically breaks if you co-locate them?
6. You chose a self-hosted runner over GitHub's hosted ones. Give the real reason — and the operational cost you took on.
7. Explain how a value gets from the build job into a command running on the deploy server. How many isolated "worlds" does it cross, and what mechanism bridges each?

### Senior — systems thinking
8. Your deploy stops the old container before starting the new one. Two separate things are wrong with that in production. Name both (one about users; one about what happens if the new image is broken).
9. Why is a truly zero-downtime deploy *structurally impossible* in the current single-host, single-port design? What component fixes it, and what does it do?
10. Your self-hosted runner sits inside the private network and holds a key that can deploy to your server. Describe the blast radius if it's compromised. Why is that a sharper risk than with an ephemeral hosted runner?

---

## 8. Next step

Answer the interview questions → mentor reviews them like a PR (which decisions you can *explain*, not just recite) → verify the deploy actually serves → **Project 2 (Kubernetes)** opens with a new business problem motivated by the single-host limits above.
