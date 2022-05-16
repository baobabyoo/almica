# Fast and High Fidelity ALMA+ACA or ALMA+ACA+TP Joint Imaging

## Features

- It runs faster (x10~x100) than CASA `tclean` and does not require masking (i.e., clean-boxing).
- It is slower than CASA `feather` but the fidelity is much better.

Jointly imaging ALMA+ACA (no TP) may be considered the most useful part of this procedure as there are many other procedures for combining TP after we obtain the ALMA+ACA map, for example, the Python based [J-comb code](https://github.com/SihanJiao/J-comb).



## Examples of images created with this procedure

This is the ALMA+ACA+TP mosaic of CO 2-1 observations towards Lupus MM3 (presenting three consecutive velocity channels below).

![Lupus MM3](/figures/channel_Lupusmm3_3.png)
![Lupus MM3](/figures/channel_Lupusmm3_4.png)
![Lupus MM3](/figures/channel_Lupusmm3_5.png)



## Acknowledgement (and History)
This procedure was initally developed for the paper [Liu et al. (2015)](https://ui.adsabs.harvard.edu/abs/2015ApJ...804...37L/abstract). It is not mandatory. But it would be very much appreciated if you would cite this paper when using this procedure.  

It was used in another few subsequent peer-reviewed journal publications including [Min et al. (2016)](https://ui.adsabs.harvard.edu/abs/2016ApJ...824...99M/abstract), [Min et al. (2018)](https://ui.adsabs.harvard.edu/abs/2018ApJ...864..102M/abstract), [Monsch et al. (2018)](https://ui.adsabs.harvard.edu/abs/2018ApJ...861...77M/abstract), [Dong et al. (2022)](https://ui.adsabs.harvard.edu/abs/2022NatAs...6..331D/abstract), and [Lin et al. (2022)](https://ui.adsabs.harvard.edu/abs/2022A%26A...658A.128L/abstract), etc.



## Main problem we tackle

In princple, we can use Mosaic imaging in CASA `tclean` to jointly image the ALMA and ACA data. It correctly takes care of the different primary beams of these two arrays. However, this is a very slow algorithm. When we image a wide-field spectral line mosaic, this approach can be prohibitively slow (or say, there is a lot of CO2 footprint). This may be fine for some of us.  

The more serious issue is that, when the target sources you are imaging have rather spatially extended emission, whichi is almost always the case otherwise you would not consider ACA, the emission covered in between the primary beams of the ALMA (12m) and ACA (7m) dishes can appear in your dirty (i.e., pre-cleaned) images as funky structures with ambiguous flux densities. 



## Our Approach

(working in progress)

In terms of combining single-dish, concept of this procedure is not too different from that of [TP2VIS](https://github.com/tp2vis/distribute) or [SDINT](https://casa.nrao.edu/casadocs/casa-6.1.0/global-task-list/task_sdintimaging/about) although the implementations are somewhat different. The performance of our procedure, if used properly, is not worse than the other two to my understanding.


This procedure implemented the same concept to the joint image of ALMA and ACA visibilities.



## Scripts
You can simply git clone to obtain the scripts to do the joint imaging. The scripts `combine_single.sh` and `combine_mosaic.sh` are the scripts for combining single-pointing (ALMA+ACA) observations and mosaic (ALMA+ACA+TP) observations, respectively.



## Requirement

### Platform
I have been running the procedure documented below on a x86_64 system. I am using Linux. I have tried the following distributions: Redhat7, Redhat8, Ubuntu 14.04, 16.04, 18.04, 20.04, and Cent OS 7, 8. They all work OK. It might work for pre-2019 Mac as long as you can successfully install the Miriad software package (binary release is OK). I have not tried it to later Mac. If it works for your Mac, I would be happy to know.

### Software packages
The implementation of this procedure is presently based on the [MIRIAD software package](https://www.astro.umd.edu/~teuben/miriad/). I am using a binary distribution that is optimized for the [CARMA](https://en.wikipedia.org/wiki/Combined_Array_for_Research_in_Millimeter-wave_Astronomy). 
I am running it with a bash script.  
We do not need other softwares.  
However, installing [ds9](https://sites.google.com/cfa.harvard.edu/saoimageds9), [CASA](https://casa.nrao.edu/), or [CARTA](https://cartavis.org/) may be handy when we need to interactively/iteratively optimize some parameters and inspect the results.

A list of MIRIAD tasks and there documentation can be found in [this link](https://www.atnf.csiro.au/computing/software/miriad/taskindex.html).  

The reason for me to base on MIRIAD is that I am more famiilar with manipulating headers in this environment, and I am lucky to be able get quick responses from the developers of MIRIAD when I need to. When we try to further combine the single-dish observations from other observatories, manipulating headers can be very frustrating unless you have done that multiple times. The second reason is that when I was developing this script, both Python and CASA have been evolving rapidly while MIRIAD has been stablized. The third reason was that CASA `tclean` was implemented with a primary beam mask which I sometimes did not want (when testing some procedures). Other than these, it is possible to build a equivalent procedure based on CASA.



## Contact

These scripts have not experienced many other users. I was using them for my own works, or for those people who would not be too interested in such details (e.g., theoreticians or very senior people). Since nowadays, not many people are using Miriad, I was not motivated to oranize, document, and release this procedure, until I heard many good comments about this script from my colleague, Siyi Feng, when she was combining here ALMA and ACA data. Then I started to think it might be useful to open it to other users.

There could be still some bugs in the script that we did not notice. 
Your comment would be very much appreciated.

You are more than welcome to drop me an E-Mail if encourtering any problems. 
