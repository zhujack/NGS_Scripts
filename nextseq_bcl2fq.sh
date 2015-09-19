#$ -S /bin/bash
#$ -j y

## covert nextseqR bcl2fq and merge fq


if [ $# -lt 1 ]
then
    echo "Usage: `basename $0` <runDir> [outDir]"
    exit 65
fi

cwd=`pwd`

runDir=$1
run=`basename ${runDir}`
flowcell=${run##*_}
runDate1=${run%%_*}
runDate="20${runDate1:0:2}-${runDate1:2:2}-${runDate1:4:2}"

## outDir
if [ $# -gt 1 ]
then
    outDir=$2
else
	outDir="/home/analysis/Solexa/fastq"
fi

if [ ! -d $outDir ]; then
	mkdir $outDir
fi

tmpDir=${runDir}/Data/Intensities/BaseCalls/fastq

if [ ! -d $tmpDir ]; then
	mkdir $tmpDir
fi

cd $tmpDir

## move SampleSheet.csv
if [ -f ${runDir}/SampleSheet.csv ]; then
	mv ${runDir}/SampleSheet.csv ${runDir}/SampleSheet_backup.csv
fi

## determine read number
nReads=`grep "<Read Number="  ${runDir}/RunInfo.xml | wc -l`
if [ $nReads -eq 2 ];then
	maskStr='y*,y*'
elif [ $nReads -eq 3 ];then
	maskStr='y*,y*,y*'
elif [ $nReads -eq 4 ];then
	maskStr='y*,y*,y*,y*'
fi

bcl2fastq -R ${runDir} -o $tmpDir -l WARNING -p 32  --create-fastq-for-index-reads --no-lane-splitting --use-bases-mask $maskStr --mask-short-adapter-reads 6

if [ -f Undetermined_S0_R1_001.fastq.gz ];then
	mv Undetermined_S0_R1_001.fastq.gz ${outDir}/X_1_${flowcell}.NEXTSEQ-${runDate}.fq.gz
else
	mail -s "No fastq files generated from bcl2fastq: $run" zhujack@mail.nih.gov <<< ""
    exit 65
fi

if [ -f Undetermined_S0_R2_001.fastq.gz ];then
	mv Undetermined_S0_R2_001.fastq.gz ${outDir}/X_2_${flowcell}.NEXTSEQ-${runDate}.fq.gz
fi

if [ -f Undetermined_S0_R3_001.fastq.gz ];then
	mv Undetermined_S0_R3_001.fastq.gz ${outDir}/X_3_${flowcell}.NEXTSEQ-${runDate}.fq.gz
fi

if [ -f Undetermined_S0_R4_001.fastq.gz ];then
	mv Undetermined_S0_R4_001.fastq.gz ${outDir}/X_4_${flowcell}.NEXTSEQ-${runDate}.fq.gz
fi

## remove the fastq folder
#rm -rf $tmpDir

mail -s "bcl2f done: $run" wangyong@mail.nih.gov,zhujack@mail.nih.gov <<< ""
#mail -s "bcl2f done: $run" zhujack@mail.nih.gov <<< ""

