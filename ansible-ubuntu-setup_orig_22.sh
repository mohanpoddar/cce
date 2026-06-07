#!/bin/bash

#Define variable
#Varaible for date and time
start_time=$(date "+%d.%m.%Y-%H.%M.%S")
echo "Job Start Time : $start_time"

echo -e "\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

# #Varaible for ssh configuration
ssh_service=/lib/systemd/system/ssh.service
ssh_config=/etc/ssh/sshd_config

#Varaible for ansible
ansible_config_file=/etc/ansible/ansible.cfg
ansible_inv_file=/etc/ansible/hosts

PLAYBOOK=ubuntu-local-setup/ubuntu_setup.yml
ANSIBLE_CMD=/usr/local/bin/ansible-playbook

while getopts h:o:u: option
do 
    case "${option}"
        in
        h)hostname=${OPTARG};;
        o)orgusername=${OPTARG};;
        u)username=${OPTARG};;
    esac
done

apt upgrade -y
apt-get update

# Install basic initial packages
pkg_install () {
    echo "Function pkg_install begins......."
    #Declare a package array
    pkg_list=("vim" "pip" "mlocate" "nfs-common"    )
    
    # Print array values in  lines
    echo "Print every element in new line"
    for list in ${pkg_list[*]}; do
        apt-get install $list -y
    done
    echo -e "\nFunction pkg_install ends......."
    echo -e "\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
}

# Setup User account
user_account_setup () {
echo "Function user_account_setup begins......."
    touch /home/$orgusername/.bashrc
    sed 's/^HISTSIZE=1000/HISTSIZE=100000/' -i /home/$orgusername/.bashrc
    echo 'export HISTTIMEFORMAT="%d/%m/%y %T "' >> /home/$orgusername/.bashrc
    sed 's/^HISTSIZE=1000/HISTSIZE=100000/' -i /root/.bashrc
    echo 'export HISTTIMEFORMAT="%d/%m/%y %T "' >> /root/.bashrc
    echo -e "\nFunction user_account_setup ends......."
    echo -e "\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

}


# Install ssh
install_ssh () {
    echo "Function install_ssh begins......."
    if [ -f "$ssh_service" ];
    then
        echo "ssh already installed. Checking sshd service status..."
        systemctl status ssh | grep -w Active
    else
        echo "ssh not installed. Installing..."
        apt install ssh -y
        cp $ssh_config $ssh_config.$current_time
        sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
        systemctl enable --now ssh
        systemctl status ssh | grep -w Active
    fi
    echo -e "\nFunction install_ssh ends......."
    echo -e "\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
}


# Python Setup
config_python_alternative () {
    echo "Function config_python_alternative begins......."
    
    python_default_ver=$(/usr/bin/python --version | awk '{print $2}' | cut -d. -f1)
    python3_ver=$(/usr/bin/python3 --version | awk '{print $2}' | cut -d. -f1-2)
    echo "Print Available python default version: $python_default_ver"
    echo "Print Available python3 version: $python3_ver"

    if [ "$python_default_ver" = "3" ];
    then
       echo  "/usr/bin/python points to python3"
       echo "Displaying Python version: $(python --version)\n"
       update-alternatives --query python
    else
       echo "/usr/bin/python does not point to python3. Setting up..."
       update-alternatives --install /usr/bin/python python /usr/bin/python$python3_ver 30
       update-alternatives  --set python /usr/bin/python$python3_ver
       echo 0 | update-alternatives --config python
       echo "\n\nDisplaying Python version: $(python --version)\n"
       update-alternatives --query python
    fi
    apt install python3-pip -y
    echo -e "\nFunction config_python_alternative ends......."
    echo -e "\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
}


# Install and Configure Ansible
configure_ansible () {
    echo "Function configure_ansible begins......."
    if [ -f "$ansible_config_file" ];
    then
        echo "Ansible is already installed. Pinging nodes"
	    sed 's/^#host_key_checking = True/host_key_checking = False/' -i /etc/ansible/ansible.cfg
        ansible -m ping mylearnersepoint
    else
        echo "Ansible is not installed. Installing ansible..."
        python -m pip install ansible==2.10
        ls -ld ansible-config/ansible
        cp -r ansible-config/ansible /etc/
        chmod 755 /etc/ansible
        ls -ld /etc/ansible
        sed 's/^#host_key_checking = True/host_key_checking = Flase/' -i /etc/ansible/ansible.cfg
        ansible --version

        chk_inv_group=$(grep ubuntuservers /etc/ansible/hosts | sed 's:^.\(.*\).$:\1:')
        echo $chk_inv_group
        if [ "$chk_inv_group" = "ubuntuservers" ];
        then
            echo "Initial host inventory found. Pinging nodes"
            ansible -m ping mylearnersepoint
        else
        cat << EOF >> $ansible_inv_file
# Customized Hosts
[ubuntuservers]

EOF
       grep -A3 ubuntuservers /etc/ansible/hosts
       ansible -m ping localhost
       ansible -m ping all
       fi
    fi
    echo -e "\nFunction configure_ansible ends......."
    echo -e "\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
}


# # # Calling functions
pkg_install
user_account_setup
install_ssh
config_python_alternative
configure_ansible


echo -e "Ansible role begins.......\n"
$ANSIBLE_CMD -l localhost -e "username=$username" $PLAYBOOK
#ansible-playbook -l mylearnersepoint $PLAYBOOK -u root --private-key $key

echo -e "\nAnsible role ends......."
echo -e "\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

#Varaible for date and time
end_time=$(date "+%d.%m.%Y-%H.%M.%S")
echo -e "Job Finish Time : $end_time \n"

apt update
apt upgrade -y
sleep 5
cd /root
echo -e "Taking final reboot"
#reboot
