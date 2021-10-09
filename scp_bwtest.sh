#!/usr/bin/env bash

if [[ -z $1 ]]
then
	echo "./speedtest HOST"
	exit 1
fi

HOST=$1

stamp="$(date -u +%s)"

MIN_WAIT=15
ULMB=10
DLMB=10
ULF="${ULMB}Mrandom"
DLF="${DLMB}Mrandom"

echo "Setting up files..."

dd if=/dev/urandom of=$ULF bs=1M count=5
dd if=/dev/urandom of=$DLF bs=1M count=10
scp $DLF $HOST:/tmp/

OF="speedtest-$HOST-$stamp.csv"

TESTCOUNT=0
while true;
do 
	TESTCOUNT=$(( TESTCOUNT + 1 ))
	echo "Starting test $TESTCOUNT..."
	echo "Upload test..."
	test_start="$(date -u +%s)"
	start_time="$(date -u +%s)"
	scp $ULF $HOST:/dev/null
	end_time="$(date -u +%s)"
	ul_elapsed="$(($end_time-$start_time))"
	ul_rate="$((1048576 * $ULMB * 8 / $ul_elapsed))"

	echo -n "Download test..."
	start_time="$(date -u +%s)"
	scp $HOST:/tmp/$DLF /dev/null
	end_time="$(date -u +%s)"
	dl_elapsed="$(($end_time-$start_time))"
	dl_rate="$((1048576 * $DLMB * 8 / $dl_elapsed))"
	echo "$test_start,$ul_elapsed,$ul_rate,$dl_elapsed,$dl_rate" | tee -a $OF
	sleep 1

	test_end="$(date -u +%s)"
	test_elapsed=$(($test_end - $test_start))
	COOLDOWN=$(( $MIN_WAIT - $test_elapsed ))
	if [[ $(( $COOLDOWN > 0 )) ]]
	then
		echo "Sleeping for $COOLDOWN seconds..."
		sleep $COOLDOWN
	fi
done
