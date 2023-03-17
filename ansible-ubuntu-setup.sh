#!/bin/bash

#Define variable
#Varaible for date and time
start_time=$(date "+%d.%m.%Y-%H.%M.%S")
echo "Job Start Time : $start_time"

echo -e "\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

#Varaible for hosts file 
hosts_file=/etc/hosts
lepoint=$(grep -w ansible_mylearnersepoint $hosts_file | awk '{print $5}')
lepoint1=$(grep -w ansible_mylearnersepoint1 $hosts_file | awk '{print $5}')

#Varaible for linudata
create_mydata=/media/devopsadmin/MyData/

#Varaible for linudata
create_linuxdata=/home/devopsadmin/linuxdata

#Varaible for user home
src_user_home_data=/media/devopsadmin/MyData/mohan-ji-HP-8-apr-12/Mohan_Data/RHEL/Linux/Automation/Training/ubuntu
src_user_devopsadmin_home_data=devopsadmin-user-home
src_user_root_home_data=root-user-home
dst_devopsadmin_home=/home/devopsadmin
dst_root_home=/root

#Varaible for ssh configuration
ssh_service=/lib/systemd/system/ssh.service
ssh_config=/etc/ssh/sshd_config

#Varaible for ansible
ansible_config_file=/etc/ansible/ansible.cfg
ansible_inv_file=/etc/ansible/hosts

PLAYBOOK=/media/devopsadmin/MyData/mohan-ji-HP-8-apr-12/Mohan_Data/RHEL/Linux/Automation/ansible/ansible-my-works/ubuntu-local-setup/ubuntu_setup.yml
key=/home/devopsadmin/.ssh/root_id_rsa 
#ANSIBLE_CMD=/media/devopsadmin/MyData/mohan-ji-HP-8-apr-12/Mohan_Data/RHEL/Linux/Automation/ansible/ansible-my-works/ubuntu-local-setup/venv_ubuntu_ansible/bin/ansible-playbook
ANSIBLE_CMD=/usr/local/bin/ansible-playbook

# Install basic initial packages
pkg_install () {
    echo "Function pkg_install begins......."
    #Declare a package array
    pkg_list=("vim" "pip" "mlocate")
    
    # Print array values in  lines
    echo "Print every element in new line"
    for list in ${pkg_list[*]}; do
        apt-get install $list -y
    done
    echo -e "\nFunction pkg_install ends......."
    echo -e "\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
}


# Add hosts file
add_host () {
    echo "Function add_host begins......."
    if [ "$lepoint" = "ansible_mylearnersepoint" ];
    then
        echo "$lepoint already exists in $hosts_file"
    else
        cat << EOF >> $hosts_file
192.168.10.100           mylearnersepoint          mylearnersepoint.example.com	# ansible_mylearnersepoint
EOF
        host=$(grep -w 100 $hosts_file | awk '{print $2}')
        if [ "$host" = "mylearnersepoint" ];
        then
            echo "Host $host added successfully"
            grep -w 100 $hosts_file
        else
           echo "Failed to add $host"
        fi
    fi

    if [ "$lepoint1" = "ansible_mylearnersepoint1" ];
    then
        echo "$lepoint1 already exists in $hosts_file"
    else
        cat << EOF >> $hosts_file
192.168.10.101           mylearnersepoint1          mylearnersepoint1.example.com	# ansible_mylearnersepoint1
EOF
        host=$(grep -w 101 $hosts_file | awk '{print $2}')
        if [ "$host" = "mylearnersepoint1" ];
        then
            echo "Host $host added successfully"
            grep -w 101 $hosts_file
        else
           echo "Failed to add $host"
        fi
    fi
    echo -e "\nFunction add_host ends......."
    echo -e "\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
}






# Setup User account
user_account_setup () {
echo "Function user_account_setup begins......."
# devopsadmin@mylearnersepoint:~$ cat .bashrc
# alias myansible='sudo /media/devopsadmin/MyData/mohan-ji-HP-8-apr-12/Mohan_Data/RHEL/Linux/Automation/ansible/ansible-my-works/ubuntu-local-setup/venv_ubuntu_ansible/bin/ansible'
# alias myansible-playbook='sudo /media/devopsadmin/MyData/mohan-ji-HP-8-apr-12/Mohan_Data/RHEL/Linux/Automation/ansible/ansible-my-works/ubuntu-local-setup/venv_ubuntu_ansible/bin/ansible-playbook'
# export PATH="$HOME/bin:$PATH"
#    cp -r $src_user_home_data/$src_user_devopsadmin_home_data/.ssh $dst_devopsadmin_home/.ssh

# Setup devopsadmin user account
    cp -r $src_user_home_data/$src_user_devopsadmin_home_data/.ssh $dst_devopsadmin_home/
    chmod 700 $dst_devopsadmin_home/.ssh
    chmod 664 $dst_devopsadmin_home/.ssh/authorized_keys
    chmod 600 $dst_devopsadmin_home/.ssh/id_ecdsa
    chmod 644 $dst_devopsadmin_home/.ssh/id_ecdsa.pub
    chmod 600 $dst_devopsadmin_home/.ssh/id_rsa
    chmod 644 $dst_devopsadmin_home/.ssh/id_rsa.pub
    chmod 644 $dst_devopsadmin_home/.ssh/known_hosts
    # cat /dev/null > $dst_devopsadmin_home/.ssh/known_hosts
    chmod 600 $dst_devopsadmin_home/.ssh/root_id_rsa
    chown -R devopsadmin:devopsadmin $dst_devopsadmin_home/.ssh
    for i in `ls $dst_devopsadmin_home/.ssh` ; do ls -l $dst_devopsadmin_home/.ssh/$i; done

    cp -r $src_user_home_data/$src_user_devopsadmin_home_data/bin $dst_devopsadmin_home/
    chown -R devopsadmin:devopsadmin $dst_devopsadmin_home/bin

    cp -r $src_user_home_data/$src_user_devopsadmin_home_data/.gitconfig $dst_devopsadmin_home/.gitconfig
    chown devopsadmin:devopsadmin $dst_devopsadmin_home/.gitconfig
    chmod 644 $dst_devopsadmin_home/.gitconfig

    cp -r $src_user_home_data/$src_user_devopsadmin_home_data/.my.cnf $dst_devopsadmin_home/.my.cnf
    chown devopsadmin:devopsadmin $dst_devopsadmin_home/.my.cnf
    chmod 644 $dst_devopsadmin_home/.my.cnf

    cp -r $src_user_home_data/$src_user_devopsadmin_home_data/.vimrc $dst_devopsadmin_home/.vimrc
    chown devopsadmin:devopsadmin $dst_devopsadmin_home/.vimrc
    chmod 644 $dst_devopsadmin_home/.vimrc

# Setup root account
    cp -r $src_user_home_data/$src_user_root_home_data/.ssh $dst_root_home/.ssh
    chmod 700 $dst_root_home/.ssh
    chmod 664 $dst_root_home/.ssh/authorized_keys
    chmod 600 $dst_root_home/.ssh/id_rsa
    chmod 644 $dst_root_home/.ssh/id_rsa.pub
    chmod 644 $dst_root_home/.ssh/known_hosts
    # cat /dev/null > $dst_root_home/.ssh/known_hosts
    chmod 600 $dst_root_home/.ssh/root_id_rsa
    for i in `ls $dst_root_home/.ssh` ; do ls -l $dst_root_home/.ssh/$i; done
    cp
    sed 's/^HISTSIZE=1000/HISTSIZE=100000/' -i /home/devopsadmin/.bashrc
    echo 'export HISTTIMEFORMAT="%d/%m/%y %T "' >> /home/devopsadmin/.bashrc
    sed 's/^HISTSIZE=1000/HISTSIZE=100000/' -i /root/.bashrc
    echo 'export HISTTIMEFORMAT="%d/%m/%y %T "' >> /root/.bashrc
    echo -e "\nFunction user_account_setup ends......."
    echo -e "\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

}


# Install ssh
# https://linuxconfig.org/enable-ssh-on-ubuntu-20-04-focal-fossa-linux
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
# Manual - Set python environment
# cd /media/devopsadmin/MyData/mohan-ji-HP-8-apr-12/Mohan_Data/RHEL/Linux/Automation/ansible/ansible-my-works/ubuntu-local-setup
# pwd
# python -m venv venv_ubuntu_ansible
# source /media/devopsadmin/MyData/mohan-ji-HP-8-apr-12/Mohan_Data/RHEL/Linux/Automation/ansible/ansible-my-works/ubuntu-local-setup/venv_ubuntu_ansible/bin/activate
# pwd
# pip list
# pip -V
# python -m pip install ansible
# deactivate
# pip list
# pip -V
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
#        apt install software-properties-common
#        add-apt-repository --yes --update ppa:ansible/ansible
#        apt install ansible
        python -m pip install ansible==2.10
        ls -ld $src_user_home_data/ansible-config/ansible
        cp -r $src_user_home_data/ansible-config/ansible /etc/
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
mylearnersepoint
mylearnersepoint1

[redhatservers]
learnersepointrhel7
learnersepointrhel8
learnersepoint
EOF
       grep -A3 ubuntuservers /etc/ansible/hosts
       ansible -m ping all
       fi
    fi
    echo -e "\nFunction configure_ansible ends......."
    echo -e "\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
}


# # # Calling functions
# pkg_install
# add_host
# create_mydata
# create_linuxdata
# user_account_setup
install_ssh
config_python_alternative
configure_ansible


# Clear this file
# cat /dev/null > /root/.ssh/known_hosts
# cat /dev/null > /home/devopsadmin/.ssh/known_hosts

# add-apt-repository ppa:openshot.developers/ppa -y

echo -e "Ansible role begins.......\n"
# # #myansible-playbook -l mylearnersepoint /home/devopsadmin/linuxdata/Automation/ansible/ansible-my-works/ubuntu-local-setup/ubuntu_setup.yml -u root --private-key /home/devopsadmin/.ssh/root_id_rsa
# ansible-playbook -l mylearnersepoint /home/devopsadmin/linuxdata/Automation/ansible/ansible-my-works/ubuntu-local-setup/ubuntu_setup.yml -u root --private-key /home/devopsadmin/.ssh/root_id_rsa
$ANSIBLE_CMD -l localhost $PLAYBOOK -u root --private-key $key
#ansible-playbook -l mylearnersepoint $PLAYBOOK -u root --private-key $key

echo -e "\nAnsible role ends......."
echo -e "\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

#Varaible for date and time
end_time=$(date "+%d.%m.%Y-%H.%M.%S")
echo -e "Job Finish Time : $end_time \n"

echo -e "Taking final reboot"
sleep 5
# reboot
