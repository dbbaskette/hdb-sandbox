# hdb-sandbox
# Pivotal HDB on Hortonworks HDP Sandbox

<img src="https://raw.githubusercontent.com/dbbaskette/hdb-on-hdp/gh-pages/images/hdb.jpeg?token=ACbVkUI1WnnUpyJAOIAZbDH4AHJsBj63ks5WM91-wA%3D%3D" width="300">

#### Packer-Based Build Process for building a Hortonworks HDP Sandbox with Pivotal HDB + MADlib

**Requirements:**  

*  Packer  
*  VMware Fusion
*  PIVNET API Key

This release only works for the vmware version.

* Run -> packer build -force -only=vmware hdb-sandbox.json


logins:

VM:
root/hadoop
gpadmin/gpadmin
Ambari:
admin/admin
