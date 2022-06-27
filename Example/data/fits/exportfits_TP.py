filename = 'TP_12CO'

importfits(
           fitsimage = filename + '.fits',
           imagename = filename + '.image',
           overwrite = True,
          )


imreframe(
          imagename = filename + '.image',
          outframe  = 'lsrk',
          restfreq  = '115271199999.99998Hz'
         )

exportfits(
           imagename = filename + '.image',
           fitsimage = filename + '.vel.fits',
           velocity  = True,
           overwrite = True
          )
