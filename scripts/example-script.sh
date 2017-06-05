display_usage () {
  echo "================================================"
  echo "Usage: sudo sh $0 -e env -p git_proj -b git_branch -l location -m svn_method"
  echo "Example: sudo sh $0 -e stg4 -p attorney-portal -b release -l hq -m checkout"
  echo "         -e     Environment name [stg(1-5)|prod|devtest], required"
  echo "         -p     Git project"
  echo "         -b     Git branch"
  echo "         -l     Location of the staging environment [pls|hq]"
  echo "         -m     Method of SVN checkout [checkout|export], required"
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

######### options #########
while getopts ":e:p:b:l:m:" option ; do
  case $option in
    e ) environment=$OPTARG ;;
    p ) git_proj=$OPTARG ;;
    b ) git_branch=$OPTARG ;;
    l ) location=$OPTARG ;;
    m ) svn_method=$OPTARG ;;
    * ) display_usage "missing a required flag" ; exit 1 ;;
  esac
done

######## validate #########
ENV_REGEX="^(stg[1-5]|prod|devtest)$"
LOCATION_REGEX="^(pls|hq)$"
METHOD_REGEX="^(checkout|export)$"
GIT_BRANCH_REGEX="^(dev1|master|staging|release|smb)$"
if [[ ! $environment =~ $ENV_REGEX ]]
then
  display_usage "incorrect environment supplied"
  exit 1
fi
if [ $environment != 'prod' ]
then
  if [[ ! $location =~ $LOCATION_REGEX ]]
  then
    display_usage "incorrect location supplied"
    exit 1
  fi
fi
if [[ ! $svn_method =~ $METHOD_REGEX ]]
then
  display_usage "incorrect method supplied"
  exit 1
fi
if [[ ! $git_branch =~ $GIT_BRANCH_REGEX ]]
then
  display_usage "supplied git branch is not supported"
  exit 1
fi

######## variables ########
doc_root='/var/www'
git_base="https://git.internetbrands.com/nolo"

date=`date +%Y%m%d%H%M`
type=${environment^^}
project="noloaps"
git_proj_slug="$(sed s/[\/\.]/_/g <<<$git_proj)"
server_root="releases/$project/$date-$type-$git_proj_slug"
releases_to_keep=4

# does not rely on a hosts file :)
make_hosts_file='false'

######## functions #########
. $doc_root/scripts/common/functions.sh

######### main ############
echo "doing $project...."
cd_func $doc_root
sudo git clone $git_base/${git_proj}.git --branch $git_branch $server_root

# remove some files and directories in SVN and replace with a symlinks
echo "handling .env stuff"

# rm /var/www/ncms/.env
# cp /var/www/ncms/.env.stg .env
# update .env file and change any setting you see fit, e.g. database, stage to stg(x) etc..

cd_func $doc_root/$server_root/app/$project
rm_func .env
if [ $environment == 'prod' ] ; then
   cp_func /var/www/conf/noloaps/config/env.prod .env
else
   get_env_num $environment
   cp_func .env.stage .env
   if [ $location == 'hq' ] ; then
      sudo /bin/sed "s/stage-db/stg-nolodb$ENV_SUBSTR/" -i .env
      sudo /bin/sed "s/stage-apsdb/stg-nolopgdb$ENV_SUBSTR/" -i .env
      sudo /bin/sed "s/stage-noloredis/stg-noloredis$ENV_SUBSTR/" -i .env
   else
      sudo /bin/sed "s/stage-db/$environment-nolodb.nolo.org/" -i .env
      sudo /bin/sed "s/stage-apsdb/$environment-nolopgdb.nolo.org/" -i .env
      sudo /bin/sed "s/stage-noloredis/$environment-noloredis1/" -i .env
   fi
   sudo /bin/sed "s/stage-nolo-kafka/stg-nolo-kafka$ENV_SUBSTR/" -i .env
   sudo /bin/sed "s/stage/$environment/" -i .env
fi

## database configs
#cd_func $doc_root/$server_root/app/$project/config
#cp_func database.php database.php.orig
#rm_func database.php
#cp_func $doc_root/conf/php/database.php .

# chown dirs
chown_func nolo.nolo $doc_root/$server_root

##laravel stuff
cd_func $doc_root/$server_root/app/$project
#clean app
php artisan clear-compiled
php artisan route:clear
php artisan config:clear
#clear laravel views and cache
php artisan view:clear
php artisan cache:clear
# clear laravel sessions
rm_func storage/framework/sessions/*
#pick up any new classes
composer dump-autoload -o --no-dev
#optimize app
php artisan optimize --force
php artisan route:cache
# don't cache config because of issues
#php artisan config:cache

# repoint prod link to this new release
echo "creating symlink: $doc_root/$project --> $server_root"
cd_func $doc_root
sudo unlink $project
symlink_func $server_root $project

# storage dir needs to be writable and maybe moved to /dev/shm
cd_func $doc_root/$project/app/$project/storage
rm_func /var/local/$project/framework
mv_func framework /var/local/$project
symlink_func /var/local/$project/framework framework
#chown_func apache.nolo $doc_root/$server_root/storage
cd_func $doc_root/$project/app/$project
chown_func apache.nolo storage
chown_func apache.nolo /dev/shm/$project
chown_func apache.nolo bootstrap/cache

# write application logs to /var/log/httpd (so it will be automatically rotated)
cd_func $doc_root/$project/app/noloaps/storage/logs
rm_func laravel.log
symlink_func /var/log/httpd/laravel.log laravel.log
symlink_func /var/log/httpd/laravel-fcm.log laravel-fcm.log

if [ "$make_hosts_file" == "true" ] ; then
   make_hosts_file $environment $location
fi

# hide .git for IB security requirements
   cd_func $doc_root/$project
   mv_func .git git.$date-$type

# delete old releases to save space
trim_releases_func $doc_root/releases/$project $releases_to_keep

echo "build done: $date-$type $environment $location"