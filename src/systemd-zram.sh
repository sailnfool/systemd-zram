#!/bin/sh

# Antonio Galea <antonio.galea@gmail.com>
# Thanks to Przemysław Tomczyk for suggesting swapoff parallelization
# Systemd service and packaging by Manuel Domínguez López <mdomlop@gmail.com>
# Distributed under the GPL version 3 or above, see terms at
#      https://gnu.org/licenses/gpl-3.0.txt

EXECUTABLE_NAME='systemd-zram'
PROGRAM_NAME='Systemd zRAM'
DESCRIPTION='Use compressed RAM as in-memory swap'
#VERSION='1.0'
VERSION='1.1'
#AUTHOR='Manuel Domínguez López'  # See AUTHORS file
AUTHOR='Robert E. Novak'  # See AUTHORS file
#MAIL='mdomlop@gmail.com'
MAIL='sailnfool@gmail.com'
LICENSE='GPLv3+'  # Read LICENSE file.

# You can change the compression algorithm, fraction number and min_2gb by
# editing the systemd service.
DEF_FRACTION=75
DEF_COMP_ALGORITHM='lz4'
DEF_MIN_2X='no'

test -z $FRACTION && FRACTION=$DEF_FRACTION
test -z $COMP_ALGORITHM && COMP_ALGORITHM=$DEF_COMP_ALGORITHM
test -z $MIN_2X && MIN_2X=$DEF_MIN_2X

CORES=`nproc --all`
TOTALMEM=`free | grep -e "^Mem:" | awk '{print $2}'`
MEM=`expr \( $TOTALMEM / $CORES \) '*' 1024`
#MEM=$(( ($TOTALMEM / $CORES) * 1024 ))
#MEMORY=`grep ^MemTotal: /proc/meminfo | awk '{print $2}'`
#CPUS=`nproc`
#SIZE=$(( MEMORY * FRACTION / 100 / CPUS ))

fallback_comp() {
    echo -n 'Warning: Unsupported compression algorithm selected: '
    echo "$COMP_ALGORITHM, falling back to $DEF_COMP_ALGORITHM."
    COMP_ALGORITHM=$DEF_COMP_ALGORITHM
}

fallback_perc() {
    echo -n 'Warning: Invalid percent value selected: '
    echo "$FRACTION, falling back to $DEF_FRACTION."
    FRACTION=$DEF_FRACTION
}

fallback_min_2gb() {
    echo -n 'Warning: Invalid MIN_2X.  Should be yes|no: '
    echo "$MIN_2X, falling back to $DEF_MIN_2X."
    MIN_2X=$DEF_MIN_2X
}

abort_execution() {
    echo 'Sorry: systemd-zram.service is active. Stop it before executing $EXECUTABLE_NAME'
    exit 1
}

case "$1" in
  "start")

    # Check if systemd-zram.service is active
    # systemctl is-active systemd-zram.service || abort_execution

    if [ ! `systemctl is-active systemd-zram.service` == 'active' ]
    then
	    abort_execution
    fi

    # Check fraction value:
    test \( "$FRACTION" -gt 0 \) -a \( "$FRACTION" -le 100 \) || fallback_perc

    # Check compression algorithm support
    grep -qw "$COMP_ALGORITHM" /sys/block/zram0/comp_algorithm || fallback_comp
    
    ########## - REN
    # Be tolerant of mixed case values in case someone specifies "Yes" or "No"
    # this does not handle the "y|n" case
    ##########
    MIN_2X=`expr $MIN_2X | tr [A-Z] [a-z]`
    if [ \( $MIN_2X != 'yes' \) && \( $MIN_2X != 'no' \) ]
    then
	    fallback_min_2gb
    fi

    ########## - REN
    # if the total memory is less then 2GB, then allocate swap space of
    # at least 2GB * FRACTION to avoid system crashes due to lack of swap
    # space.  This is particularly good at managing browsers with many tabs
    # or many simultaneous applications running.  This was found to be
    # practical when using a Raspberry Pi 3B with 1GB of memory as a desktop
    # machine.
    ##########
    MULTIPLIER=1

    if [ $MIN_2X == 'yes' ]
    then
        TWO_X=`expr 2 \* 1024 \* 1024` 
        
        if [ $TOTALMEM -lt $TWO_X ]
        then
    	    MULTIPLIER=2
        else
    	    MULTIPLIER=1
        fi
    fi

    MEM=`expr \( \( $TOTALMEM \* $MULTIPLIER \* $FRACTION \) / \( $CORES \* 100 \) \) '*' 1024`
    echo "$EXECUTABLE_NAME MEM=$MEM, MULTIPLIER=$MULTIPLIER, FRACTION=$FRACTION, CORES=$CORES"

    modprobe zram num_devices=$CORES

#    modprobe zram num_devices=$CPUS
#    for n in `seq $CPUS`; do
#      i=$((n - 1))
#      echo $COMP_ALGORITHM > /sys/block/zram$i/comp_algorithm
#      echo ${SIZE}K > /sys/block/zram$i/disksize
#      mkswap /dev/zram$i
#      swapon /dev/zram$i -p 10
#    done

    swapoff -a
    CORE=0
    while [ $CORE -lt $CORES ]
    do
	########## - REN
	# When reading the kernel notes on zram, I learned that you can
	# perform a reset on each zram allocation before changing the values
	# of the disksize or compression algorithm:
	# https://www.kernel.org/doc/Documentation/blockdev/zram.txt
	#
	# Hence the sequence is to:
	# 1) reset the zram
	# 2) change the compression algorithm
	# 3) change the disksize
	##########
        zrampath=/sys/block/zram$CORE
        echo "$EXECUTABLE_NAME zrampath=$zrampath"
	echo 1 > $zrampath/reset
	if [ $? -ne 0 ]
	then
		echo "$EXECUTABLE_NAME Reset of /dev/zram$CORE failed"
	fi
	echo $COMP_ALGORITHM > $zrampath/comp_algorithm
	if [ $? -ne 0 ]
	then
		echo "$EXECUTABLE_NAME Failed to set comp_algorithm of /dev/zram$CORE to $COMP_ALGORITHM"
	fi
	echo $MEM > $zrampath/disksize
	if [ $? -ne 0 ]
	then
		echo "$EXECUTABLE_NAME Failed to set disksize of /dev/zram$CORE to $MEM"
	fi
	mkswap /dev/zram$CORE
	if [ $? -ne 0 ]
	then
		echo "$EXECUTABLE_NAME Failed to set mkswap of /dev/zram$CORE"
	fi
	swapon -p 5 /dev/zram$CORE
	CORE=`expr $CORE '+' 1`
    done
    ;;
  "stop")
    CORE=0
    while [ $CORE -lt $CORES ]; do
      swapoff /dev/zram$CORE && echo "disabled disk $CORE of $CORES" &
      CORE=`expr $CORE '+' 1`
    done
#    for n in `seq $CPUS`; do
#      i=$((n - 1))
#      swapoff /dev/zram$i && echo "disabled disk $n of $CPUS" &
#    done
    wait
    sleep .5
    modprobe -r zram
    ;;
  *)
    echo "Usage: $EXECUTABLE_NAME (start | stop)"
    exit 1
    ;;
esac
