#!/bin/bash

set -x

###############################################################
## Abstract:
## Create FV3 initial conditions from GFS intitial conditions
## RUN_ENVIR : runtime environment (emc | nco)
## HOMEgfs   : /full/path/to/workflow
## EXPDIR : /full/path/to/config/files
## CDATE  : current date (YYYYMMDDHH)
## CDUMP  : cycle name (gdas / gfs)
## PDY    : current date (YYYYMMDD)
## cyc    : current cycle (HH)
###############################################################

###############################################################
# Source FV3GFS workflow modules
. $HOMEgfs/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

export DATAROOT="$RUNDIR/$CDATE/$CDUMP"
[[ ! -d $DATAROOT ]] && mkdir -p $DATAROOT

###############################################################
# Source relevant configs
configs="base fv3ic wave"
for config in $configs; do
    . $EXPDIR/config.${config}
    status=$?
    [[ $status -ne 0 ]] && exit $status
done

###############################################################
# Source machine runtime environment
. $BASE_ENV/${machine}.env fv3ic
status=$?
[[ $status -ne 0 ]] && exit $status

# Create ICSDIR if needed
[[ ! -d $ICSDIR/$CDATE ]] && mkdir -p $ICSDIR/$CDATE
[[ ! -d $ICSDIR/$CDATE/ocn ]] && mkdir -p $ICSDIR/$CDATE/ocn
[[ ! -d $ICSDIR/$CDATE/ice ]] && mkdir -p $ICSDIR/$CDATE/ice

if [ $ICERES = '025' ]; then
  ICERESdec="0.25"
fi 
if [ $ICERES = '050' ]; then         
 ICERESdec="0.50"        
fi 
if [ $ICERES = '100' ]; then         
 ICERESdec="1.00"        
fi 

# Setup ATM initial condition files
if [ $MEMBER -le 0 ]; then
   cp -r $ORIGIN_ROOT/$CPL_ATMIC/$CDATE/$CDUMP  $ICSDIR/$CDATE/
else
   charnanal=mem`printf %3.3i $MEMBER`
   cp -r -L $ORIGIN_ROOT/${CASE}_L64/$CDATE/$charnanal $ICSDIR/$CDATE/INPUT
fi

# Setup Ocean IC files 
if [ $MEMBER -le 0 ]; then
   cp -r $ORIGIN_ROOT/$CPL_OCNIC/$CDATE/ocn/$OCNRES/MOM*.nc  $ICSDIR/$CDATE/ocn/
else
   if [ $OCNENS = ".true." ]; then
      cp -r $ORIGIN_ROOT/mx${OCNRES}/$CDATE/${charnanal}/MOM6.mx${OCNRES}.ic.nc  $ICSDIR/$CDATE/ocn/
   else
      cp -r $ORIGIN_ROOT/mx${OCNRES}/$CDATE/MOM6.mx${OCNRES}.ic.nc  $ICSDIR/$CDATE/ocn/
   fi
fi

#Setup Ice IC files 
if [ $ICERES = '100' ]; then # Phil's ics
   cp $ORIGIN_ROOT/mx${ICERES}/$CDATE/cice5_model_${ICERESdec}.ic.nc $ICSDIR/$CDATE/ice/cice5_model_${ICERESdec}.res_$CDATE.nc
else
   cp $ORIGIN_ROOT/$CPL_ICEIC/$CDATE/ice/$ICERES/cice5_model_${ICERESdec}.res_$CDATE.nc $ICSDIR/$CDATE/ice/
fi

if [ $cplwav = ".true." ]; then
  [[ ! -d $ICSDIR/$CDATE/wav ]] && mkdir -p $ICSDIR/$CDATE/wav
  for grdID in $waveGRD
  do
    cp $ORIGIN_ROOT/$CPL_WAVIC/$CDATE/wav/$grdID/*restart.$grdID $ICSDIR/$CDATE/wav/
  done
fi

if [ $MEMBER -le 0 ]; then
   export OUTDIR="$ICSDIR/$CDATE/$CDUMP/$CASE/INPUT"
else # phil's ensemble ics
   export OUTDIR="$ICSDIR/$CDATE/INPUT"
fi


# Stage the FV3 initial conditions to ROTDIR
COMOUT="$ROTDIR/$CDUMP.$PDY/$cyc"
[[ ! -d $COMOUT ]] && mkdir -p $COMOUT
cd $COMOUT || exit 99
rm -rf INPUT
$NLN $OUTDIR .

##############################################################
# Exit cleanly

set +x
exit 0
