
INSERT INTO `soldb`.`flowCellBasecallLane` 
(basecallId,lane,Remark,readnumber,fastqFile,basecallFile) 

SELECT
L.basecallId,
L.lane,
L.Remark,
1 as readnumber,
REPLACE(L.fastqFile, 'X_1_', 'X_2_') as fastqFile,
L.basecallFile
FROM  flowCellBasecallLane L,  flowCellBasecall B
WHERE
L.basecallID=B.id AND L.fastqFile LIKE 'X_1_%'
AND B.nread > 1

UNION

SELECT 
L.basecallId,
L.lane,
L.Remark,
2 as readnumber,
REPLACE(L.fastqFile, 'X_1_', 'X_3_') as fastqFile,
L.basecallFile
FROM  flowCellBasecallLane L,  flowCellBasecall B
WHERE
L.basecallID=B.id AND L.fastqFile LIKE 'X_1_%'
AND B.nread > 2

UNION

SELECT 
L.basecallId,
L.lane,
L.Remark,
3 as readnumber,
REPLACE(L.fastqFile, 'X_1_', 'X_4_') as fastqFile,
L.basecallFile
FROM  flowCellBasecallLane L,  flowCellBasecall B
WHERE
L.basecallID=B.id AND L.fastqFile LIKE 'X_1_%'
AND B.nread > 3

ON DUPLICATE KEY UPDATE 

basecallId=values(basecallId), 
lane=values(lane),
Remark=values(Remark), 
readnumber=values(readnumber),
fastqFile=values(fastqFile),
basecallFile=values(basecallFile)