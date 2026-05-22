## Whats in here

- `QA.md` - answers to the individual Q&A section
- `runbook.md` - the anti-drunk engineer runbook
- `terraform/` - terraform to stand up a VPC, firewall, instance template, health check, MIG, and global HTTP LB

## Resources used

| Resource | How I used it |
|---|---|
| PowerCerts How DNS Works (YouTube) | Watched to understand the recursive resolver chain and how lookups actually work |
| PowerCerts DNS Records Explained (YouTube) | Used to understand A, CNAME, MX, TXT records and when you use each one |
| PowerCerts Traceroute Explained (YouTube) | Helped me understand how TTL decrement works hop by hop |
| Cloudflare - What is DNS | Cross referenced the resolver chain, their diagrams helped |
| PowerCerts SSL TLS HTTP HTTPS Explained | Walked through the TLS handshake step by step |
| How SSL encryption works (article) | Used to understand certificate chains and CA trust model |
| GCP Docs - Target proxies overview | Needed to understand where SSL termination actually happens in GCP LB |
| GCP Docs - SSL Policies | Referenced for cipher suite and TLS version enforcement at the LB |
| GCP Docs - SSL certificates overview | Managed vs self-managed certs |
| GCP Blog - Deep dive into managed TLS certs | How GCP automates cert provisioning for HTTP(S) LBs |
| GCP Docs - Cloud DNS overview | Zones, record sets, how it all fits together |
| GCP Cloud DNS Full Course (YouTube) | Followed to understand wiring a custom domain to a GCP LB |
| GCP Docs - Certificate Manager overview | Newer cert management vs classic SSL certs |
| GCP Docs - Encryption from LB to backends | Used for the in-flight encryption question |
| Terraform google provider docs | Referenced heavily while writing the TF, specifically compute resources |

## Running the terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars and put in your project ID
terraform init
terraform plan
terraform apply
```

Note: after apply the LB takes a few minutes to become healthy. The `test_command` output will give you the curl command to verify it's working. If you get a 502 right after apply just wait a bit.

Requires terraform >= 1.5
