# Set to the FQDN of the MIP Integrator for your site
#integrator => "localhost",
integrator => "example.com",

# Port used by MIP Integrator above
port       => 9013,

# This enables or disables the use of SSL on MIP remote (0 = off, 1 = on)
usessl     => 0,

# Location of an SSL file used to encrypt MIP traffic
ssl_file   => "/tmp/mycert.pem",
#ssl_file   => "/location/for/cert/cert.pem",

# Note:
# The command below will create a certificate using openssl.
# To properly create the certificate please replace COUNTRY, CITY NAME, and example.com with your Country, City Name, and FQDN respectively

# openssl req -x509 -nodes -days 365 -subj '/C=COUNTRY/L=CITY NAME/CN=example.com' -newkey rsa:1024 -keyout cert.pem -out cert.pem

