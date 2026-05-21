# Runbook: Broken GCP VM Recovery 
**Version:** 1.0
**Authors:** [group names]
**Date:** 2025

## Purpose

Use this when a GCP VM that should be serving HTTP traffic and/or accepting SSH connections suddenly stops doing one or both of those things. Written specifically after an incident where a VM was left in a broken state after some late night config changes.

---

## Prerequisites

- gcloud CLI configured and authenticated, or access to GCP Console
- Compute Admin and Network Admin roles on the project (or Owner/Editor)
- Know the VM name and project

---

## Phase 1 — Figure out what you're dealing with before touching anything

Resist the urge to start clicking things. First just gather info.

**1.1 Find the VM in the console**

Go to Compute Engine → VM Instances. Find it and write down:
- External IP (or whether it even has one)
- Zone
- Status — Running, Stopped, Terminated?
- What network/subnet its on
- What network tags are on it

**1.2 Check if the VM is actually running**

If it's stopped or terminated that's probably your first issue. Start it. If it's terminated the disk might be detached, check the Disks section.

**1.3 Actually try to connect to it**

```bash
# see if port 80 responds
curl -v http://<EXTERNAL_IP>

# try ssh
ssh <your_user>@<EXTERNAL_IP>
```

Write down what happens — don't just note "it doesn't work," write down the actual error:
- Connection timed out = something is blocking at the network level (firewall probably)
- Connection refused = port is closed or nothing is listening there
- "Network unreachable" = routing problem or no external IP

These errors point you in different directions so it matters.

---

## Phase 2 — Check firewall rules

This is the most common cause of sudden network inaccessibility so check here first.

**2.1 Look at existing firewall rules**

VPC Network → Firewall. You're looking for:
- Rules that allow TCP 22 (SSH) and TCP 80 (HTTP) inbound
- Check the **Action** — should be Allow
- Check **Direction** — should be Ingress
- Check **Source ranges** — needs `0.0.0.0/0` for public access
- Check **Priority** — lower number = higher priority. A DENY at priority 900 beats an ALLOW at 1000

Or with gcloud:
```bash
gcloud compute firewall-rules list --format="table(name,direction,priority,targetTags,allowed,sourceRanges,denied)"
```

**2.2 Check if the VM has the right network tags**

If firewall rules use target tags (they probably do), the VM needs to actually have those tags. Go to the VM → scroll down to Network Tags. Compare them to what the firewall rules are targeting.

If tags are missing add them:
```bash
gcloud compute instances add-tags <VM_NAME> --tags=<TAG> --zone=<ZONE>
```

This is a really easy thing for someone to accidentally mess up. The firewall rule can exist and look fine but if the VM doesn't have the matching tag the rule just doesn't apply to it.

**2.3 Check for deny rules**

Explicitly look for any DENY rules that could be overriding your allows. Someone might have added a deny-all at a lower priority number that's blocking everything.

---

## Phase 3 — Check if the web server is actually running

If firewall looks fine but HTTP still doesn't work, the service might just be down inside the VM.

**3.1 Get into the VM**

If SSH works, use that. If SSH is also broken, use the serial console:

Compute Engine → VM name → Connect → Connect to serial console

If serial console isn't enabled:
```bash
gcloud compute instances add-metadata <VM_NAME> --metadata serial-port-enable=TRUE --zone=<ZONE>
```

**3.2 Check the web server**

```bash
sudo systemctl status nginx
# if it's apache
sudo systemctl status apache2

# or just see what's listening on 80
sudo ss -tlnp | grep :80
```

If it's stopped:
```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

The `enable` is important — `start` just starts it now, `enable` makes it start on reboot. Easy thing to forget.

Check logs if it won't start:
```bash
sudo journalctl -u nginx -n 50
sudo tail -50 /var/log/nginx/error.log
```

**3.3 Check what address the webserver is listening on**

Sometimes nginx gets configured to only listen on 127.0.0.1 (localhost) instead of all interfaces. Check:

```bash
grep -r "listen" /etc/nginx/sites-enabled/
```

Should be `listen 80` or `listen 0.0.0.0:80`, NOT `listen 127.0.0.1:80`

---

## Phase 4 — SSH not working specifically

If HTTP works fine but SSH is the problem:

**4.1 Verify sshd is running and listening on the right address**

Via serial console:
```bash
sudo systemctl status sshd
sudo ss -tlnp | grep :22
```

**4.2 Check sshd config for anything weird**

```bash
sudo grep -E "Port|ListenAddress|PermitRootLogin|PasswordAuthentication" /etc/ssh/sshd_config
```

Things a person messing around might change:
- `ListenAddress 127.0.0.1` — this would completely break remote SSH, should be `0.0.0.0` or not set at all
- `Port 2222` — changed the port, need to connect with `-p 2222` and also open that port in firewall
- `PermitRootLogin no` — this shouldn't break normal user SSH but worth noting

After changing config:
```bash
sudo systemctl restart sshd
```

**4.3 Check SSH keys if using key auth**

```bash
# on the VM
cat ~/.ssh/authorized_keys
```

Make sure your public key is still in there.

---

## Phase 5 — Check the network more broadly

If everything inside the VM looks fine and firewall looks fine:

**5.1 Does the VM actually have an external IP?**

If the VM was stopped and restarted and had an ephemeral IP, that IP changed. Assign a static one if needed.

```bash
# reserve a static IP
gcloud compute addresses create my-static-ip --region=<REGION>
```

**5.2 Check routes**

```bash
gcloud compute routes list --project=<PROJECT_ID>
```

There should be a default route `0.0.0.0/0` pointing to the default internet gateway. If thats missing, external traffic won't work.

---

## Phase 6 — Validation checklist

After fixing whatever you found, verify everything:

```bash
# ssh works
ssh <user>@<EXTERNAL_IP>

# http returns something
curl -I http://<EXTERNAL_IP>
# expect: HTTP/1.1 200 OK

# web server running and will survive reboot
sudo systemctl is-active nginx
sudo systemctl is-enabled nginx
```

---

## Quick reference

| What you see | Where to look first |
|---|---|
| SSH times out | Firewall rule for port 22 / VM network tags |
| SSH refused | sshd not running or wrong ListenAddress |
| HTTP times out | Firewall rule for port 80 / VM network tags |
| HTTP refused | nginx/apache not running |
| Can't reach IP at all | VM stopped, missing external IP, or default route gone |
| Firewall looks right but still blocked | Double check target tags on the VM itself |
