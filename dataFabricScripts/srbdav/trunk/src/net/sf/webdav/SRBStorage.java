/*
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */
package net.sf.webdav;

import java.io.InputStream;
import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.io.BufferedOutputStream;
import java.io.FileOutputStream;
import java.io.BufferedInputStream;
import java.io.FileInputStream;

import java.security.Principal;

import java.util.Date;
import java.util.Hashtable;
import java.util.List;
import java.util.ArrayList;

import edu.sdsc.grid.io.srb.SRBAccount;
import edu.sdsc.grid.io.srb.SRBException;
import edu.sdsc.grid.io.srb.SRBFile;
import edu.sdsc.grid.io.srb.SRBFileInputStream;
import edu.sdsc.grid.io.srb.SRBFileOutputStream;
import edu.sdsc.grid.io.srb.SRBFileSystem;

/**
 * Reference Implementation of IWebdavStorage
 * 
 * @author joa
 * @author re
 */
public class SRBStorage implements IWebdavStorage {

	private static final String ROOTPATH_PARAMETER = "rootpath";

	private static final String DEBUG_PARAMETER = "storeDebug";

	private static int BUF_SIZE = 50000;

	private static SRBFileSystem srbFileSystem = null;

	private static int debug = -1;

	private String defaultResource;
	
	private String homeDirectory;
	
	public String getHomeDirectory() {
		return homeDirectory;
	}
	public void setHomeDirectory(String homeDirectory) {
		this.homeDirectory = homeDirectory;
	}
	public String getDefaultResource() {
		return defaultResource;
	}
	public void setDefaultResource(String defaultResource) {
		this.defaultResource = defaultResource;
	}
	public SRBStorage(){
	}	
	public SRBStorage(SRBFileSystem srbFileSystem){
		this.srbFileSystem=srbFileSystem;
	}
	
	public void setFileSystem(Object srbFileSystem){
		this.srbFileSystem=(SRBFileSystem)srbFileSystem;
	}
	
	public void disconnect(){
		try {
			if (srbFileSystem.isConnected()) srbFileSystem.close();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	public void begin(Principal principal, Hashtable parameters)
			throws Exception {
		System.out.println("principal:"+principal);
//		System.out.println("parameters:"+parameters);
		if (debug == -1) {
			String debugString = (String) parameters.get(DEBUG_PARAMETER);
			if (debugString == null) {
				debug = 0;
			}else{
			debug = Integer.parseInt(debugString);
			}
		}
		if (debug == 1)
			System.out.println("LocalFileSystemStore.begin()");
		if (srbFileSystem == null || !srbFileSystem.isConnected()) {
			SRBAccount account = new SRBAccount( 
				     "ngspare.sapac.edu.au", 5544, "shunde", "shunde", "/ngspare.sapac.edu.au/home/shunde.ngspare.sapac.edu.au", "ngspare.sapac.edu.au", "datafabric.ngspare.sapac.edu.au" );

			srbFileSystem=new SRBFileSystem(account);
			if (debug == 1)
				System.out.println("srbFileSystem is connected: "+srbFileSystem.isConnected());
//			String rootPath = (String) parameters.get(ROOTPATH_PARAMETER);
//			if (rootPath == null) {
//				throw new Exception("missing parameter: " + ROOTPATH_PARAMETER);
//			}
//			root = new File(rootPath);
//			if (!root.exists()) {
//				if (!root.mkdirs()) {
//					throw new Exception(ROOTPATH_PARAMETER + ": "
//							+ root
//							+ " does not exist and could not be created");
//				}
//			}
		}
	}

	public void checkAuthentication() throws SecurityException {
		if (debug == 1)
			System.out.println("LocalFileSystemStore.checkAuthentication()");
		// do nothing

	}

	public void commit() throws IOException {
		// do nothing
		if (debug == 1)
			System.out.println("LocalFileSystemStore.commit()");
	}

	public void rollback() throws IOException {
		// do nothing
		if (debug == 1)
			System.out.println("LocalFileSystemStore.rollback()");

	}

	public boolean objectExists(String uri) throws IOException {
		SRBFile file = new SRBFile(srbFileSystem, uri);
		if (debug == 1)
			System.out.println("LocalFileSystemStore.objectExists(" + uri
					+ ")=" + file.exists());
		return file.exists();
	}

	public boolean isFolder(String uri) throws IOException {
		SRBFile file = new SRBFile(srbFileSystem, uri);
		if (debug == 1)
			System.out.println("LocalFileSystemStore.isFolder(" + uri + ")="
					+ file.isDirectory());
		return file.isDirectory();
	}

	public boolean isResource(String uri) throws IOException {
		SRBFile file = new SRBFile(srbFileSystem, uri);
		if (debug == 1)
			System.out.println("LocalFileSystemStore.isResource(" + uri + ") "
					+ file.isFile());
		return file.isFile();
	}

	/**
	 * @throws IOException
	 *             if the folder cannot be created
	 */
	public void createFolder(String uri) throws IOException {
		if (debug == 1)
			System.out
					.println("LocalFileSystemStore.createFolder(" + uri + ")");
		SRBFile file = new SRBFile(srbFileSystem, uri);
		if (!file.mkdir())
			throw new IOException("cannot create folder: " + uri);
	}

	/**
	 * @throws IOException
	 *             if the resource cannot be created
	 */
	public void createResource(String uri) throws IOException {
		if (debug == 1)
			System.out.println("LocalFileSystemStore.createResource(" + uri
					+ ")");
		SRBFile file = new SRBFile(srbFileSystem, uri);
		file.setResource(defaultResource);
		if (!file.createNewFile())
			throw new IOException("cannot create file: " + uri);
	}

	/**
	 * tries to save the given InputStream to the file at path "uri". content
	 * type and charachter encoding are ignored
	 */
	public void setResourceContent(String uri, InputStream is,
			String contentType, String characterEncoding) throws IOException {

		if (debug == 1)
			System.out.println("LocalFileSystemStore.setResourceContent(" + uri
					+ ")");
		SRBFile file = new SRBFile(srbFileSystem, uri);
		file.setResource(defaultResource);
		SRBFileOutputStream os = new SRBFileOutputStream(file);
		try {
			int read = -1;
			byte[] copyBuffer = new byte[BUF_SIZE];

			while ((read = is.read(copyBuffer, 0, copyBuffer.length)) != -1) {
				os.write(copyBuffer, 0, read);
			}
		} finally {
			try {
				is.close();
			} finally {
				os.close();
			}
		}
	}

	/**
	 * @return the lastModified Date
	 */
	public Date getLastModified(String uri) throws IOException {
		if (debug == 1)
			System.out.println("LocalFileSystemStore.getLastModified(" + uri
					+ ")");
		SRBFile file = new SRBFile(srbFileSystem, uri);
		return new Date(file.lastModified());
	}

	/**
	 * @return the lastModified date of the file, java.io.file does not support
	 *         a creation date
	 */
	public Date getCreationDate(String uri) throws IOException {
		if (debug == 1)
			System.out.println("LocalFileSystemStore.getCreationDate(" + uri
					+ ")");
		// TODO return creation date instead of last modified
		SRBFile file = new SRBFile(srbFileSystem, uri);
		return new Date(file.lastModified());
	}

	/**
	 * @return a (possibly empty) list of children, or <code>null</code> if
	 *         the uri points to a file
	 */
	public String[] getChildrenNames(String uri) throws IOException {
		if (debug == 1)
			System.out.println("LocalFileSystemStore.getChildrenNames(" + uri
					+ ")");
		SRBFile file = new SRBFile(srbFileSystem, uri);
		if (file.isDirectory()) {
			return file.list();
//			File[] children = file.list();
//			List childList = new ArrayList();
//			for (int i = 0; i < children.length; i++) {
//				String name = children[i].getName();
//				childList.add(name);
//
//			}
//			String[] childrenNames = new String[childList.size()];
//			childrenNames = (String[]) childList.toArray(childrenNames);
//			return childrenNames;
		} else {
			return null;
		}

	}

	/**
	 * @return an input stream to the specified resource
	 */
	public InputStream getResourceContent(String uri) throws IOException {
		if (debug == 1)
			System.out.println("LocalFileSystemStore.getResourceContent(" + uri
					+ ")");
		SRBFile file = new SRBFile(srbFileSystem, uri);

		try{
			SRBFileInputStream in = new SRBFileInputStream(file);
			if (in==null) throw new IOException();
			System.out.println("getResourceContent:"+in.available()+" "+in.getFileSystem());
			return in;
		}catch (Exception e){
			e.printStackTrace();
			throw new IOException();
		}
	}

	/**
	 * @return the size of the file
	 */
	public long getResourceLength(String uri) throws IOException {
		if (debug == 1)
			System.out.println("LocalFileSystemStore.getResourceLength(" + uri
					+ ")");
		SRBFile file = new SRBFile(srbFileSystem, uri);
		if (file==null) throw new IOException();
		return file.length();
	}

	/**
	 * @throws IOException
	 *             if the deletion failed
	 * 
	 */
	public void removeObject(String uri) throws IOException {
		SRBFile file = new SRBFile(srbFileSystem, uri);
		boolean success = file.delete();
		if (debug == 1)
			System.out.println("LocalFileSystemStore.removeObject(" + uri
					+ ")=" + success);
		if (!success) {
			throw new IOException("cannot delete object: " + uri);
		}

	}

}
