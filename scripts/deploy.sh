##eventually will want to add apt-get installs/uninstalls to this as well

display_usage () {
	echo "================================================"
	echo "================================================"
	if [ -n "${1+set}" ]; then
		echo ""
		echo "PROBLEM --> $1"
		echo ""
	fi
}

########## usage ##########
if [ "$#" -lt 1 ]
then
  display_usage "too few arguments supplied"
  exit 1
fi
if [[ $(id -u) -ne 0 ]]
then
  display_usage "$0 must be run as root"
  exit 1
fi

######## variables ########
doc_root='/var/www/hub'
git_base="https://github.com/NickH10/"

######### main ############
cd_func $doc_root
sudo git clone $git_base/${git_proj}.git --branch $git_branch $server_root