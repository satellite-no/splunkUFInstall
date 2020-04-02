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
    $deploy_file = "deploymentclient.conf"
    $app_file = "app.conf"
    $meta_file = "local.meta"
    
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

    $app_conf | out-file "$install_dir\etc\apps\$deploy_app\local\$deploy_app"

    write-host "Creating Deployment app in $deploy_app"
    new-item -path "$install_dir\etc\apps\$deploy_app\local\" -name $app_file

    write-host "Creating $install_dir\etc\system\local\$deploy_file ..."
    $deployment_conf = "[deployment-client]"
    $deployment_conf += "`n# Set the phoneHome at the end of the PS engagement"
    $deployment_conf += "`n# 10 minutes"
    $deployment_conf += "`n# phoneHomeIntervalInSecs = 600"
    $deployment_conf += "`n"
    $deployment_conf += "`n[target-broker:deploymentServer]"
    $deployment_conf += "`n# Change the targetUri"
    $deployment_conf += "`ntargetUri=$deployment_server"

    $deployment_conf | out-file "$install_dir\etc\apps\$deploy_app\local\$deploy_file"
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