.. vim: set tw=78 ts=4 sw=4 et ft=rst:
.. $Id:$
.. $HeadURL:$

=====================================
ARCS Data Fabric - Step-by-Step Guide
=====================================

.. sectnum::

.. rubric:: Step by Step Guide to get started using the ARCS Data Fabric.

The ARCS Data Fabric can be used to store and share file based data.  A number
of different forms of access are possible, and they do not all offer the same
amount of functionality or ease of use.  There are important differences with:

* authentication (and how it times out!),
* the way you work with files (up/download, view/edit),
* setting permissions on file sharing and
* controlling replication and other high level management of how files are stored.

The main interface we are promoting for general usage is a web interface to a
custom service written by ARCS staff, which provides rich access to browse and
manage files from a familiar and widely available iterface (a web browser).
This interface has limitations supporting large files and bulk operations.
Ther are also limitations with the authentication setup as we need to provide a
secure, stronly authenticated environment and it is difficult to not compromise
useability in this context.  See `known issues <http://www.arcs.org.au/products-services/data-services/arcs-data-fabric-1/arcs-data-fabric-1>`_.

We also support a webdav interface, for which there is a wide variety of client
software available, but some is quite tricky to setup and use, particularly
with the stromg authentication and encryption we require.  Software is
available to 'mount' the ARCS data fabric to make it available like a
filesystem or shared drive. Webdav and mounting the data fabric also have
problems with large file support.  They also have issues with authentication
timing out (and not offering graceful options for re-authenticating) and there
being no way of setting access permissions.

The underlying technology for the Data Fabric is iRODS, and command line
clients can also be setup to use the full functionality of that system.  With
the authentication systems we are using this is non-trivial and most users will
not use this interface and it is not mentioned further in this guide.  Feel
free to contact help@arcs.org.au for more information.

.. .. sidebar::

.. contents:: Contents: Step by Step

Register for ARCS Services
+++++++++++++++++++++++++++++

You have to register_ for ARCS Services prior to using the ARCS Data Fabric. If
you have not registered yet, please do so at the ARCS Services registry.
Otherwise go to the next step.

.. _register: http://services.arcs.org.au/

Accessing the ARCS Data Fabric using a web browser
+++++++++++++++++++++++++++++++++++++++++++++++++++++

It is possible to use the ARCS Data Fabric through most web browsers. 

* To view your home directory and other directories you have access to, simply
  point your browser to the address (or click here!)::

    https://df.arcs.org.au/ARCS/home

  You will be prompted for a username and password and at present you need to
  use a combination of AAF (and slcs) and myproxy.  In the future we aim to
  simplify the authentication.

Enter your Username and Password
+++++++++++++++++++++++++++++++++++++++

**new!** If you are using shibboleth authentication with the web interface, you
will be redirected to an AAF WAYF service to choose your IdP and then be
prompted to authenticate to your home institution.  If your institution does
not yet have an AAF federated IdP service, you can register_ to use the `ARCS
IdP`_.

.. _`ARCS IdP`: http://idp.arcs.org.au/

For access to services by clients that are not web browsers (or an ARCS
provided tool such as slix_), shibboleth is unsuitable on it's own but ARCS
anables you to authenticate to AAF to create a proxy credential which can be
held by an ARCS myproxy service, and you can use that for non-browser access to
ARCS services such as the Data Fabric.

.. |slix| replace:: slix

_`ARCS myproxy service`
-----------------------
 .. |pleasemyproxy| replace:: Please use the `ARCS myproxy service`_

Unless you are using shibboleth authentication in a web browser you should use
use the ARCS myproxy service. You will need to pre-load the myproxy service
with short-lived proxy credentials that you get from using shibboleth/AAF
authentication to the ARCS slcs service. The easiest way to do this for most
people is to use grix.

To access the ARCS slcs service (with slix_), you need to have an account with
an Identity Provider (IdP).  To login, you will need to know the name of your
IdP, you username on the IdP and your password.  Please contact |arcshelp| if 
you have trouble with your IdP and we can redirect you to your institutes IdP 
maintainer or otherwise help.

You can create a MyProxy credential by using the slix_ tool as follows:

1.  Download: http://staff.vpac.org/~markus/slix.jar
#. Run: ``java -jar slix.jar`` to start slix (if your browser did not do this automatically).
#. Select your IdP and enter your Username and Password.
#. Also provide a suitable MyProxy-Username and MyProxy-Password (should not be 
   the same password you use to access your institution!).
#. Push the "Create MyProxy" button.

slix_ creates a MyProxy credential that lasts for 10 days before expiring.

Once your MyProxy credential has been created, you can instruct the ARCS Data
Fabric to use if by entering the MyProxy-Username you declared in the form:
``myproxy\grahamj`` together with your chosen password. It should be noted that in
this context the username is case-insensitive, and a forward slash is an
acceptable alternative to the backslash character.

Mount the ARCS Data Fabric on your system
++++++++++++++++++++++++++++++++++++++++++++

How to mount the ARCS Data Fabric on your system

On MAC OS 10.5
-------------------

Connecting to the ARCS Data Fabric on Mac

It is possible to connect to the ARCS Data Fabric using the WebDAV protocol.
This page describes how you can connect to the data fabric using the built in
WebDAV client Finder on Mac.

 
Connecting using Finder

Finder is a WebDAV client that is bundled with the operating system.  To connect:

* In the Finder menu, find "Go", then select "Connect to Server" (or press Cmd-K).
* In Server Address, type in::

    https://df.arcs.org.au/ARCS/home

* Click on "+" to save this URL as a connection favorite.
* Click on connect and you will be prompted for a username and password. |pleasemyproxy|.
* Click on OK, and a connection will be made.
* You can now use the data fabric like any other local folder!

Adding Servers to Finder SideBar

* Click on Finder Preference
* Select Sidebar tab
* Check "Connected Servers" 

The ARCS Data Fabric connection should appear on the left sidebar of the Finder
window.  The eject button can be used to disconnect from the ARCS Data Fabric.

 
[Optional] Disabling .DS_Store creation

It is strongly suggested that you turn of .DS_Store file creation for network
connections.

The following will disable this function for all network connections: SMB/CIFS,
AFP, NFS, and WebDAV.

* Open Terminal, then type in::

    defaults write com.apple.desktopservices DSDontWriteNetworkStores true

* Press Return
* Restart the computer

On Windows
---------------

Connecting to the ARCS Data Fabric on Windows XP
................................................

Windows Explorer is a WebDAV client and no extra software is needed to connect
to the ARCS Data Fabric.

To connect to the ARCS Data Fabric:

* Double click on "My Network Places".
* Click on "Add a network Place", then Next.
* Select "Choose another network location".
* Then enter the following URL::

    https://df.arcs.org.au/ARCS/home

* You will be prompt for your username and password. |pleasemyproxy|.
* Once connected, you'll be asked to name the connection, e.g. ARCS_DataFabric.
* Click on OK - the connection has been created! 
    - You should see a new folder in "My Network Places"
* You can simply drag and drop files into the ARCS Data Fabric like any other local folder!

 
Connecting to the ARCS Data Fabric on Windows Vista and Windows 7 BETA
......................................................................

Connection to the ARCS Data Fabric can be accomplished using the NetDrive
software which can be downloaded from http://www.netdrive.net and is free for
non-commercial home use.

If you are using Windows Vista, you will also need to install a patch, as
outlined at http://support.microsoft.com/kb/907306

You can then connect to the ARCS Data Fabric as follows:

* Double click on the NetDrive shortcut, then click "New Site". 
* Enter "ARCS-DF" in the "Site name" field and select "WebDav"in the "Server Type" field.
* Enter::

      df.arcs.org.au/ARCS/home

  in the "Site IP or URL" field
* Click the "Advanced" button and ensure that "UTF-8" appears in the "Encoding" field.
* Also tick the "Use HTTPS" box, then click the "OK" button.
* Select an appropriate (e.g. "W:") value in the "Drive" field, then fill out the "Account" and "Password" fields. |pleasemyproxy|.
* Click the "Connect" button and your home folder should appear.
* You can now drag and drop files between that folder and any local folder as required!

On Linux
-------------

There are a number of file system browsers that can connect to the ARCS Data
Fabric directly on Linux.

Using KDE - Konqueror
.....................

* Open up a Konqueror window, and type in::

    webdavs://df.arcs.org.au/ARCS/home

* You'll be prompted for a username and password. |pleasemyproxy|.
* You can now use the ARCS Data Fabric like any other local folder!

Using Gnome - Nautilus
......................

* Open up a Nautilus window
* In the File menu, select "Connect to Server".  This will bring up a dialog box.  Fill in with the following details::

    Service type: Secure WebDAV (HTTPS)
    Host: df.arcs.org.au
    Port: (leave empty)
    Folder: ARCS/home
    Username: myproxy\<username> [#]_
    Name to user for connection: ARCS_DataFabric

* Click on Connect
* You'll be prompted for your password. |pleasemyproxy|.
* You should see an icon on your Desktop with the name you've given to the connection.  Double click on this to make the connection.
* You can now use the ARCS Data Fabric like any other local folder!

.. [#] |pleasemyproxy|

For gnome-util 2.24 users
.........................

Due to a bug in gnome-utils, gnome-util 2.24 users will have to connect
differently.

* In the File menu, select "Connect to Server"  This will briing up a dialog box.  Fill in with the following details::

    Service type: Custom Location
    Location URI: davs://df.arcs.org.au/ARCS/home
    Bookmark Name: ARCS_DataFabric

* You'll be prompted for your password. |pleasemyproxy|.
* You can now use the ARCS Data Fabric like any other local folder!

Using DAVFS
...........

For advanced users, you can mount WebDAV directories as shown here:
http://www.sfu.ca/itservices/linux/webdav-linux.html

 
On Windows Vista or Windows 7
-----------------------------

Connecting to the ARCS Data Fabric on Windows Vista or Windows 7

Connection to the ARCS Data Fabric can be accomplished using the NetDrive
software which can be downloaded from http://www.netdrive.net and is free for
non-commercial home use.

If you are using Windows Vista, you will also need to install a patch, as
outlined at http://support.microsoft.com/kb/907306

You can then connect to the ARCS Data Fabric as follows:

* Double click on the NetDrive shortcut, then click "New Site". 
* Enter "ARCS-DF" in the "Site name" field and select "WebDav"in the "Server Type" field.
* Click the "Advanced" button and ensure that "UTF-8" appears in the "Encoding" field.
* Also tick the "Use HTTPS" box, then click the "OK" button.
* Select an appropriate (e.g. "W:") value in the "Drive" field, then fill out the "Account" and "Password" fields. |pleasemyproxy|.
* Click the "Connect" button and your home folder should appear.
* You can now drag and drop files between that folder and any local folder as required!

 
Access Control and File Sharing
++++++++++++++++++++++++++++++++++

Using the ARCS Data Fabric to share files with others
Permissions

Files and folders are protected by a set of permissions on the ARCS Data
Fabric. 

* read - access to read object
* write - access to modify content (includes deletion!) of object
* all - access to read, modify and change access control of object
* null - remove all access
 
To modify the permission
------------------------

Permissions can only be modified using the browser mode. 

* Login to the ARCS Data Fabric using your browser.
* Click on the "Access Control" button next to an object, and a dialog will popup.
* Username: select a user or group you would like to assign a permission to.  You must know the ARCS Data Fabric username of the person you would like to assign permission to.  This is not the same as their IdP username. 
    - To find out your own username, first log into the ARCS Data Fabric.  You should see two folders.  The "public" folder is a shared directory - whatever you put in there will be readable by everyone.  The other directory is your home directory on the ARCS Data Fabric.  The name of this folder is your ARCS Data Fabric username. 
* Permission: selected a permission type
* Recursive: check this option if you would like this permission to be applied to any subfolders and files within them.
* Click on "Apply" and these changes will be set
* Click on "Cancel" closes the dialog box, and no changes will be made.
 
Removing a permission
------------------------

* Click on the "Access Control" button next to an object, and a dialog will popup.
* Click on the row that you would like to remove, then in the "Permission" dropdown box, select "null"
* Click on "Apply" and the permission will be removed.

 
Sharing a file with others
---------------------------

Once you have set the appropriate permissions for others to access an object,
right click on the object and select to copy the link. Send this link to your
colleagues and they will be taken directly to the object you would like to
share.  The 'guest' user

The 'guest' user is a special read-only user on the ARCS Data Fabric to allow
you to share an object on the ARCS Data Fabric with anybody, even if they
themselves don't have an account on the ARCS Data Fabric. To use it, allow the
'guest' user to read an object, send the URL of the object to your colleagues
(as above) and advise them to use login 'guest' and password 'guest' when asked
to provide it.


