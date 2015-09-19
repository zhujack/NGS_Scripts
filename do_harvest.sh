#!/bin/bash
## 18000 = 5 hours

timeCutoff=$(( 60 * 60 * 4 ))
#timeCutoff=$(( 116770 + 60 ))

n=0
for f in /home/solexa/[0-9][0-9][0-9][0-9][0-9][0-9]_*_[0-9][0-9][0-9][0-9]_*
do
RTAfile="${f}/RTAComplete.txt"
if [ -f "$RTAfile" ]; then
    modsecs=$(date --utc --reference=$RTAfile +%s)
    nowsecs=$(date +%s)
    RTA_time_past=$(($nowsecs-$modsecs))
else
    RTA_time_past=$timeCutoff
fi

# echo $f
# echo $RTA_time_past

run=${f##*/}
flowcell=${run/*_/}

if [ $RTA_time_past -lt $timeCutoff ]; then
    echo $run
    if [[ ! $run =~ "_NS500" ]]; then
        # continue
        fn=`ls -l /home/analysis/Solexa/sequence/*${flowcell}* | wc -l | cut -f1`
        if [ "$fn" == 0 ]; then
            #qsub -cwd  -pe smp 8 -l arch=lx* -l io=0.1 -N "PRO.${flowcell/000000000-/}" -q lowp.q /home/zhujack/bin/harvest.sh $f
            ((n++))
            echo "To be processed: $run"
            mail -r noreply@meltzerlab.nih.gov -s "New non-NextSeq run to be processed: $run" wangyong@mail.nih.gov,zhujack@mail.nih.gov <<< ""
        fi
    else
        echo $run 

        ### harvest
        cd /home/solexa
        tarFile=`ls -l /home/analysis/Solexa/sequence/X_X_${flowcell}* | wc -l`
        if [ $tarFile -eq 0 ]; then
            # qsub -cwd -pe smp 8 -l arch=lx* -l io=0.05 -N "harvest.pl" -b y perl -I ~/bin ~/bin/harvest.pl $run
            perl -I ~/bin ~/bin/harvest.pl $run
            mail -r noreply@meltzerlab.nih.gov -s "Harvest started: $run" zhujack@mail.nih.gov <<< ""
        fi
        
        tarFile=`ls -l /home/analysis/Solexa/sequence/X_X_${flowcell}* | wc -l`
        if [ $tarFile -ne 0 ]; then
            mail -r noreply@meltzerlab.nih.gov -s "Harvest done: $run" zhujack@mail.nih.gov <<< ""
            ## update solDB_flowCellBasecallLane
            echo "Updated flowCellBasecallLane on $(date +%c)" >> /home/zhujack/log/solDB_flowCellBasecallLane_update.log
            mysql -h sartre.nci.nih.gov -u zhujack -pmicroarray soldb < /home/zhujack/bin/solDB_flowCellBasecallLane_update.sql >> /home/zhujack/log/solDB_flowCellBasecallLane_update.log  2>&1
            
            cd /home/zhujack/temp
            ## cron problem
            /import/cluster/sge6_2u5/default/common/settings.sh
            export SGE_ROOT=/import/cluster/sge6_2u5
            /import/cluster/sge6_2u5/bin/lx24-amd64/qsub -cwd -pe smp 24-32 -m e -l arch=lx* -l io=0.01 -N "bcl2fq.${flowcell}" -q lowp.q@steinbeck.nci.nih.gov,lowp.q@neruda.nci.nih.gov,lowp.q@marquez.nci.nih.gov,lowp.q@mueller.nci.nih.gov ~/bin/nextseq_bcl2fqD_new.sh $f
        else
            mail -r noreply@meltzerlab.nih.gov -s "Harvest failed: $run" zhujack@mail.nih.gov <<< ""
        fi
        ((n++))
    fi
fi
done

echo "`date`: Total runs to be processed: $n"

# for f in /home/solexa/[0-9][0-9][0-9][0-9][0-9][0-9]_*_[0-9][0-9][0-9][0-9]_*
# do
#     echo $f;
# done
