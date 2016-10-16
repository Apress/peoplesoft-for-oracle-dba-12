TUXLOG=$PS_HOME/appserv/DEVP8/LOGS
for i in $TUXLOG/TUXLOG.[0-1][0-9][0-3][0-9][0-9][0-9]
  do
    FILE=`basename $i`
    echo "$FILE \c"
    egrep -h "tpservice\(|tpreturn\(" $i | \
awk '{
        elements=split($4,var1,"(");
        if(var1[1]=="tpservice") {
            dir="c->s"
            elements=split($4,var1,"\"");
            service=var1[2]
        }
        if(var1[1]=="tpreturn") {
            dir="s->c"
        }
        elements=split($7,var1,",")
        size=var1[1]
        print dir, service, size
}' | \
    sort -k3n,3 | \
    awk '{
        lineno++
        totsize+=$3
        print lineno, $1, $2, $3, totsize
    }' | \
    sort -rn | \
    awk 'BEGIN{
       printf("Message direction,Service name,Message size (bytes),")
       printf("Proportion of messages not larger than this message,")
       printf("Proportion of traffic in messages not larger than this message\n")
    }{
        if(lines==0) {
            lines=$1
            totsize=$5
            sizeleft=totsize
        }
        if($4>0) {
            printf("%s,%s,%d,%f,%f\n", $2, $3, $4, $1/lines, $5/totsize) 
        }
    }' | \
    tee $FILE.msglen |\
    wc -l
done



