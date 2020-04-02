# Upgrade/Install Splunk UF On Windows
#
# By: Sean Elliott
# Date: 04/01/2020
#
# Example: .\splunk_udpate.ps1 -version "splunkversion.msi" -deployment_server "123.456.789:8089"

param ([Parameter(Mandatory)]$version, $deploy_app, $deployment_server, $install_pwd,$install_user="admin")
$install_dir = "C:\Program Files\SplunkUniversalForwarder"
$temp_dir = "C:\temp\"
$install_log = "splunk_install.log"

function install-splunk {
    write-host "Installing Splunk version $version ..."
    $arg_list = @(
        "/i"
        ('"{0}" AGREETOLICENSE=Yes INSTALLDIR="{1}" LAUNCHSPLUNK=0 LOGON_USERNAME="{2}" LOGON_PASSWORD="{3}" SERVICESTARTTYPE=auto' -f $version, $install_dir, $install_user, $install_pwd)
        "/L*v"
        $install_log
        "/quiet"
    )
    # Performs the install of Splunk UF
    Start-Process msiexec.exe -Wait -ArgumentList $arg_list

    if (!$install_pwd){
        write-host "No password set using default user seed file... "
        install-userseed
    }
}

function upgrade-splunk {
    write-host "Upgrading Splunk to $version ..."
    $arg_list = @(
        "/i"
        ('"{0}" AGREETOLICENSE=Yes' -f $version)
        "/L*v"
        $install_log
        "/quiet"
    )
    # Performs the Upgrade of Splunk UF
    start-process msiexec.exe -Wait -argumentList $arg_list
}

function install-userseed {
    $seed_file = "user-seed.conf"

    write-host "Creating $install_dir\etc\system\local\$seed_file ..."
    $seed_conf = "[user_info]"
    $seed_conf += "`nUSERNAME = admin"
    $seed_conf += "`nPASSWORD = password123!"

    $seed_conf | out-file "$install_dir\etc\system\local\$seed_file"
}
function install-deploymentserver {
    # Set variables and configs 
    $deploy_file = "deploymentclient.conf"
    $app_file = "app.conf"
    $meta_file = "local.meta"
    
    # Default app.conf config
    $app_conf = @(
        "[install]"
        "state = enabled"
        ""
        "[package]"
        "check_for_updates = false"
        ""
        "[ui]"
        "is_visible = false"
        "is_manageable = false"
    )
    # Default meta.local
    $meta_conf = @(
        "[]"
        "access = read : [ * ], write : [ admin ]"
        "export = system"
    )
    # Deploymentclient.conf config
    $deployment_conf = @(
        "[deployment-client]"
        "# Set the phoneHome at the end of the PS engagement"
        "# 10 minutes"
        "# phoneHomeIntervalInSecs = 600"
        ""
        "[target-broker:deploymentServer]"
        "# Change the targetUri"
        "targetUri=$deployment_server"
    )

    write-host "Creating Deployment app in $deploy_app"
    new-item -path "$install_dir\etc\apps\$deploy_app\local\" -name $app_file -force
    new-item -path "$install_dir\etc\apps\$deploy_app\local\" -name $deployment_conf -force
    new-item -path "$install_dir\etc\apps\$deploy_app\metadata\" -name $app_file -force

    $app_conf | out-file "$install_dir\etc\apps\$deploy_app\local\$app_file" -value $app_conf
    $deployment_conf | out-file "$install_dir\etc\apps\$deploy_app\local\$deploy_file" -value $deploy_conf
    set-content -path "$install_dir\etc\apps\$deploy_app\metadata\$meta_file" -value $meta_conf
}

if (test-path $install_dir) {
    upgrade-splunk
} 
else {
    install-splunk
}

if ($deployment_server) {
    install-deploymentserver
}

write-host "Starting Splunk ..."
& $install_dir\bin\splunk.exe start --accept-license