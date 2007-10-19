#Port MIP Integrator will listen on
port => 9013,

#Location of int_cache
int_cache => '/tmp/intcache',

# The int_cache is used to store information received from Remote MIP's.
# The XML is stored for a certain period of time (set below) and will be used until it is expired.

# Number of seconds until the files in intcache expire
file_age => 600,

# This enables or disables the use of SSL on MIP Integrator (0 = off, 1 = on)
usessl     => 0,


# Location of an SSL file used to encrypt MIP traffic
ssl_file => '/tmp/mycert.pem',


# Provides a list of hosts that can connect to this integrator (Optional component)
# If not defined then any host can connect
# NOTE: Currently only IP addresses work correctly
hostlist => [ '10.0.0.1','127.0.0.1', ],

# Note:
# The command below will create a certificate using openssl.
# To properly create the certificate please replace COUNTRY, CITY NAME, and example.com with your Country, City Name, and FQDN respectively

# openssl req -x509 -nodes -days 365 -subj '/C=COUNTRY/L=CITY NAME/CN=example.com' -newkey rsa:1024 -keyout cert.pem -out cert.pem

