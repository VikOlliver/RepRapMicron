#!/bin/sh
# Takes the Prusa GCODE as the first parameter, sends it to a python filter
#
# Put some debug info where we can check it if things go bad
echo Prusaslicer.filter >/tmp/x
date >> /tmp/x
echo $* >>/tmp/x
# Make a new temporary file for the modified GCODE
NEW_FNAME=${1}$$
echo Creating ${NEW_FNAME} >> /tmp/x
# Call the python filter and put the output in temporary file
/home/vik/uRepRap/gcode_segmentation/dipify_gcode.py $1 > ${NEW_FNAME}
# Get rid of the original, and copy our hacked file over it
rm -f ${1}
cp ${NEW_FNAME} ${1}
# Save a copy for debugging
cp ${NEW_FNAME} /tmp/mod.gcode
# Get rid of the temporary file
rm -f ${NEW_FNAME}
