# hdb-sandbox
# Pivotal HDB on Hortonworks HDP Sandbox

<img src="https://raw.githubusercontent.com/dbbaskette/hdb-on-hdp/gh-pages/images/hdb.jpeg?token=ACbVkUI1WnnUpyJAOIAZbDH4AHJsBj63ks5WM91-wA%3D%3D" width="300">

#### Packer-Based Build Process for building a Hortonworks HDP Sandbox with Pivotal HDB

**Requirements:**  

* Packer  
* VMware Fusion

This release only works for the vmware version.

* Download the VMWARE version of Sandbox 2.4 in to the main hdp-on-hpd directory. Leave it in its native downloaded format.
* Place Pivotal HDB and Ambari Plugin packages in ./bins Directory. Leave them in their native *.tar.gz format.
* Place MADlib Package in ./plugins.   Leave in Native *.tar.gz format
* In build.sh, verify the value for the following variable: SANDBOX_BASENAME,OVFTOOL_BIN,VMRUN_BIN.   If needed, change them to the appropriate values, so that the first process of the builder will run properly.
* Run ./build.sh vmware   (it's completely hands-off from here)
* Output will be a Zip file containing the VM.    Move and unzip where you want to store the VM.  It does not require an import to work.


Build Process: (Steps that are performed)
* If required, OVA will be converted to vmx format
* VM is booted, Root password is changed, and then VM is shutdown.
* VM is cloned.
* HDB Repos are configured and plugin is installed
* hdfs-site, core-site, and yarn-site are configured with appropriate values via Ambari API and then services are restarted.
* HDB and PXF are installed via API and parameters are set.
* HDB and PXF are started to complete installation
* Apache MADlib is installed.
* Tutorial GIT is cloned
* Data files are moved into HDFS and a table is created in Hive
* VM is cleaned up prior to shutdown
* VM is shutdown and then compressed to a zip file.


This release will automatically download the HDB Tutorials (which are not completed).   This process also will load data into Hive for immediate query by PXF

* Boot up the VM
* login to Ambari at <ip>:8080 with admin/admin
* start HDB and PXF
* login to the command line as gpadmin (gpadmin/gpadmin)
* Type:  psql -d template
* from the psql shell type: select * from hcatalog.faa.otp limit 10;

This will directly query the Hive table leveraging the metadata from HCATALOG



logins:

VM:
root/hawq2016
gpadmin/gpadmin
Ambari:
admin/admin
