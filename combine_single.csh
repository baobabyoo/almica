#!/bin/csh 

##### Notes #####################################################
#
# When there are repeats of the observations (i.e., on the same
# target source with same setup, I ussually name the files as
# XXX_1.ms, XXX_2.ms, XXX_3.ms and so on to make it easy to process with iterator.
# This procedure assumes you also do that.
#
##### Parameters ################################################

# name of your spectral line. I usually use this as part of my output filename.
# In this case, it is the CO J=2-1 line.
# You can set this to anything you like. It does not matter.
set linename     = "co_2to1"

# The rest frequency of your line. The sets the velocity grid.
set linerestfreq = 230.53800000 # in GHz unit

# The directory where your visibility data are located.
set visdir   = "./fits_vis/"

# The ids (integers) of the data files (see the notes at the beginning).
set fileids  = "1 2 3"

# The primary beam FWHM of the files with id=1, id=2, and id=3, i.e.,
# for the visibility files XXX_1.fits, XXX_2.fits, and XXX_3.fits
set pbfwhm = (27.327382 27.327382 45.54)

# Filename of the ACA visibility
set ACAvis = 'co_2to1_3.uv.miriad'

# Filename of all of the ALMA 12-m visibility
set all12mvis = 'co_2to1_1.uv.miriad,co_2to1_2.uv.miriad'

# Filename of one of the ALMA 12-m visibility. It can be any one of those.
# This is for the script to extract header information.
set Mainvis = 'co_2to1_1.uv.miriad'

# A relative Tsys for adjusting weighting.
set tsys_single = '60'

# parameters for ACA cleaning - - - - - - - - - -

# size of the initial ACA image in units of pixels
set acaimsize = '128,128'

# cell size for the initial ACA image in units of arcsecond.
set acacell   = '0.8'

# number of iterations for the initial ACA imaging (per channel)
set acaniters  =  1500

# cutoff level fo the initial ACA imaging
set acacutoff  =  0.15
      
# options for the initial ACA imaging (in the clean task)
set acaoptions = 'positive' 
      
# The region in the ACA image to clean.
# This is sometimes useful (e.g., when you actually neeed single-dish but doesn't have it)
set acaregion  = 'boxes(45,45,85,85)'


# paramaters for final imaging  - - - - - - - - - -

# Briggs robust parameter for the final imaging.
set robust  = 2.0

# size of the final image in units of pixels
set imsize  = '6000,6000'

# cell size for the final image in units of arcsecond.
set cell    = '0.01'

# number of iterations for the final imaging (per channel)
set niters  = 1000000

# cutoff level fo the final imaging
set cutoff  = 0.005

# The region in the final image to clean.
# This is sometimes useful (e.g., when you actually neeed single-dish but doesn't have it)
set region  = 'boxes(1200,1200,4800,4800)'

# tapering FWHM in units of arcsecond.
# You can comment out the tapering part in the final cleaning command if it is not needed.
set taper   = '0.1,0.1'

#################################################################
# Notes.
# 
# The FWHM of the ALMA primary beam is 21" at 300 GHz for a 12 m 
# antenna and a 35? for a 7 m antenna, and scales linearly with 
# wavelength
#
# ###############################################################




##### Step 0. Converting FITS visibilities to Miriad format #####

importvis:

foreach fileid ($fileids)

   set filename = $linename'_'$fileid'.uv.fits'

   if (-e $linename'_'$fileid'.uv.miriad') then
      rm -rf $linename'_'$fileid'.uv.miriad'
   endif

   fits in=$visdir$filename \
        stokes='ii' \
        op=uvin \
        out=$linename'_'$fileid'.uv.miriad'

end

#################################################################



##### Step 1. Set headers #######################################

setheader:

foreach fileid ($fileids)

   set pb = '"gaus('$pbfwhm[$fileid]')"'
   puthd in=$linename'_'$fileid'.uv.miriad'/telescop \
         value='single' \
         type=a

   puthd in=$linename'_'$fileid'.uv.miriad'/pbtype \
         value=$pb \
         type=a

   puthd in=$linename'_'$fileid'.uv.miriad'/restfreq \
         value=$linerestfreq \
         type=d

end

#################################################################



##### Step 2. Imaging ACA #######################################

acaclean:

if (-e $linename.acamap.temp ) then
   rm -rf $linename.acamap.temp
endif

if (-e $linename.acabeam.temp ) then
   rm -rf $linename.acabeam.temp
endif

if (-e $linename.acamodel.temp ) then
   rm -rf $linename.acamodel.temp
endif

if (-e $linename.acaresidual.temp ) then
   rm -rf $linename.acaresidual.temp
endif

if (-e $linename.acaclean.temp ) then
   rm -rf $linename.acaclean.temp
endif


# produce dirty image (i.e., fourier transform)
invert vis=$ACAvis \
       map=$linename.acamap.temp   \
       beam=$linename.acabeam.temp \
       options=double    \
       imsize=$acaimsize \
       cell=$acacell

# perform cleaning (i.e., produce the clean model image)
clean map=$linename.acamap.temp \
      beam=$linename.acabeam.temp \
      out=$linename.acamodel.temp \
      niters=$acaniters \
      cutoff=$acacutoff \
      region=$acaregion \
      options=$acaoptions

# produce the clean image (for inspection)
restor map=$linename.acamap.temp \
       beam=$linename.acabeam.temp \
       mode=clean \
       model=$linename.acamodel.temp \
       out=$linename.acaclean.temp

# produce the residual image (for insepction)
restor map=$linename.acamap.temp \
       beam=$linename.acabeam.temp \
       mode=residual \
       model=$linename.acamodel.temp \
       out=$linename.acaresidual.temp

#################################################################



##### Step 3. Implment the 12m dish PB to ACA ###################

pbcorr:

if (-e $linename.acamodel.regrid.temp) then
   rm -rf $linename.acamodel.regrid.temp
endif

# regriding the model image to the original imagesize
regrid in=$linename.acamodel.temp \
       tin=$linename.acamap.temp \
       out=$linename.acamodel.regrid.temp

if (-e $linename.acamodel.regrid.pbcor.temp) then
   rm -rf $linename.acamodel.regrid.pbcor.temp
endif

# correct the aca primary beam to the model
linmos in=$linename.acamodel.regrid.temp \
       out=$linename.acamodel.regrid.pbcor.temp

if (-e $linename.acamodel.regrid.pbcor.demos.temp1) then
   rm -rf $linename.acamodel.regrid.pbcor.demos.temp1
endif

# implement (i.e., multiply) the 12m array primary beam
demos map=$linename.acamodel.regrid.pbcor.temp \
      vis=$Mainvis \
      out=$linename.acamodel.regrid.pbcor.demos.temp

if (-e $linename.acamodel.regrid.pbcor.demos.temp) then
   rm -rf $linename.acamodel.regrid.pbcor.demos.temp
endif
mv $linename.acamodel.regrid.pbcor.demos.temp1 $linename.acamodel.regrid.pbcor.demos.temp

#################################################################



##### Step 4. Generate ACA visibility model #####################

uvmodel:

if (-e $ACAvis'.uvmodel') then
   rm -rf $ACAvis'.uvmodel'
endif

# replacing the visibility amplitude and phase based on the input image model
uvmodel vis=$ACAvis \
        model=$linename.acamodel.regrid.pbcor.demos.temp \
        options='replace' \
        out=$ACAvis'.uvmodel'

# change the system temperature of the re-generated, primary beam tapered, ACA visibility.
# this is to adjust the relative weight to the ALMA 12m visibility.
uvputhd vis=$ACAvis'.uvmodel' \
        hdvar=systemp \
        type=r \
        varval=$tsys_single \
        length=1 \
        out=$ACAvis'.uvmodel.temp'

if (-e $ACAvis'.uvmodel') then
   rm -rf $ACAvis'.uvmodel'
endif
mv $ACAvis'.uvmodel.temp' $ACAvis'.uvmodel'

#################################################################



##### Step 5. Jointly image ACA visiiblity model with 12m #######

inverting:

if (-e $linename.map.temp ) then
   rm -rf $linename.map.temp
endif

if (-e $linename.beam.temp ) then
   rm -rf $linename.beam.temp
endif

# produce the dirty image
invert vis=$all12mvis,$ACAvis'.uvmodel'      \
       map=$linename.map.temp                \
       beam=$linename.beam.temp              \
       options='systemp,double'              \
       robust=$robust                        \
#       line=channel,1,90,1,1 \
       imsize=$imsize       \
       fwhm=$taper          \
       cell=$cell



cleaning:


if (-e $linename.model.temp ) then
   rm -rf $linename.model.temp
endif

# produce the clean model
clean map=$linename.map.temp \
      beam=$linename.beam.temp \
      out=$linename.model.temp \
      niters=$niters \
      region=$region \
      cutoff=$cutoff



restoring:

if (-e $linename.clean.temp ) then
   rm -rf $linename.clean.temp
endif

if (-e $linename.residual.temp ) then
   rm -rf $linename.residual.temp
endif

# produce the final clean image
restor map=$linename.map.temp \
       beam=$linename.beam.temp \
       mode=clean \
       model=$linename.model.temp \
       out=$linename.clean.temp

# produce the final residual image
restor map=$linename.map.temp \
       beam=$linename.beam.temp \
       mode=residual \
       model=$linename.model.temp \
       out=$linename.residual.temp



finalpbcor:

if (-e $linename.clean.pbcor.temp ) then
   rm -rf $linename.clean.pbcor.temp
endif

# the Miriad task to perform primary beam correction
linmos in=$linename.clean.temp out=$linename.clean.pbcor.temp

#################################################################



##### Step 6. FITS output #######################################

fits in=$linename.clean.pbcor.temp \
     op=xyout \
     out=$linename.clean.pbcor.fits

fits in=$linename.clean.temp \
     op=xyout \
     out=$linename.clean.fits

fits in=$linename.residual.temp \
     op=xyout \
     out=$linename.residual.fits

fits in=$linename.map.temp \
     op=xyout \
     out=$linename.dirty.fits

fits in=$linename.beam.temp \
     op=xyout \
     out=$linename.beam.fits

if (-e fits_images) then
   mv $linename.clean.pbcor.fits ./fits_images/
   mv $linename.clean.fits ./fits_images/
   mv $linename.residual.fits ./fits_images/
   mv $linename.dirty.fits ./fits_images/
   mv $linename.beam.fits ./fits_images/
else
   mkdir fits_images
   mv $linename.clean.pbcor.fits ./fits_images/
   mv $linename.clean.fits ./fits_images/
   mv $linename.residual.fits ./fits_images/
   mv $linename.dirty.fits ./fits_images/
   mv $linename.beam.fits ./fits_images/
endif

if (-e $linename ) then
   rm -rf $linename
   mkdir $linename
else
   mkdir $linename
endif

mv ./$linename.*.temp ./$linename

#################################################################



##### Cleaning up ###############################################
rm -rf $linename*.uv.miriad*
#################################################################



##### Ending ####################################################

endscript:

#################################################################
