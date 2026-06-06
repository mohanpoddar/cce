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
# ansible_config_file=/etc/ansible/ansible.cfg
ansible_config_file=/usr/bin/ansible
ansible_inv_file=/etc/ansible/hosts

PLAYBOOK=ubuntu-local-setup/ubuntu_setup.yml
ANSIBLE_CMD=/usr//bin/ansible-playbook

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
    sed 's/^HISTSIZE=1000/HISTSIZE=100000000/' -i /home/$orgusername/.bashrc
    echo 'export HISTTIMEFORMAT="%d/%m/%y %T "' >> /home/$orgusername/.bashrc
    sed 's/^HISTSIZE=1000/HISTSIZE=100000000/' -i /root/.bashrc
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

    # Ensure python3 is available
    py3=$(command -v python3 || true)
    if [ -z "$py3" ]; then
        echo "python3 not found; installing python3..."
        apt-get update
        apt-get install -y python3
        py3=$(command -v python3 || true)
        if [ -z "$py3" ]; then
            echo "Failed to install python3. Exiting function."
            return 1
        fi
    fi

    # If an alternatives group for 'python' exists, show it; otherwise register python3
    if update-alternatives --query python >/dev/null 2>&1; then
        echo "update-alternatives 'python' group exists. Current python: $(command -v python || echo 'none')"
        update-alternatives --query python || true
    else
        echo "No alternatives for 'python' found. Registering $py3 as the python alternative."
        update-alternatives --install /usr/bin/python python "$py3" 10
        update-alternatives --set python "$py3" >/dev/null 2>&1 || true
        echo "Registered /usr/bin/python -> $(python --version 2>/dev/null || echo 'unknown')"
    fi

    apt-get install -y python3-pip

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
        apt update
        apt install -y software-properties-common
        add-apt-repository --yes --update ppa:ansible/ansible
        apt install -y ansible
        ls -ld ansible-config/ansible
        # cp -r ansible-config/ansible /etc/
        # chmod 755 /etc/ansible
        ls -ld /etc/ansible
        sed 's/^#host_key_checking = True/host_key_checking = Flase/' -i /etc/ansible/ansible.cfg
        ansible --version

        chk_inv_group=$(grep ubuntuservers /etc/ansible/hosts | sed 's:^.\(.*\).$:\1:')
        echo $chk_inv_group
        if [ "$chk_inv_group" = "ubuntuservers" ];
        then
            echo "Initial host inventory found. Pinging nodes"
            ansible -m ping mylearnersepoint
            ansible -m ping localhost
        else
        cat << EOF >> $ansible_inv_file
# Customized Hosts
[ubuntuservers]
localhost ansible_connection=local

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
# pkg_install
# user_account_setup
# install_ssh
# config_python_alternative
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
