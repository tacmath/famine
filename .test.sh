#!/bin/sh


mkdir -p /tmp/test
mkdir -p /tmp/test2
rm -rf /tmp/test/*
rm -rf /tmp/test2/*

./famine
./famine
sleep 0.1
cp /bin/ls /tmp/test
echo -n "expected 0 : "
strings /tmp/test/ls | grep -c Pestilence

./famine
./famine
sleep 0.1
echo -n "expected 1 : "
strings /tmp/test/ls | grep -c Pestilence

cp /bin/uname /tmp/test
/tmp/test/ls > /dev/null
/tmp/test/ls > /dev/null
sleep 0.1
echo -n "expected 1 : "
strings /tmp/test/uname | grep -c Pestilence

cp /bin/pwd /tmp/test2
/tmp/test/uname > /dev/null
sleep 0.1
echo -n "expected 1 : "
strings /tmp/test2/pwd | grep -c Pestilence


rm -rf /tmp/test/*
rm -rf /tmp/test2/*

./resources/test &

./famine
./famine
sleep 0.1
cp /bin/ls /tmp/test
echo -n "expected 0 : "
strings /tmp/test/ls | grep -c Pestilence

./famine
./famine
sleep 0.1
echo -n "expected 0 : "
strings /tmp/test/ls | grep -c Pestilence

cp /bin/uname /tmp/test
/tmp/test/ls > /dev/null
/tmp/test/ls > /dev/null
sleep 0.1
echo -n "expected 0 : "
strings /tmp/test/uname | grep -c Pestilence

cp /bin/pwd /tmp/test2
/tmp/test/uname > /dev/null
sleep 0.1
echo -n "expected 0 : "
strings /tmp/test2/pwd | grep -c Pestilence

pkill test 2>> /dev/null


cp /bin/l* /tmp/test
echo -n "expected [1-200] : "
./famine
sleep 1
strings /tmp/test/* | grep -c Pestilence


cp /sbin/l* /tmp/test2
echo -n "expected [1-200] : "
/tmp/test/ls > /dev/null
sleep 1
strings /tmp/test2/* | grep -c Pestilence



rm -rf /tmp/test/*
rm -rf /tmp/test2/*

./resources/test &

cp /bin/l* /tmp/test
echo -n "expected 0 : "
./famine
sleep 1
strings /tmp/test/* | grep -c Pestilence


cp /sbin/l* /tmp/test2
echo -n "expected 0 : "
/tmp/test/ls > /dev/null
sleep 1
strings /tmp/test2/* | grep -c Pestilence

rm -rf /tmp/test/*
rm -rf /tmp/test2/*

pkill test 2>> /dev/null
