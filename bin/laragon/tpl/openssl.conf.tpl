[req]
default_bits       = 2048
default_md         = sha256
distinguished_name = req_distinguished_name
req_extensions     = v3_req
prompt            = no

[req_distinguished_name]
C  = SG
ST = Singapore
L  = Singapore
O  = Laragon
OU = Server
CN = laragon

[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
IP.1  = 127.0.0.1

# You can another DNS below. For example:
# DNS.2 = xxx
# DNS.3 = yyy
