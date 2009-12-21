 # Convert PEM to PKCS12
 openssl pkcs12 -export -in idp.crt -inkey idp.key -out cred.p12
 # Change password
 openssl rsa -in idp.key -des3 -out idp.key.new