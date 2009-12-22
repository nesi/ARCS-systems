What is it?
-----------
stpUtil is a SharedToken Portability utility to generate a signed PDF SharedToken document. The generated document is used for 
the migration of the SharedToken from the source institution to target institution.

How it works?
-------------
The steps include:
1. Read user's auEduPersonSharedToken and other attributes from institution LDAP.
2. Generate a PDF document including the aEPST, CN, issuer identity, issue data and so on.
3. Sign the document with the IdP's certificate. The certificate has to be PKCS12 format.
4. The signed document will be sent to the SharedToken's owner.
5. The owner will show the document to the target institution admin and the document will be verified.

Where to download?
------------------
Assume $INST is the installation directory.

>cd $INST
>svn co http://projects.arcs.org.au/svn/systems/trunk/idp/stpUtil

How to configure?
-----------------
Configure the file $INST/conf/stpUtil.properties. See the comments in the file.


How to build?
---------------
>cd $INST
>ant

How to run?
>cd $INST
>$INST/java -jar stpUtil.jar <uid>
<uid> is the user's unique ID in the LDAP. 


How Convert PEM to PKCS12?
--------------------------
If the IdP certificate is in PEM format, convert it to PKCS12 format using openssl: 
>openssl pkcs12 -export -in idp.crt -inkey idp.key -out cred.p12
