#!/bin/bash

APP_NAME=$(pwd | awk -F'/' '{print $NF}')
QM_TARGET=localization
TS_SOURCES=localization-sources

echo "Running QM generator for app '${APP_NAME}'"

if [ ! -d $QM_TARGET ]
then
    echo "Creating qm target '${QM_TARGET}'..."
    mkdir $QM_TARGET
fi

echo "Release languages as idbased qm files..."
for i in $(ls ${TS_SOURCES}); do lrelease -idbased ${TS_SOURCES}/$i -qm ${QM_TARGET}/$(echo $i | awk -F'_' '{print $2 "_" $3}' | awk -F'.' '{print $1}').qm; done
