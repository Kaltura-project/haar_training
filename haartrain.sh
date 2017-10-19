#!/bin/bash

HELP="Usage:\n
haartrain.sh\n
\t-C\tCleanup various file formats\n
\t  -p\tPositive images directory\n
\t  -n\tNegative images directory\n
\t-S\tSetup training data\n
\t  -p\tPositive images directory\n
\t  -n\tNegative images directory\n
\t  -P\tNumber of positive samples\n
\t  -N\tNumber of negative samples\n
\t-T\tTrain classifier\n
\t  -P\tNumber of positive samples\n
\t  -N\tNumber of negative samples\n
\t  -t\tNumber of stages\n
\t-h\tHelp\n"

while getopts "CSTp:n:P:N:t:h" OPTION
do
	case $OPTION in
		C)
			CLEAN=true
			;;
		S)
			SETUP=true
			;;
		T)
			TRAIN=true
			;;
		p)
			POSITIVESDIR=$OPTARG
			;;
		n)
			NEGATIVESDIR=$OPTARG
			;;
		P)
			POSSAMPLES=$OPTARG
			;;
		N)
			NEGSAMPLES=$OPTARG
			;;
		t)
			STAGES=$OPTARG
			;;
        h)
			echo -e $HELP
	esac
done

function cleanup {
	FORMATS=(".JPG" ".png" ".PNG")
	for i in "${FORMATS[@]}";
	do
		if [ -v POSITIVESDIR ];
		then
			mogrify -format jpg $POSITIVESDIR*$i
			rm $POSITIVESDIR*$i
		fi
		if [ -v NEGATIVESDIR ];
		then
			mogrify -format jpg $NEGATIVESDIR*$i
			rm $NEGATIVESDIR*$i
		fi
	done
}

function setup {
	cd $(dirname $0)
	EXTEND="_extra/"
	NEWNEG=${NEGATIVESDIR:0:${#NEGATIVESDIR}-1}$EXTEND
	mkdir $NEWNEG
	echo $NEWNEG
	python3 negatives.py $NEGATIVESDIR $NEWNEG
	find $POSITIVESDIR -iname *.jpg > positives.txt
	find $NEWNEG -iname *.jpg > negatives.txt
	mkdir "samples"
	perl bin/sonots/createtrainsamples.pl positives.txt negatives.txt samples $NEGSAMPLES  "opencv_createsamples -bgcolor 0 -bgthresh 0 -maxxangle 1.1 -maxyangle 1.1 maxzangle 0.5 -maxidev 40 -w 40 -h 40"
	python3 bin/mergevec/mergevec.py -v samples -o train.vec
}

function train {
	opencv_traincascade -data classifier -vec train.vec -bg negatives.txt -numStages $STAGES -minHitRate 0.999 -maxFalseAlarmRate 0.5 -numPos $POSSAMPLES -numNeg $NEGSAMPLES -w 40 -h 40 -mode ALL -precalcValBufSize 1024 -precalcIdxBufSize 1024
}

if [[ "$CLEAN" == "true" ]]; then
	cleanup
elif [[ "$SETUP" == "true" ]]; then
	setup
elif [[ "$TRAIN" == "true" ]]; then
	train
else
	echo -e $HELP
fi
