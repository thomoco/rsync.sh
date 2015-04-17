#!/bin/sh -x
#
# rsync.sh
# thom o'connor
# modified: 2006/01/20
# rsync filesystems - keep two filesystems in sync
#  - useful for backups
#  - run out of cron:
#  15 0 * * 2 /usr/local/bin/rsync.sh -s / -d /backup/rsync/root
#

PATH=/usr/bin:/bin:/usr/sbin:/usr/local/bin
export PATH

usage()
{
        echo "Usage: rsync.sh [-p <port>] -s <source location> <local storage location>"
        exit 1
}

if [ -z "$1" ]; then
	usage
fi

# getopt
while [ $# -ge 1 ]; do
   case $1 in
      -p)       shift;  PORT="$1" ;;
      -s)       shift;  DIR="$1" ;;
      -d)       shift;  LOCAL="$1" ;;
      -*)       usage ;;
      *)        usage ;;
   esac
   shift
done

echo "Starting rsync:"
DATE="`date`"

if [ -z "$DIR" -o -z "$LOCAL" ]; then
	usage
fi

if [ -z "$PORT" ]; then
	PORT=22
fi

if [ -n "`echo $DIR | grep ':' 2>/dev/null`" ]; then
	SOURCEHOST="`echo $DIR | awk -F':' '{print $1}'`"
	SOURCEDIR="`echo $DIR | awk -F':' '{print $2}'`"
	DIRNAME="$SOURCEHOST-$SOURCEDIR"
else
	SOURCEDIR="$DIR"
	DIRNAME="$SOURCEDIR"
fi

# set special SOURCEDIRNAME for logging
SOURCEDIRNAME="`echo $SOURCEDIR | sed -e 's/^\///;' | \
	sed -e 's/\//-/g;'`"
if [ -z "$SOURCEDIRNAME" ]; then
	SOURCEDIRNAME="rootdir"
fi

# defaults
MOUNT=/backup
DESTDIR="/backup/rsync"

if [ -n "$SOURCEHOST" ]; then
	HOSTNAME="$SOURCEHOST"
else
	HOSTNAME="`hostname`"
fi

if [ -n "$LOCAL" ]; then
	FINALDIR="$LOCAL"
	MOUNT="/`echo $LOCAL | awk -F'/' '{print $2}'`"
else
	FINALDIR="$DESTDIR/$HOSTNAME"
fi

# mount if necessary
if [ -z "`mount | awk '$3 == dir {print $0}' dir=$MOUNT`" ]; then
        mount $MOUNT || (echo "Critical Error: cannot mount $MOUNT" && \
           exit 1)
fi

date > $DESTDIR/$HOSTNAME-$SOURCEDIRNAME.log

if [ -n "$SOURCEHOST" ]; then
	rsync -avzSx --delete -e "ssh -p $PORT" $SOURCEHOST:$SOURCEDIR $FINALDIR/ >> \
		$DESTDIR/$HOSTNAME-$SOURCEDIRNAME.log
else
	rsync -avzSx --delete $SOURCEDIR $FINALDIR/ >> \
		$DESTDIR/$HOSTNAME-$SOURCEDIRNAME.log
fi

date >> $DESTDIR/$HOSTNAME-$SOURCEDIRNAME.log

DATE=`date`
umount $MOUNT || echo "Error: Cannot unmount $MOUNT"

exit 0

