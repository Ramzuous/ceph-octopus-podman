#!/bin/bash

if test -f vars_files/ceph-new-hosts-vars.yml;
then
	rm vars_files/ceph-new-hosts-vars.yml
fi

touch vars_files/ceph-new-hosts-vars.yml

sed -i 's/#//' updateCephCluster.yml

sed -i "s/replace: 'mirrorlist'/replace: '#mirrorlist'/" updateCephCluster.yml
sed -i '0,/baseurl/s//#baseurl/' updateCephCluster.yml

echo ""
echo ""

echo "**************************************************************************"
echo "*************** Welcome in generation of ansible components **************"
echo "**************************************************************************"

echo ""
echo ""

#################################################################################
################################## Variables ####################################
#################################################################################

# Template settings
template_mon_name="" # Plain text
template_mon_id=""

template_osd_name="" # Plain text
template_osd_id=""

# Hardware
net0_hw="" # example: virtio,bridge=vmbr0
cores_num=""
vcpus_num=""
memory_size="" # example 4096

# Ceph Features - Common
ceph_network="" # Only three octets, example: 192.168.0
netmask="" # example: 24
gateway="" # example: 192.168.0.1

# Ceph mon - admin is also ceph-mon
create_new_mons_confirm="" # only yes confirm creating new hosts
target_node_mon="" # example: pve01
mon_ip_fourth_greater="" # example: 40
mon_ip_fourth_smaller="" # example: 38
ceph_mons_name_begin="" # example: mon

# Ceph osd
create_new_osds_confirm="" # only yes confirm creating new hosts
target_node_osd="" # example: pve01
osd_ip_fourth_greater="" # example: 35
osd_ip_fourth_smaller="" # exmaple 30
ceph_osds_name_begin="" # example: osd

# Variables not to change
number_of_ceph_mon_nodes=$(grep -c 'vm_name' vars_files/ceph-mon-vars.yml)
number_of_ceph_osd_nodes=$(grep -c 'vm_name' vars_files/ceph-osd-vars.yml)
check_info_mon_show=0
check_info_osd_show=0


#################################################################################

#################################################################################

idrsapub=`cat id_rsa.pub`

echo "*****************************************************"
echo "Set new ceph mons"
echo "*****************************************************"

echo ""
echo ""

if [ $create_new_mons_confirm == 'yes' ]
then

	echo "Setting host_vars, inventory & vars_files/ceph-new-hosts-vars.yml"

	i=$number_of_ceph_mon_nodes

	while [ $mon_ip_fourth_smaller -le $mon_ip_fourth_greater ]
	do

		mon_ip=$ceph_network"."$mon_ip_fourth_smaller

		mon_name=$ceph_mons_name_begin"-"$i

		ip_check=$(grep -c $mon_ip vars_files/ceph-mon-vars.yml)

		ip_check2=$(grep -c $mon_ip vars_files/ceph-osd-vars.yml)

		ip_check3=$(grep -c $mon_ip vars_files/ceph-admin-vars.yml)

		if ! test -f host_vars/$mon_name.yml && [ $ip_check == 0 ] && [ $ip_check2 == 0 ] && [ $ip_check3 == 0 ];
		then

			echo "Setting host_vars/"$mon_name".yml, inventory/ceph-cluster-inventory.yml & vars_files/ceph-new-hosts-vars.yml"

			echo "ansible_host: "$mon_ip >> host_vars/$mon_name".yml"

			check_mon_string=$(grep -c ceph_new_mon_vars vars_files/ceph-new-hosts-vars.yml)

			if [ $check_mon_string == 0 ];
			then
				echo "ceph_new_mon_vars:" >> vars_files/ceph-new-hosts-vars.yml
			fi

			awk -i inplace '1;/            cephmons:/{c=2}c&&!--c{print "                '$mon_name':"}' inventory/ceph-cluster-inventory.yml

			echo "  - { vm_name: '"$mon_name"', network_cloud: 'ip="$mon_ip"/"$netmask,"gw="$gateway"', net0_hw: '"$net0_hw"', target_node: '"$target_node_mon"', ip_cloud: '"$mon_ip"', memory_size: "$memory_size", cores_num: "$cores_num", vcpus_num: "$vcpus_num", template_name: "$template_mon_name", template_id: "$template_mon_id" }" >> vars_files/ceph-new-hosts-vars.yml

			echo "  - { vm_name: '"$mon_name"', network_cloud: 'ip="$mon_ip"/"$netmask,"gw="$gateway"', net0_hw: '"$net0_hw"', target_node: '"$target_node_mon"', ip_cloud: '"$mon_ip"', memory_size: "$memory_size", cores_num: "$cores_num", vcpus_num: "$vcpus_num", template_name: "$template_mon_name", template_id: "$template_mon_id" }" >> vars_files/ceph-mon-vars.yml

		else
			echo "File host_vars/"$mon_name".yml or IP address exist in cluster. New mon "$mon_name" will not be added"
			check_info_mon_show=$((check_info_mon_show+1))
		fi
			mon_ip_fourth_smaller=$((mon_ip_fourth_smaller+1))
			i=$((i+1))
	done
else
    echo "No mons will be created"

	sed -i 's/- name: Add mons/#- name: Add mons/' updateCephCluster.yml
	sed -i '/shell: ceph orch daemon add mon "{{ item.vm_name }}":"{{ item.ip_cloud }}"/{n;s/.*/      #with_items:/}' updateCephCluster.yml
	sed -i 's/shell: ceph orch daemon add mon "{{ item.vm_name }}":"{{ item.ip_cloud }}"/#shell: ceph orch daemon add mon "{{ item.vm_name }}":"{{ item.ip_cloud }}"/' updateCephCluster.yml

	sed -i 's/- "{{ ceph_new_mon_vars }}"/#- "{{ ceph_new_mon_vars }}"/g' updateCephCluster.yml
fi

echo ""

echo "*****************************************************"
echo "Set new ceph osds"
echo "*****************************************************"

echo ""
echo ""

if [ $create_new_osds_confirm == 'yes' ]
then

	echo "Setting host_vars, inventory & vars_files/ceph-new-hosts-vars.yml"

	i=$number_of_ceph_osd_nodes

	while [ $osd_ip_fourth_smaller -le $osd_ip_fourth_greater ]
	do

		osd_ip=$ceph_network"."$osd_ip_fourth_smaller

		osd_name=$ceph_osds_name_begin"-"$i

		ip_check=$(grep -c $osd_ip vars_files/ceph-mon-vars.yml)

		ip_check2=$(grep -c $osd_ip vars_files/ceph-osd-vars.yml)

		ip_check3=$(grep -c $osd_ip vars_files/ceph-admin-vars.yml)

		if ! test -f host_vars/$osd_name.yml && [ $ip_check == 0 ] && [ $ip_check2 == 0 ] && [ $ip_check3 == 0 ];
		then

			echo "Setting host_vars/"$osd_name".yml, inventory/ceph-cluster-inventory.yml & vars_files/ceph-new-hosts-vars.yml"

			echo "ansible_host: "$osd_ip >> host_vars/$osd_name".yml"

			awk -i inplace '1;/            cephosds:/{c=2}c&&!--c{print "                '$osd_name':"}' inventory/ceph-cluster-inventory.yml

			check_osd_string=$(grep -c ceph_new_osd_vars vars_files/ceph-new-hosts-vars.yml)

			if [ $check_osd_string == 0 ];
			then
				echo "ceph_new_osd_vars:" >> vars_files/ceph-new-hosts-vars.yml
			fi

			echo "  - { vm_name: '"$osd_name"', network_cloud: 'ip="$osd_ip"/"$netmask,"gw="$gateway"', net0_hw: '"$net0_hw"', target_node: '"$target_node_osd"', ip_cloud: '"$osd_ip"', memory_size: "$memory_size", cores_num: "$cores_num", vcpus_num: "$vcpus_num", template_name: "$template_osd_name", template_id: "$template_osd_id" }" >> vars_files/ceph-new-hosts-vars.yml

			echo "  - { vm_name: '"$osd_name"', network_cloud: 'ip="$osd_ip"/"$netmask,"gw="$gateway"', net0_hw: '"$net0_hw"', target_node: '"$target_node_osd"', ip_cloud: '"$osd_ip"', memory_size: "$memory_size", cores_num: "$cores_num", vcpus_num: "$vcpus_num", template_name: "$template_osd_name", template_id: "$template_osd_id" }" >> vars_files/ceph-osd-vars.yml

		else
			echo "File host_vars/"$osd_name".yml or IP address exist in cluster. New osd "$osd_name" will not be added"
			check_info_osd_show=$((check_info_osd_show+1))
		fi

			osd_ip_fourth_smaller=$((osd_ip_fourth_smaller+1))
			i=$((i+1))

	done
else
    echo "No osds will be created"

	sed -i 's/- name: Add osds/#- name: Add osds/' updateCephCluster.yml
	sed -i '/shell: ceph orch daemon add osd "{{ item.vm_name }}":\/dev\/sdb/{n;s/.*/      #with_items:/}' updateCephCluster.yml
	sed -i 's/shell: ceph orch daemon add osd "{{ item.vm_name }}":\/dev\/sdb/#shell: ceph orch daemon add osd "{{ item.vm_name }}":\/dev\/sdb/' updateCephCluster.yml

	sed -i 's/- "{{ ceph_new_osd_vars }}"/#- "{{ ceph_new_osd_vars }}"/g' updateCephCluster.yml
fi

echo ""
echo ""

if [ $create_new_mons_confirm != 'yes' ] && [ $create_new_osds_confirm != 'yes' ] || [ $check_info_mon_show != 0 ] || [ $check_info_osd_show != 0 ]; 
then
	echo "No update can be done, because create_new_mons_confirm & create_new_osds_confirm are not set to 'yes' or host with added IP's already exist"
else
	echo "**************************************************************************"
	echo "********************* All components are set *****************************"
	echo "**************************************************************************"

	echo ""
	echo ""

	echo "To update ceph cluster, run:"

	echo ""

	echo "ansible-playbook -i inventory/ceph-cluster-inventory.yml updateCephCluster.yml --ask-vault-pass"
fi

echo ""
echo ""
