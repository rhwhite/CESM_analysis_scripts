#!/bin/sh

#------------------------------------------------------------------
# Simple script to create annual and seasonal climatologies using 
# ncra for CESM data, cam (atmosphere) data
#
# Author: RHWhite rachel.white@cantab.net
#
# Creation date: 2016
#------------------------------------------------------------------

# Specify start and end year for climatologies, being sure to leave enough
# spin-up at the beginning (one year sufficient for fixed SSTs, 10-15 years
# probably sufficient for slab ocean, but you should check your simulation
# output). startyear and endyear are inclusive.
startyear=20
endyear=41

# set flags to 1 to get:
# monthly climatologies (one file per month, averaged over all years from
# startyear to endyear
monthly=0
# seasonal climatologies (one file per season, avagered over all months in
# season and over all years from startyear to endyear
seas=1
# calculate standard deviations for seasonal averages
seasstd=0
# calculate annual average over all month and all year from startyear to
# endyear
ann=1
# calculate standard deviation form annual average
annstd=0

# Specify the name of the experiment, or experiments - note all experiments
# will have the same startyear and endyear
# This script assumes that your experiment name is the name of the
# directory AND the prefix for filenames. This is the default for CESM.
Experiments=("CAM4SOM4_noR")
# Use this format to specify multiply experiments:
#Experiments=("CAM4_f09f09_CTL_ICC14" "CAM4_f09f09_noTWP_FakeSU")

# This script assumes a directory structure:
# ${DirStart}/${Experiment}/${DirInside}/
# Specify root directory
DirStart=${HOME}/CESM_outfiles/
# Specify DirInside (i.e. inside each Experiment directory. This is the
# standard for CESM
DirInside=/atm/hist/


for experi in ${Experiments[@]}; do
    echo $experi
    cd ${DirStart}/${experi}/${DirInside}
    mkdir raw
    mv ${experi}.cam2.h* raw
    cd raw
    mkdir temp
    mv ${experi}* temp/

    for iyear in `seq -f "%04g" $startyear $endyear`; do
        mv temp/${experi}.cam2.h0.${iyear}-??.nc .
    done

    if [ $seas -eq 1 ]; then
        ncra ${experi}.cam2.h0.????-12* ${experi}.cam2.h0.????-01* \
            ${experi}.cam2.h0.????-02* \
            ../DJF${startyear}-${endyear}_mean_${experi}.cam2.h0.nc
        ncra ${experi}.cam2.h0.????-03* ${experi}.cam2.h0.????-04* \
            ${experi}.cam2.h0.????-05* \
            ../MAM${startyear}-${endyear}_mean_${experi}.cam2.h0.nc
        ncra ${experi}.cam2.h0.????-06* ${experi}.cam2.h0.????-07* \
            ${experi}.cam2.h0.????-08* \
            ../JJA${startyear}-${endyear}_mean_${experi}.cam2.h0.nc
        ncra ${experi}.cam2.h0.????-09* ${experi}.cam2.h0.????-10* \
            ${experi}.cam2.h0.????-11* \
            ../SON${startyear}-${endyear}_mean_${experi}.cam2.h0.nc
    fi

    if [ $seasstd -eq 1 ]; then
        for iyear in `seq -f "%04g" $startyear $endyear`; do
            if [ $iyear -eq 0042 ]; then
                 if [ $experi = 'CAM4_f09f09_CTL_ICC14' ]; then
                    echo 'skipping year 42 because the land sea mask is wrong'
                    continue
                fi
            fi
            ncra ${experi}.cam2.h0.${iyear}-12.nc \
                ${experi}.cam2.h0.${iyear}-01.nc \
                ${experi}.cam2.h0.${iyear}-02.nc \
                IndSeas_DJF${iyear}_${experi}.cam2.h0.nc
        
            ncra ${experi}.cam2.h0.${iyear}-03.nc \
                ${experi}.cam2.h0.${iyear}-04.nc \
                ${experi}.cam2.h0.${iyear}-05.nc \
                IndSeas_MAM${iyear}_${experi}.cam2.h0.nc

            ncra ${experi}.cam2.h0.${iyear}-06.nc \
                ${experi}.cam2.h0.${iyear}-07.nc \
                ${experi}.cam2.h0.${iyear}-08.nc \
                IndSeas_JJA${iyear}_${experi}.cam2.h0.nc

            ncra ${experi}.cam2.h0.${iyear}-09.nc \
                ${experi}.cam2.h0.${iyear}-10.nc \
                ${experi}.cam2.h0.${iyear}-11.nc \
                IndSeas_SON${iyear}_${experi}.cam2.h0.nc

        done

        for iseas in 'DJF' 'MAM' 'JJA' 'SON'; do
            ncrcat IndSeas_${iseas}*_${experi}.cam2.h0.nc \
                ${iseas}${startyear}-${endyear}_${experi}.cam2.h0.nc
            cdo timmean ${iseas}${startyear}-${endyear}_${experi}.cam2.h0.nc \
                ${iseas}mean_${startyear}-${endyear}_${experi}.cam2.h0.nc
            cdo timstd ${iseas}${startyear}-${endyear}_${experi}.cam2.h0.nc \
                ${iseas}std_${startyear}-${endyear}_${experi}.cam2.h0.nc
            rm IndSeas_${iseas}*_${experi}.cam2.h0.nc

        done
        
    fi


    if [ $monthly -eq 1 ]; then
		for imonth in `seq -f "%02g" 1 12`; do
			echo $imonth
			ncra ${experi}.cam2.h0.????-${imonth}.nc \
                ../ClimMon${imonth}_${startyear}-${endyear}_${experi}.cam2h0.nc

		done
    fi

    if [ $ann -eq 1 ]; then
        ncra ${experi}.cam2.h0.????-??.nc \
                ../ANN${startyear}-${endyear}_mean_${experi}.cam2.h0.nc

    fi

    if [ $annstd -eq 1 ]; then
        for iyear in `seq -f "%04g" $startyear $endyear`; do
            # Because CAM4_f09f09_CTL_ICC14 is missing year 42
            if [ $iyear -eq 0042 ]; then 
                 if [ $experi = 'CAM4_f09f09_CTL_ICC14' ]; then
                    echo 'skipping year 42 because the land sea mask is wrong'
                    continue
                fi
            fi
            ncra ${experi}.cam2.h0.${iyear}-??.nc \
                    ANN${iyear}_${experi}.cam2.h0.nc
        done
        ncrcat ANN????_${experi}.cam2.h0.nc \
                ../ANN${startyear}-${endyear}_${experi}.cam2.h0.nc
        cdo timmean ../ANN${startyear}-${endyear}_${experi}.cam2.h0.nc \
            ../ANNmean_${startyear}-${endyear}_${experi}.cam2.h0.nc
        cdo timstd ../ANN${startyear}-${endyear}_${experi}.cam2.h0.nc \
            ../ANNstd_${startyear}-${endyear}_${experi}.cam2.h0.nc
        rm ANN????_${experi}.cam2.h0.nc
    fi
   

    mv temp/* .


done
