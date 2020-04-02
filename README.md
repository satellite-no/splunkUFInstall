# splunkUFInstall

## Description:
I have not tested this extensively yet but the attached PowerShell script should check for a current Splunk installation then either install or upgrade the Splunk UF version.  If the deployment server is set it will also set the deployment conf file. 

## Requirements:
PS1 script and splunk UF msi file must be in same directory.  (Recommend putting in "c:\temp")

## Usage:
Option   | Description        | Required | Example | Default Value
---------|--------------------|----------|---------|---------------
-version | Used to set the msi file to upgrade too | True | .\splunk_udpate.ps1 -version "splunkversion.msi"
-deploy_app | Sets the local app name for the uf deployment server | False | .\splunk_udpate.ps1 -version "splunkversion.msi" -deploy_app "CGS_uf_deploymentclient" -deployment_server "123.456.789:8089" | all_uf_deploymentclient
-deployment_server | Sets the deployment server in system/local | False | .\splunk_udpate.ps1 -version "splunkversion.msi" -deployment_server "123.456.789:8089"
-install_user | New install username* (ignored during upgrade) | False | .\splunk_udpate.ps1 -version "splunkversion.msi" -install_user “admin” | admin
-install_pwd | New install password* (ignored during upgrade) | False | .\splunk_udpate.ps1 -version "splunkversion.msi" -install_user “splunk” -install_pwd “mypassword123” | password123!

*If no username and password is set on a new install a default user-seed.conf is created in system/local.
