#!/bin/bash

# To create a new package, you must first do:
# 	./mkpkg.sh -set
# that records the current files in the rootfs in file "rootfsfiles.lst"
# than, do:
# 	make O=... menu-config
# and add the package to buildroot, then do:
# 	make O=...
# to build the package and populate the rootfs, then do:
# 	./mkpkg.sh <pkg>
# where <pkg> is the lower case name of the buildroot package name.
# You must then edit and correct ipkfiles/<pkg>.control, add any
# <pkg>.{conffiles | preinst | postinst | prerm | postrm} files
# and recreate the package:
# 	./mkpkg.sh <package name>
# 	
# If package "a" depends on package "b", you must first create the package
# "b", with the above procedure, and then create the package "a" 
# 
# If the file contents of a package changes, do:
# 	rm ipkfiles/<pkg>.lst
# and recreate the package:
# 	./mkpkg.sh <package name>
# This assumes that the rootfs file list, rootfsfiles.lst, is still valid.
# 
# A end user package, to appear in the web pages,
# must have the following files:
# 1 /etc/init.d/S8?<pkgname> with a field "TYPE=user"
# 2 /etc/<pkgname>.conf
# 3 /sbin/rc<pkgname> as a link to /usr/sbin/rcscript
#   this is done at boot time, must also be created at
#   install time, use ipkg postinst script?
# 4 /usr/www/cgi-bin/<pkgname>.cgi
# 5 /usr/www/cgi-bin/<pkgname>_proc.cgi

#set -x
set -u

usage() {
	echo -e "usage: mkpkg.sh <package> |
	-rm <package> (remove from rootfs files from <pkg> |
	-ls <package> (list package file contents) |
	-set (store current rootfs file list) |
	-clean (remove new files since last -set) |
	-diff (show new files since last -set) |
	-force <package> (force create package. You must first create the .control file) |
	-setroot (creates rootfs base file list) |
	-cleanroot (remove all files not in rootfs base file list) |
	-diffroot (show new files since last -setroot) |
	-index (create ipkg package index) |
	-all (recreates all packages in ipkfiles dir) |
	-rmall (remove from rootfs files from all packages) |
	-help"
	exit 0
}

if test "$(dirname $0)" != "."; then
	echo "This script must be run in the root of the tree, exiting."
	exit 1;
fi

if test -z "$BLDDIR"; then
	cat<<-EOF
		Set the environment variable BLDDIR to the build directory, e.g
		   export BLDDIR=<path to where you which the build dir>\nkeep it out of this tree."
		exiting.
	EOF
	exit 1
fi

if test $# = 0; then
	usage
fi

mkdir -p pkgs

CDIR=$(pwd)
PATH=$CDIR/bin:$PATH
IPKGDIR=$CDIR/ipkgfiles

ROOTFSFILES=$CDIR/rootfsfiles-base.lst
ROOTFSDIR=$BLDDIR/project_build_arm/dns323/root
TFILES=$CDIR/rootfsfiles.lst
PFILES=$CDIR/pkgfiles.lst

force=n

case "$1" in
	-rm)
		if test $# != 2 -o ! -f $IPKGDIR/$2.lst; then
			usage
		fi
		cd $ROOTFSDIR
		# remove files first
		xargs --arg-file=$IPKGDIR/$2.lst rm -f >& /dev/null
		# and then empty directories. reverse sort to remove subdirs first
		cat $IPKGDIR/$2.lst | sort -r | xargs rmdir >& /dev/null
		exit 0
		;;

	-ls)
		if test $# != 2 -o ! -f $IPKGDIR/$2.lst; then
			usage
		fi
		cd $ROOTFSDIR
		xargs --arg-file=$IPKGDIR/$2.lst ls
		exit 0
		;;

	-set)
		cd $ROOTFSDIR
		if test -f $TFILES; then
			mv $TFILES $TFILES-
		fi
		#find . ! -type d | sort > $TFILES
		find . | sort > $TFILES
		chmod -w $TFILES
		exit 0
		;;

	-diff)
		cd $ROOTFSDIR
		TF=$(mktemp)
		#find . ! -type d | sort > $TF
		find . | sort > $TF
		diff $TFILES $TF | sed -n 's\> ./\./\p'
		rm $TF
		exit 0
		;;

	-clean)
		tf=$(mktemp -t)
		cd $ROOTFSDIR
		find . | cat $TFILES - | sort | \
			uniq -u | xargs rm >& $tf
		awk '/Is a directory/{print substr($4,2,length($4)-3)}' $tf | sort -r | xargs rmdir
		rm $tf
		exit 0
		;;

	-force)
		if test "$#" != 2; then usage; fi
		shift
		force=y
		;;

	-setroot)
		# records the current files in the rootfs
		# must be done after the first make with only the base packages configured
		if test -f $ROOTFSFILES; then
			mv $ROOTFSFILES $ROOTFSFILES-
		fi
	
		cd $ROOTFSDIR
		#find . ! -type d | sort > $ROOTFSFILES
		find . | sort > $ROOTFSFILES
		chmod -w $ROOTFSFILES
		exit 0
		;;

	-cleanroot)
		# remove all files found in the rootfs after the last "-setroot"
		# to recreate the rootfs.ext2, a make with the base system configured must be done
		tf=$(mktemp -t)
		cd $ROOTFSDIR
		find . | cat $ROOTFSFILES - | sort | \
			uniq -u | xargs rm >& $tf
		awk '/Is a directory/{print substr($4,2,length($4)-3)}' $tf | sort -r  | xargs rmdir
		rm $tf
		exit 0
		;;

	-diffroot)
		cd $ROOTFSDIR
		TF=$(mktemp)
		#find . ! -type d | sort > $TF
		find . | sort > $TF
		diff $ROOTFSFILES $TF | sed -n 's\> ./\./\p'
		rm $TF
		exit 0
		;;

	-index)
		ipkg-make-index pkgs/ > pkgs/Packages
		exit 0
		;;

	-all)
		for i in $(ls $IPKGDIR/*.lst); do
			p=$(basename $i .lst)
			echo Creating package $p
			./mkpkg.sh $p
			#if test $? = 1; then exit 1; fi
		done
		ipkg-make-index pkgs/ > pkgs/Packages
		exit 0
		;;

	-rmall)
		for i in $(ls $IPKGDIR/*.lst); do
			p=$(basename $i .lst)
			echo Removing files from package $p
			./mkpkg.sh -rm $p
		done
		exit 0
		;;

	-help|--help|-h)
		usage
		sed -n '3,35p' $0
		exit 1
		;;

	-*)
		usage
		;;
esac

if ! test -e $TFILES; then
	echo "file $TFILES not found, read help. Exiting"
	exit 1
fi

ARCH=arm

pkg=$1
PKG=$(echo $pkg | tr '[:lower:]-' '[:upper:]_')

if test "$force" != "y"; then
	PKGMK=$(find $CDIR/package -name $pkg.mk)
	if test -z "$PKGMK"; then
		echo Package $pkg not found, is it a sub-package?
		
		if $(grep -q ^BR2_PACKAGE_$PKG .config); then
			MPKG=$(echo $PKG | cut -f1 -d "_")
			mpkg=$(echo $MPKG | tr '[:upper:]_' '[:lower:]-' )
			MPKGMK=$(find $CDIR/package -name $mpkg.mk)
			if test -z "$MPKGMK"; then
				echo Main Package $mpkg not found, exiting.
				exit 1
			fi
		else
			echo Package $pkg is not configured, exiting.
			exit 1
		fi
		echo $pkg is a sub-package of $mpkg

		PKGDIR=$(dirname $MPKGMK)
		eval $(sed -n '/^'$MPKG'_VERSION[ :=]/s/[ :]*//gp' $PKGDIR/$mpkg.mk)
		version=$(eval echo \$${MPKG}_VERSION)	
	else
		PKGDIR=$(dirname $PKGMK)
		eval $(sed -n '/^'$PKG'_VERSION[ :=]/s/[ :]*//gp' $PKGDIR/$pkg.mk)
		version=$(eval echo \$${PKG}_VERSION)
	fi
fi

if ! test -f $IPKGDIR/$pkg.control; then # first time build

	# create minimum control file. User must edit it
	# and do a new "./mkpkg <package>
	# the "Depends" entry is just a helper, it has to be checked
	# and corrected		

	awk -v ver=$version -v pkg=$pkg '
		BEGIN { deps = "ipkg" }
		/(depends|select)/ && /BR2_PACKAGE/ {
			for (i=1; i<=NF; i++) {
				p = tolower(substr($i,13));
				if (p != "")
					deps = p ", " deps ;
			}
		}
		/\thelp/,/^\w/ {
			a=substr($0,1,1);
			if (a != "" && a != "\t")
				exit;
			else if ($1 != "" && $1 != "help")
				desc = desc $0 "\n";
		}
		END {
			printf "Package: %s\n", pkg;
			printf "Description: %s", desc;
			printf "Version: %s\n", ver;
			if (deps != "")
				printf "Depends: %s\n", deps;
			printf "Architecture: arm\n";
			printf "Priority: optional\n";
			printf "Section: admin\n";
			printf "Source: http://code.google.com/p/alt-f/\n";
			printf "Maintainer: jcard\n";
		}
	' $PKGDIR/Config.in > $IPKGDIR/$pkg.control
elif test "$force" != "y"; then 
	cver=$(awk '/^Version/{print $2}' $IPKGDIR/$pkg.control)
 	if test "$cver" != "$version"; then
		echo "ERROR: $pkg.control has version $cver and built package has version $version."
		exit 1
	fi
else
	version=$(awk '/^Version/{print $2}' $IPKGDIR/$pkg.control)
fi

if ! test -f $IPKGDIR/$pkg.lst; then # first time build
	# create file list
	cd $ROOTFSDIR	
	#find . ! -type d | sort > $PFILES
	find . | sort > $PFILES

	diff $TFILES $PFILES | sed -n 's\> ./\./\p' > $IPKGDIR/$pkg.lst
	cd $CDIR
	rm $PFILES
fi

# in CONTROL:
# configuration files: conffiles (one line per configuration file)
# scripts to execute: preinst, postinst, prerm, and postrm
#	(variable PKG_ROOT defined as root of pkg installation)
#
# in $IPKGDI there will be:
# <pkg>.control, <pkg>.lst, <pkg>.conffiles, 
# <pkg>.preinst, <pkg>.postinst, <pkg>.prerm, <pkg>.postrm

mkdir -p tmp tmp/CONTROL

cd ${BLDDIR}/project_build_arm/dns323
#cd root
#cpio --quiet -pdu $CDIR/tmp < $IPKGDIR/$pkg.lst
# cpio creates needed directories ignoring umask, so use tar
# but using tar with a pipe, if the first tar fails we can't know it,
# so check files first
for i in $(cat $IPKGDIR/$pkg.lst); do
	if ! test -e root/$i; then
		echo "Fail creating $pkg package ($i not found)"
		exit 1
	fi
done

tar -C root -c -T $IPKGDIR/$pkg.lst | tar -C $CDIR/tmp -x
if test $? = 1; then 
	echo Fail creating $pkg package
	exit 1
fi
cd "$CDIR"

for i in control conffiles preinst postinst prerm postrm; do
	if test -f $IPKGDIR/$pkg.$i; then
		cp $IPKGDIR/$pkg.$i tmp/CONTROL/$i
		if test ${i:0:1} = "p"; then
			chmod +x tmp/CONTROL/$i
		fi
	fi
done

ipkg-build -o root -g root tmp

mv ${pkg}_${version}_${ARCH}.ipk pkgs
rm -rf tmp

# my own "sm" ipkg-build
#tar -C ${BLDDIR}/project_build_arm/dns323/root -T $IPKGDIR/$pkg.lst -czf data.tar.gz
#tar -czf control.tar.gz ./control
#echo "2.0" > tmp/debian-binary
#ar -crf ${pkg}_${version}_arm.ipk ./debian-binary ./data.tar.gz ./control.tar.gz 
#rm data.tar.gz control control.tar.gz debian-binary
