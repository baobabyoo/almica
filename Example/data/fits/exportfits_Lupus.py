import sys
sys.path.append('./')
# from linebasecasa import *

thesteps = []
step_title = {
              0: 'Collect file names',
              1: 'FITS output',
             }

try:
  print 'List of steps to be executed ...', mysteps
  thesteps = mysteps
except:
  print 'global variable mysteps not set.'
if (thesteps==[]):
  thesteps = range(0,len(step_title))
  print 'Executing all steps: ', thesteps


# Not actually producing images in debug mode -------------------
debug = False
# ---------------------------------------------------------------


# setting up which sources and spectral line to image -----------
fieldtoimage = [
                ''
               ]

linename     = 'nchan10_start0kms'

datapath     = '../ALMA/'
mspath       = datapath

# ----- Notes ---------------------------------------------------
# ACA data: fields 0~8
# 12m data: fields 1~29
fieldsrange_dict = {}
fieldsrange_dict['mst_07_nchan10_start0kms.ms'] = [1, 11]
fieldsrange_dict['mst_12_nchan10_start0kms.ms'] = [1, 29]
# ---------------------------------------------------------------




# collecting visibility filenames
mystep = 0
if(mystep in thesteps):
  casalog.post('Step '+str(mystep)+' '+step_title[mystep],'INFO')
  print 'Step ', mystep, step_title[mystep]

  vis     = os.listdir( mspath )
  visname = os.listdir( mspath )
  print ( "Visibilities to image" )

  for vis_id in range( len(vis) ):
     vis[vis_id] = mspath + vis[vis_id]
     print ( vis[vis_id] )


mystep = 1
if(mystep in thesteps):

  if (debug == False):
      for vis_id in range( len(vis) ):
          print visname[vis_id]

          beg_id = fieldsrange_dict[visname[vis_id]][0]
          end_id = fieldsrange_dict[visname[vis_id]][1] + 1

          for field_id in range(beg_id, end_id):
              
              exportuvfits(
                           vis   = vis[vis_id],
                           field = str(field_id),
                           datacolumn = 'data',
                           fitsfile = visname[vis_id] + '.' + str(field_id) + '.uv.fits',
                           multisource  = False,
                           # writestation = True,
                           overwrite = True,
                           combinespw = False
                          )

