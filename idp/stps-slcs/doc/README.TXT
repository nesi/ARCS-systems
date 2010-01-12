# Obtain slcs certificate using slcs-client-cmd
{{{
cd /opt
svn co https://projects.arcs.org.au/svn/slcs-client-cmd/trunk/ slcs-client-cmd
cd slcs-client-cmd
ant dist
cd dist/temp

./bin/slcs-client -v \
  -s https://slcs1.arcs.org.au/SLCS/login \
  -u <username> \
  -i urn:mace:federation.org.au:testfed:openidp.arcs.org.au \
  -d /root/.globus-slcs

# sign the certificate digest
{{{
cd /root/.globus-slcs
openssl dgst -sha1 \
  -sign userkey.pem \
  -out usercert.pem.sha1 \
  usercert.pem
}}}

openssl rsautl -sign \
  -inkey rsaprivatekey.pem \
  -in myfile.txt 
  -out myfile_signature.bin \

# configuration

{{{
vi $TOMCAT_HOME/webapps/stps/WEB-INF/classes/stps.properties
}}}


