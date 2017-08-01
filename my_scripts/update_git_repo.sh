#!/bin/bash

# Update All Repos
# PREREQ:
# each repo must contain the remote "upstream" pointing
# to the current repo. After called, each repo (except tools)
# is pointing to the current repo index. The branch "nightly_build"
# will be the branchof the update data.

get_build_name () {
	echo ""
	echo "get_build_name()"
	echo ""
	DATE=`date +%Y-%m-%d`
	eval "$1='/opt/maxim/LDE/nightly_build$DATE'"
}

check_with_user () {
	# BYPASS WAIT
	# read -p "Press key to continue... or CTRL+C to break " -n1 -s
	#
	echo ""
	return 0;
}

update_all_repos () {
	echo ""
	echo "Update_all_repos()"
	echo""

	CUR_DIR="/opt/maxim/LDE/source"
	cd $CUR_DIR;
	# Let the person running the script know what's going on.
	echo "Pulling in latest changes for all repositories..."
	# Find all git repositories and update it to the master latest revision
	for i in $(find . -name ".git" | cut -c 3-); do
		# We have to go to the .git parent directory to call the pull command
		cd "$i";
		cd ..;
 		doc="/opt/maxim/LDE/source/Documentation";
		br="/opt/maxim/LDE/source/user/buildroot";
		cr=$(pwd);
		#do once, then comment out. Creates build branch
		if [ -z "$1" ]
		then
			git checkout nightly_build;
		else
		#	instead do this, since branch already created
			git checkout -b nightly_build;
		fi
		#Skip Documentation
		if [[ "$doc" == "$cr" ]]; then
			echo "Doc detected, skip"
			cd $CUR_DIR;
			continue;
		fi
		#  pull develop or br2 branch
		if [[ "$br" == "$cr" ]]; then
			git fetch upstream;
			git fetch --tags upstream;
			git pull upstream br2;
		else
			git fetch upstream;
			git fetch --tags upstream;
			git pull upstream develop;
			#git pull upstream bennett1;
		fi
		echo $(pwd);
		check_with_user
		echo ""
		# lets get back to the CUR_DIR
		cd $CUR_DIR
	done
	echo "Complete!"
	return 0;
}

create_new_output_dir () {
	echo ""
	echo "create_new_output_dir()"
	echo ""

	output_dir='';
	get_build_name output_dir;
	echo [ $output_dir ]
	ldecmd create jibe $output_dir
	return 0;
}

go_back_to_prior_branch () {
	for i in $(find . -name ".git" | cut -c 3-); do
		#	#go back to original branch
		git checkout -;
	done
	return 0;
}

build_fresh () {
	echo ""
	echo "build_fresh()"
	echo ""

	output_dir='';
	get_build_name output_dir;
	cd $output_dir;
	echo $(pwd);

	touch build_time_start.txt
	date > build_time_start.txt

	#halt
	echo ""
	echo "	ldecmd make -- CFGNAME=hcr4-v1-B5 bootdefconfig"
	echo ""
	check_with_user

	ldecmd make -- CFGNAME=hcr4-v1-B5 bootdefconfig;
	ldecmd defconfig --config=hcr4-v1-B5 kernel;


	#halt
	echo ""
	echo "	ldecmd defconfig --config=hcr4-v1-B5 addon &"
	echo ""
	check_with_user
	ldecmd defconfig --config=hcr4-v1-B5 addon &


	sleep 5;
	echo "Y";
	echo "Y";
	echo "Y";
	echo "Y";
	echo "Y";

	ldecmd defconfig --config=hcr4-v1-B5 buildroot;
	ldecmd defconfig --config=hcr4-v1-B5 rootfs;
	#halt
	echo ""
	echo "	ldecmd build buildroot;"
	echo ""
	check_with_user

	ldecmd build buildroot;

	#halt
	echo ""
	echo "	ldecmd make =hcr4 -- all;"
	echo ""
	check_with_user

	ldecmd make =hcr4 -- all;
	ldecmd make =ct-l2 -- all;
	ldecmd make =hcr4 -- all;
	ldecmd build addon;
	ldecmd make -M-w =secureboot-jibe -- all;
	ldecmd make -- bootstrap;
	ldecmd build rootfs;
	ldecmd build kernel;

	ldecmd install kernel;
	ldecmd install addon;
	ldecmd install rootfs;
	ldecmd build kernel;

	touch build_time_end.txt
	date > build_time_end.txt
	cd $CUR_DIR
	return 0;
}


#main

update_all_repos
create_new_output_dir
build_fresh

