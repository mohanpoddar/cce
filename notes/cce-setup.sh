#!/bin/bash

while getopts h:o:u: option
do 
    case "${option}"
        in
        h)hostname=${OPTARG};;
        o)orgusername=${OPTARG};;
        u)username=${OPTARG};;
    esac
done

tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)

echo $tmp_dir

apt install git

git clone https://github.com/mohanpoddar/cce.git $tmp_dir

echo -e "\nSystemuser : $orgusername"
sleep 1
echo -e "Admin User : $username\n"
sleep 1
cd $tmp_dir
ls $tmp_dir

bash $tmp_dir/ansible-ubuntu-setup.sh -u $username -o $orgusername

rm -rf $tmp_dir
