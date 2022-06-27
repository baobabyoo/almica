#!/bin/bash

##### Parameters #########################################

# README -------------------------------------------------
#
#
# Latest update: 2019 Oct. 06 by Baobab Liu
#
# Compatible with outputs of CASA 5.4 and Miriad-carma 4.3.8
# For combining spectral line cubes.
#
#
# It would be very much appreciated if you can cite
# https://ui.adsabs.harvard.edu/abs/2013ApJ...770...44L/abstract
# when using this script
#
#
# Flow ---------------------------------------------------
#
# 1. Convert input data from FITS to Miriad format 
#
# 2. Correct headers if necessary
#
# 3. Generate TP visibilities at ACA pointings
#
# 4. Jointly image ACA and TP visibilities
#
# 5. Re-generate ACA+TP visibilities at 12m pointings
#
# 6. Final imaging
#
# --------------------------------------------------------


# flow control -------------------------------------------
if_fitstomiriad='yes'
if_setheaders='yes'
if_tpdeconvolve='yes'
if_tp2vis='yes'
if_tprewt='yes'
if_duplicateACATP='yes'
if_acaim='yes'
if_acatpscale='yes'
if_tp2almavis='yes'
if_acatprewt='yes'
if_duplicateALL='yes'
if_finalim='yes'
if_cleanup='yes'
if_reimmerge='yes'
# --------------------------------------------------------


# global information -------------------------------------
linerestfreq='115.2179212' # in GHz unit

# set the starting channel and number of channels
ch_start="1"
numch="10"

# set the dimension for the ACA images
aca_cell=0.5
aca_imsize=512

# parameters for deconvolving the TP image
cutoff_tp=0.2
niters_tp=500

# parameters for tp2vis
npts=1500
uvmax=2.5

# parameters for tp2almavis
nptsalma=1500
uvmaxalma=5.0


# --------------------------------------------------------

# 12m data information
path_12m='../data/fits/'
name_12m='mst_12_nchan10_start0kms.ms'
fields_12m=$(seq 1 1 29)
pbfwhm_12m='54.64'

# 7m data information
path_7m='../data/fits/'
name_7m='mst_07_nchan10_start0kms.ms'
fields_7m=$(seq 1 1 11)
pbfwhm_7m='91.08'

# TP data information
path_tp='../data/fits/'
name_tp='TP_12CO.vel'
pbfwhm_tp='54.64'
crval3_tp=167.4129
cdelt3_tp=-0.3175914
crpix3_tp=1
tsys_tp=5000.0
tp_unit_convert="yes"
tp_brightness_unit="Jy/beam"
tp_conv_f=1.0
tp_add_f=0.0


# - - Defining global variables - - - - - - - - - - - - -#
ch='channel,'$numch',1,1,1'
chout='channel,'$numch',1,1,1'

# ACA+TP imaging parameter
acatp_niters=50000
acatp_cutoff=0.04
acatp_method='clean'

# 12m + (ACA+TP) imaging parameter
tsys_acatp=11000.0
alma_cell=0.3
alma_imsize=512
cutoff_alma=0.01
niters_alma=300000000
imaging_method='clean'
acatp_conv_f=0.4

##########################################################



##### Converting FITS data to Miriad format ##############

if [ $if_fitstomiriad == 'yes' ] 
then

   # 12m data
   echo '########## Importing 12m data ##########'
   for field_id in $fields_12m
     do 
	outname=$name_12m'.'$field_id'.uv.miriad'
	rm -rf $outname
        fits in=$path_12m$name_12m'.'$field_id'.uv.fits'  \
	     op=uvin \
	     out=$outname
     done

   # 7m data
   echo '########## Importing ACA data ##########'
   for field_id in $fields_7m
     do
        outname=$name_7m'.'$field_id'.uv.miriad'
        rm -rf $outname
        fits in=$path_7m$name_7m'.'$field_id'.uv.fits'  \
             op=uvin \
             out=$outname
     done

   # TP
   echo '########## Importing TP data ##########'
   outname=$name_tp'.image.miriad'
   rm -rf $outname
   fits in=$path_tp$name_tp'.fits' \
	op=xyin \
	out=$outname

fi

##########################################################



##### Reset headers to allow Miriad processing ###########

if [ $if_setheaders == 'yes' ]
then

   # 12m data
   for field_id in $fields_12m
     do
        pb="gaus("$pbfwhm_12m")"
        puthd in=$name_12m'.'$field_id'.uv.miriad'/telescop \
              value='single' type=a
        puthd in=$name_12m'.'$field_id'.uv.miriad'/pbtype \
              value=$pb type=a
     done

   # 7m data
   for field_id in $fields_7m
     do
        pb="gaus("$pbfwhm_7m")"
        puthd in=$name_7m'.'$field_id'.uv.miriad'/telescop \
	      value='single' type=a
	puthd in=$name_7m'.'$field_id'.uv.miriad'/pbtype \
              value=$pb type=a
     done

   # TP
   puthd in=$name_tp'.image.miriad'/bmaj value=$pbfwhm_tp,arcsec type=double
   puthd in=$name_tp'.image.miriad'/bmin value=$pbfwhm_tp,arcsec type=double
   puthd in=$name_tp'.image.miriad'/bpa  value=0,degree type=double
   puthd in=$name_tp'.image.miriad'/ctype3 value='VELO-LSR' type=ascii
   puthd in=$name_tp'.image.miriad'/cunit3 value='km/s    ' type=ascii
   puthd in=$name_tp'.image.miriad'/crval3 value=$crval3_tp type=double
   puthd in=$name_tp'.image.miriad'/cdelt3 value=$cdelt3_tp type=double
   puthd in=$name_tp'.image.miriad'/crpix3 value=$crpix3_tp type=double

   rm -rf single_input.miriad
   if [ $tp_unit_convert == 'yes' ]
   then
     maths exp="(($name_tp.image.miriad)*$tp_conv_f)" \
	   out=single_input.miriad options=unmask
   else
     cp -r $name_tp'.image.miriad' single_input.miriad
   fi

   puthd in=single_input.miriad/bmaj value=$pbfwhm_tp,arcsec type=double
   puthd in=single_input.miriad/bmin value=$pbfwhm_tp,arcsec type=double
   puthd in=single_input.miriad/bpa  value=0,degree type=double
   puthd in=single_input.miriad/bunit value='Jy/beam' type=ascii

fi

##########################################################



##### Deconvolve TP map ##################################

if [ $if_tpdeconvolve == 'yes' ]
then

   # Generate the TP Gaussian Beam
   rm -rf tp_beam
   imgen out=tp_beam imsize=$aca_imsize cell=$aca_cell \
         object=gaussian \
         spar=1,0,0,$pbfwhm_tp,$pbfwhm_tp,0


   for field_id in $fields_7m
     do
        # Creat template ACA maps for regriding TP maps
        rm -rf single_input.aca_$field_id.temp.miriad
	rm -rf temp.beam
	echo $ch
        invert vis=$name_7m'.'$field_id'.uv.miriad'   \
               imsize=$aca_imsize cell=$aca_cell options=double \
               map=single_input.aca_$field_id.temp.miriad beam=temp.beam line=$ch

	# Regrid TP maps
        rm -rf single_input.aca_$field_id.regrid.miriad       
        regrid in=single_input.miriad tin=single_input.aca_$field_id.temp.miriad \
               out=single_input.aca_$field_id.regrid.miriad \
	       project=sin

        # Deconvolve the TP Map
	rm -rf single_input.aca_$field_id.deconv.miriad
        clean map=single_input.aca_$field_id.regrid.miriad beam=tp_beam \
	      out=single_input.aca_$field_id.deconv.miriad \
	      niters=$niters_tp cutoff=$cutoff_tp gain=0.05

	# Restore the deconvolved TP map for a sanity check
	rm -rf single_input.aca_$field_id.restor.miriad
        restor map=single_input.aca_$field_id.regrid.miriad beam=tp_beam \
	       model=single_input.aca_$field_id.deconv.miriad \
               mode=clean out=single_input.aca_$field_id.restor.miriad

        rm -rf single_input.aca_$field_id.residual.miriad
        restor map=single_input.aca_$field_id.regrid.miriad beam=tp_beam \
               model=single_input.aca_$field_id.deconv.miriad \
               mode=residual out=single_input.aca_$field_id.residual.miriad

	# Apply the ACA primary beam to TP clean models
	rm -rf temp1
	rm -rf single_input.aca_$field_id.demos.miriad
        demos map=single_input.aca_$field_id.deconv.miriad vis=$name_7m'.'$field_id'.uv.miriad' \
	      out=temp
	mv temp1 single_input.aca_$field_id.demos.miriad

     done


     # clean up
     rm -rf temp.beam
     rm -rf tp_beam
     rm -rf single_input.aca_*.temp.miriad

fi

##########################################################



##### Convolve TP map to visibility ######################

if [ $if_tp2vis == 'yes' ]
then

   rm -rf uv_random.miriad
   uvrandom npts=$npts freq=$linerestfreq inttime=10 uvmax=$uvmax nchan=$numch \
            gauss=true out=uv_random.miriad

   
   for field_id in $fields_7m
     do

	rm -rf single_input.aca_$field_id.uvmodel.miriad
#        uvmodel vis=uv_random.miriad model=single_input.aca_$field_id.demos.miriad \
#                'select=uvrange(0,13)' options=replace,imhead \
#                out=single_input.aca_$field_id.uvmodel.miriad
         uvmodel vis=uv_random.miriad model=single_input.aca_$field_id.demos.miriad \
                 options=replace,imhead \
                 out=single_input.aca_$field_id.uvmodel.miriad "select=uvrange(0,$uvmax)" \


        rm -rf temp
        uvputhd vis=single_input.aca_$field_id.uvmodel.miriad hdvar='telescop' \
		varval='TP  ' type=a out=temp
        rm -rf single_input.aca_$field_id.uvmodel.miriad
        mv temp single_input.aca_$field_id.uvmodel.miriad


     done

fi

##########################################################



##### Manually reweight the TP visibilities ##############
if  [ $if_tprewt == 'yes' ]
then

   echo '##### Reweighting TP visibility assuming Tsys ='$tsys_tp' Kelvin'

   for field_id in $fields_7m
     do

	 outname=single_input.aca_$field_id.uvmodel.rewt.miriad
         rm -rf $outname
         uvputhd vis=single_input.aca_$field_id.uvmodel.miriad hdvar=systemp type=r length=1 \
		 varval=$tsys_tp out=$outname
	 puthd in=$outname/jyperk value=1.0 type=r

	 pb="gaus("$pbfwhm_7m")"
         puthd in=$outname/telescop \
               value='single' type=a
         puthd in=$outname/pbtype \
               value=$pb type=a


     done

fi

##########################################################




##### Make a copy of relevant files for imaging ##########
if [ $if_duplicateACATP == 'yes' ]
then

   rm -rf intermediate_vis
   mkdir intermediate_vis

   # ACA
   cp -r $name_7m'.'*'.uv.miriad' ./intermediate_vis/

   # TP
   cp -r single_input.aca_*.uvmodel.rewt.miriad ./intermediate_vis/



fi
##########################################################



##### Imaging ACA and TP visibilities together ###########
if [ $if_acaim == 'yes' ]
then


   rm -rf acatp.map
   rm -rf acatp.beam
   invert "vis=./intermediate_vis/*" options=systemp,double,mosaic \
	  map=acatp.map beam=acatp.beam cell=$aca_cell imsize=$aca_imsize robust=2.0

   rm -rf acatp.model
   if [ $acatp_method == 'clean' ]
   then
       mossdi map=acatp.map beam=acatp.beam out=acatp.model gain=0.1 \
	      niters=$acatp_niters cutoff=$acatp_cutoff options=positive clip=0.3
   else
       mosmem map=acatp.map beam=acatp.beam out=acatp.model rmsfac=1.5 
   fi

   rm -rf acatp.clean
   rm -rf acatp.residual
   restor map=acatp.map beam=acatp.beam model=acatp.model \
	  mode=clean out=acatp.clean
   restor map=acatp.map beam=acatp.beam model=acatp.model \
          mode=residual out=acatp.residual

fi
##########################################################



##### Final ACA+TP flux scaling ##########################

if [ $if_acatpscale == 'yes' ]
then
 
   rm -rf temp
   maths exp="((acatp.model)*$acatp_conv_f)" \
         out=temp options=unmask
   rm -rf acatp.model
   mv temp acatp.model

fi

##########################################################


##### Converting ACA+TP image to 12m visibilities ########
if [ $if_tp2almavis == 'yes' ]
then


   rm -rf uv_random.miriad
   uvrandom npts=$nptsalma freq=$linerestfreq inttime=10 uvmax=$uvmaxalma nchan=$numch \
            gauss=true out=uv_random.miriad


   for field_id in $fields_12m
     do

	rm -rf single_input.alma_$field_id.temp.miriad
	rm -rf temp.beam
        invert vis=$name_12m'.'$field_id'.uv.miriad'   \
               imsize=$alma_imsize cell=$alma_cell \
               map=single_input.alma_$field_id.temp.miriad beam=temp.beam line=$ch

        # applying ALMA primary beam to ACA+TP clean model
	rm -rf acatp.demos
	rm -rf acatp.demos1

	if [ $acatp_method == 'clean' ]
        then
           demos map=acatp.model vis=$name_12m'.'$field_id'.uv.miriad' out=acatp.demos
        else
           demos map=acatp.model vis=$name_12m'.'$field_id'.uv.miriad' out=acatp.demos # options=detaper
        fi

	mv acatp.demos1 acatp.demos

        # regrid ACA+TP maps
        rm -rf single_input.alma_$field_id.regrid.miriad
        regrid in=acatp.demos tin=single_input.alma_$field_id.temp.miriad \
               out=single_input.alma_$field_id.regrid.miriad \
               project=sin


	# simulate visibilities
	rm -rf single_input.alma_$field_id.uvmodel.miriad
        uvmodel vis=uv_random.miriad model=single_input.alma_$field_id.regrid.miriad \
		options=replace,imhead "select=uvrange(0,$uvmaxalma)" \
                 out=single_input.alma_$field_id.uvmodel.miriad


        rm -rf temp
        uvputhd vis=single_input.alma_$field_id.uvmodel.miriad hdvar='telescop' \
                varval='ALMA' type=a out=temp
        rm -rf single_input.alma_$field_id.uvmodel.miriad
        mv temp single_input.alma_$field_id.uvmodel.miriad

	outname=single_input.alma_$field_id.uvmodel.miriad
        pb="gaus("$pbfwhm_12m")"
        puthd in=$outname/telescop \
              value='single' type=a
        puthd in=$outname/pbtype \
              value=$pb type=a


     done



fi
##########################################################



##### Manually reweight the ACA+TP visibilities ##########
if  [ $if_acatprewt == 'yes' ]
then

   echo '##### Reweighting ACA+TP visibility assuming Tsys ='$tsys_acatp' Kelvin'

   for field_id in $fields_12m
     do

         outname=single_input.alma_$field_id.uvmodel.rewt.miriad
         rm -rf $outname
         uvputhd vis=single_input.alma_$field_id.uvmodel.miriad hdvar=systemp type=r length=1 \
                 varval=$tsys_acatp out=$outname
         puthd in=$outname/jyperk value=1.0 type=r

         pb="gaus("$pbfwhm_12m")"
         puthd in=$outname/telescop \
               value='single' type=a
         puthd in=$outname/pbtype \
               value=$pb type=a

     done

fi

##########################################################



##### Duplicating all visibilities for imaging ###########
if [ $if_duplicateALL == 'yes' ]
then

   rm -rf final_vis
   mkdir final_vis

   # 12m
   cp -r $name_12m'.'*'.uv.miriad' ./final_vis/

   # ACA+TP
   cp -r single_input.alma_*.uvmodel.rewt.miriad ./final_vis/

fi
##########################################################



##### Final imaging ######################################
if [ $if_finalim == 'yes' ]
then


   rm -rf combined.map
   rm -rf combined.beam
   invert "vis=./final_vis/*" options=systemp,double,mosaic \
          map=combined.map beam=combined.beam cell=$alma_cell imsize=$alma_imsize robust=2.0

   rm -rf combined.model
   if [ $imaging_method == 'clean' ]
   then
       mossdi map=combined.map beam=combined.beam out=combined.model gain=0.1 \
              niters=$niters_alma cutoff=$cutoff_alma clip=0.3
   else
       mosmem map=combined.map beam=combined.beam out=combined.model rmsfac=3 # niters=15
   fi

   rm -rf combined.clean
   rm -rf combined.residual
   restor map=combined.map beam=combined.beam model=combined.model \
          mode=clean out=combined.clean
   restor map=combined.map beam=combined.beam model=combined.model \
          mode=residual out=combined.residual

   rm -rf combined.clean.fits
   fits in=combined.clean op=xyout out=combined.clean.fits
   rm -rf combined.dirty.fits
   fits in=combined.map op=xyout out=combined.dirty.fits
   rm -rf combined.model.fits
   fits in=combined.model op=xyout out=combined.model.fits
   rm -rf combined.residual.fits
   fits in=combined.residual op=xyout out=combined.residual.fits

fi
##########################################################



##### Removing meta data #################################
if [ $if_cleanup == 'yes' ]
then
   echo '##### Removing meta data #############'
   rm -rf ./*uvmodel*
   rm -rf ./*regrid*
   rm -rf ./*temp*
   rm -rf ./single_input.miriad
   rm -rf ./single_input*.restor.miriad
   rm -rf ./single_input*.residual.miriad
   rm -rf ./temp.*
   rm -rf ./*.temp
   rm -rf ./uv_random.miriad
   rm -rf ./acatp*
   rm -rf ./intermediate_vis
   rm -rf ./*demos*
   rm -rf ./*deconv*
fi
##########################################################



##### Re-immerge #########################################

if [ $if_reimmerge == 'yes' ]
then


   # Gegrid TP maps
   rm -rf TP_12CO.vel.image.regrid.miriad
   regrid in=TP_12CO.vel.image.miriad tin=combined.clean \
          out=TP_12CO.vel.image.regrid.miriad \
          project=sin

   rm -rf combined.clean.reimmerge
   immerge in=combined.clean,TP_12CO.vel.image.regrid.miriad factor=$acatp_conv_f \
	   out=combined.clean.reimmerge

   rm -rf combined.clean.reimmerge.fits
   fits in=combined.clean.reimmerge op=xyout out=combined.clean.reimmerge.fits

fi

##########################################################
