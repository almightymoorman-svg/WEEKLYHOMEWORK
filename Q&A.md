# Q&A

## DNS and SSL/TLS

### Explain what the traceroute and dig commands do. Compare and contrast.

So these are both tools you use to debug network stuff but they do pretty different things.

**dig** is for querying DNS. You run it against a domain name and it goes out and asks DNS servers what records exist for that domain. So like if I run `dig google.com` it'll tell me the A record, which server answered, the TTL, etc. You can also tell it what type of record to look for — `dig google.com MX` will show you the mail records instead. Its useful when you want to see exactly what DNS is returning without your OS or browser doing any caching weirdness on top of it.

**traceroute** is different — it's about the actual network path packets take to get somewhere. Every time a packet goes through a router, that's a "hop." Traceroute shows you all those hops and how long each leg took. The way it works is it sends packets out with a TTL of 1, then 2, then 3 and so on. Each router drops the TTL by 1 and when it hits 0 it sends back a timeout message — thats how traceroute knows where each hop is. You end up with something like a map of the route.

So the main difference is dig is DNS layer (did the name resolve correctly) and traceroute is network layer (is the packet actually getting there). In practice if a site isn't loading you might use dig first to confirm the domain resolves to the right IP, and then traceroute to see if packets are actually reaching that IP or dying somewhere in between. They compliment eachother pretty well for troubleshooting.

---

### What are the 3 or 4 most common DNS records and what are their use cases?

**A record** - maps a hostname to an IPv4 address. This is the main one, basically every domain needs one. `example.com -> 93.184.216.34`

**CNAME** - an alias that points one hostname to another hostname instead of an IP. So `www.example.com` might CNAME to `example.com`. You also see this a lot with third party services — like if you use Shopify they give you a hostname to point your domain at. One gotcha is you can't use a CNAME on the apex/root domain (just `example.com` without anything in front), has to be on a subdomain.

**MX record** - this is specifically for email routing. It tells other mail servers where to deliver email for your domain. They also have a priority value so you can set up backup mail servers if your primary one goes down.

**TXT record** - kind of a catch-all. Originally it was just for storing text notes but now it gets used for a ton of verification stuff. SPF records live in TXT records, DKIM keys, and when you sign up for Google Search Console or similar services they have you add a TXT record to prove you own the domain.

There's also AAAA records (same as A record but for IPv6) which are becoming more common but I only listed the 4 most common ones.

---

### Give an overview of the steps in a TLS handshake.

The TLS handshake is the back-and-forth that happens before any real data gets sent. Its how the client and server agree on how to encrypt stuff.

1. **Client Hello** - client sends a message saying "here's the TLS versions I can support, here's the cipher suites I know, and here's a random number"

2. **Server Hello** - server picks a TLS version and cipher suite from the list and sends back its own random number plus its certificate

3. **Certificate check** - the client looks at the cert. Is it expired? Is the domain right? Is it signed by a CA I trust? If any of that fails the connection dies here

4. **Key exchange** - this is where both sides figure out the shared secret they'll use to encrypt everything. In TLS 1.3 this uses Diffie-Hellman where both sides can independently calculate the same secret without ever actually sending it over the wire. Kind of wild honestly

5. **Both sides derive session keys** - using the two random numbers from the hello messages plus the shared secret, both sides generate the same symmetric keys independently

6. **Finished** - both sides send a "finished" message encrypted with the new keys to confirm everything worked

After that actual traffic flows encrypted with symmetric keys (fast) even though the setup used asymmetric crypto (slower but necessary for the key exchange part).

---

### How does an SSL/TLS cert know what domain it belongs to?

The domain is literally written into the certificate. There's a field called the Subject Alternative Name (SAN) that lists exactly which domains the cert is valid for. It can have multiple domains in it, and it supports wildcards like `*.example.com` which would cover any subdomain.

There's also an older field called Common Name (CN) that was used before SAN became the standard — most modern stuff uses SAN now and some browsers actually ignore CN entirely.

When your browser connects to a site it checks whether the hostname it's connecting to matches what's in the cert's SAN field. If it doesn't match you get the scary "your connection is not private" warning. This is what stops someone from taking a valid cert for one domain and using it on a different one.

---

### What is a certificate authority?

A CA is basically a trusted third party that signs certificates. The reason your browser trusts a cert isn't because the server told you to — it's because a CA your browser already trusts signed it and vouched for it.

Your OS and browser come with a built in list of CAs they trust (DigiCert, Let's Encrypt, Sectigo, etc). When a site presents a cert, your browser checks if it was signed by one of those. If yes, trust chain established. If the cert was self-signed (the server signed its own cert with no CA involved), your browser throws a warning because there's no third party verification.

The trust actually goes through a chain — your server cert is signed by an intermediate CA, which is signed by a root CA. Browsers trust root CAs and work their way down the chain to verify everything checks out.

---

## Load Balancers

### How do application load balancers in GCP offload (decrypt) SSL? What part of the load balancer does this?

SSL termination on a GCP HTTP(S) load balancer happens at the **target HTTPS proxy**. Thats the component that actually holds the SSL cert and does the TLS handshake with clients connecting on port 443.

When a client hits the LB, the target proxy handles all the TLS negotiation, decrypts the traffic, then forwards it as plain HTTP back to the backend services (or you can configure it to re-encrypt if you need that). The backend VMs never deal with TLS at all — the proxy handles it.

This is the "offloading" part. Instead of every single VM needing to manage certificates and handle encryption, you centralize all of that at the proxy layer. Its also where SSL policies live — you can enforce minimum TLS versions and block weak cipher suites at the LB level rather than having to configure every backend separately.

---

### Are there use cases to have in flight encryption from the backend service to the backend itself?

Yeah there are definitely situations where you'd want that. A few:

**Compliance** - things like PCI-DSS or HIPAA sometimes require encryption in transit everywhere, even internal traffic. Doesn't matter that its inside your own network, the requirement is the requirement.

**Zero trust architecture** - if your security model assumes nothing inside the network is automatically safe, you encrypt everything. The idea is that if something gets compromised internally it can't just sniff unencrypted traffic laterally.

**Multi-tenant infrastructure** - if your workloads share physical hardware with other customers' stuff, encrypting internal traffic adds a layer even within GCP's network.

For most normal setups the traffic between the GCP LB and backends goes over Google's internal network which is pretty locked down, so plain HTTP to backends is usually fine. But having the option is important for regulated industries or high security environments.

---

## Cloud Domain/DNS

### Can multiple domains end up pointing to the same LB?

Yes. A GCP load balancer has one external IP, and you can have as many domains as you want with DNS records pointing at that same IP. Once traffic arrives at the LB, host-based routing rules in the URL map sort out where to send it based on the hostname in the request.

So `app1.com`, `app2.com`, and `dashboard.someotherdomain.io` could all resolve to the same LB IP. You'd set up routing rules to send each hostname to a different backend service. You'd also need certs that cover all those domains — either separate certs per domain or a multi-SAN cert.

This is a pretty common pattern when you want one LB fronting a bunch of different services or microservices.

---

### In the context of Cloud DNS, what are zones?

A zone is basically a container that holds all the DNS records for a specific domain. When you create a zone in Cloud DNS you tell it which domain it's responsible for, like `example.com`. Then inside that zone you create all your records — A records, CNAMEs, MX, whatever.

There are public zones (normal DNS that the whole internet can see) and private zones which only resolve inside your VPC. Private zones are useful for internal stuff like service discovery — you could have `db.internal` resolve to a private IP without that being visible to the public internet at all.

One zone per domain, all that domain's records live inside it.
