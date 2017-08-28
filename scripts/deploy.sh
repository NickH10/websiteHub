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
if false
	then

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

fi

######## variables ########
doc_root='/var/www'
git_branch='websiteHub'
git_base="https://github.com/NickH10/$git_branch"

######### main ############
sudo rm -rf "$doc_root/$git_branch"
cd $doc_root
#sudo git clone $git_base/${git_proj}.git --branch $git_branch $server_root
sudo git clone $git_base
sudo chmod -R 777 $doc_root/$git_branch #will want to fix this later
grep -q -F '127.0.0.1 localhost.nick-hughes.com' /etc/hosts || echo '127.0.0.1 localhost.nick-hughes.com' >> /etc/hosts ##change localhost to just nick-hughes.com
sudo ln -s $doc_root/$git_branch/conf/httpd.hub.conf /etc/apache2/sites-enabled/
sudo service apache2 restart
as