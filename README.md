# ALMICA: Fast and High Fidelity ALMA+ACA or ALMA+ACA+TP Joint Imaging

The name `ALMICA` is to make it sounds like a fusion of **ALM**A, **I**maging, and A**CA**, which is what this procedure is doing.


## Features

- On laptop, this runs faster (x10~x100) than CASA `tclean` and does not require masking (i.e., clean-boxing).
- It is slower than CASA `feather` but the fidelity is much better.
- This is not intended to be a black box. The steps are transparent.

Jointly imaging ALMA+ACA (no TP) may be considered the most useful part of this procedure as there are many other procedures for combining TP after we obtain the ALMA+ACA map, for example, the Python based [J-comb code](https://github.com/SihanJiao/J-comb).



## Usage

1. Install the [MIRIAD software package](https://www.astro.umd.edu/~teuben/miriad/).
2. Download the BASH (i.e., .sh) scripts released here.
3. Export your ALMA or ACA data to FITS format.
4. Edit the parameters in the `Parameters` section in this script.
5. Run it.

*Before running this script, it is recommended that you rename your FITS visibilities as XXX_1.fits, XXX_2.fits, XXX_3.fits, etc, such that you can use iterators to loop through all files.*

*This procedure does not support multi-processor (since Miriad does not support it). If you only have one spectral line to image, normally running it with a single modern processor would be more than adequate for most of the typical ALMA projects (LPs are different stories).* 

*If you have many spectral lines and many processors, you can split the lines into separated files, replicate the scripts for individual lines, and run them separately. This is what I am always doing. For high-mass star-forming regions, this is in fact not quite avoidable since you may need to try different Briggs Robust parameters, tapering, or uv distance range for different lines. Imaging the whole spw in one go does not always get us the best achievable image quality for all lines. I shared another Python/CASA script that may make it easier for you to split a large number of lines for a large number of ALMA MS files ( [Check this link](https://github.com/baobabyoo/usefulCASAscripts/blob/zcma_2017Nov/linesplit.py), and please use the zcma_2017Nov branch, which was the lastest edit and was used for the publication [Dong et al.  2022](https://ui.adsabs.harvard.edu/abs/2022NatAs...6..331D/abstract)). The syntax of ALMA data might have changed since then. If you encounter any problem or if you have any suggestion, please let me know.* 




## Examples of images created with this procedure

This is the ALMA+ACA+TP mosaic of CO J=2-1 observations towards Lupus MM3 (presenting one velocity channel; the 10 consecutive velocity channels can be found in the /figures folder). The image cube with 10 spectral channels (in the /figure folder) was produced with a laptop purchased in late 2018 (an ASUS model which costed about 1000 USD, with 16 GB RAM and using a single processor). The run-time was about 5 minutes, which is demonstrated to my colleague, Adele Plunkett, in a visit. I let MIRIAD clean automatically without using any box (or say, masks or regions).

![Lupus MM3](/figures/channel_Lupusmm3_3.png)

This procedure was used in another few subsequent peer-reviewed journal publications including 
- [Dong et al. (2022)](https://ui.adsabs.harvard.edu/abs/2022NatAs...6..331D/abstract)
- [Lin et al. (2022)](https://ui.adsabs.harvard.edu/abs/2022A%26A...658A.128L/abstract)
- [Monsch et al. (2018)](https://ui.adsabs.harvard.edu/abs/2018ApJ...861...77M/abstract)
- [Min et al. (2016)](https://ui.adsabs.harvard.edu/abs/2016ApJ...824...99M/abstract) and [Min et al. (2018)](https://ui.adsabs.harvard.edu/abs/2018ApJ...864..102M/abstract)
- [Liu et al. (2013)](https://ui.adsabs.harvard.edu/abs/2013ApJ...770...44L/abstract)

which can also demonstrate the performance.
The last one was perhaps the first mega-mosaic observations (e.g., with 150+ pointings in a night) of the Submillimeter Array, which demonstrated the fisrt interferometric 0.87 mm dust continuum image of the Galactic circumnuclear disk on ~2 pc scales.


## Acknowledgement (and History)
This procedure was initally developed for the paper [Liu et al. (2015)](https://ui.adsabs.harvard.edu/abs/2015ApJ...804...37L/abstract). It is not mandatory, but it would be very much appreciated if you would cite this paper when using this procedure. You are also welcome to include a link to this page in a footnote.



## Main problem tackled

**(Slowliness)** In princple, we can use Mosaic imaging in CASA `tclean` to jointly image the ALMA and ACA data. It correctly takes care of the different primary beams of these two arrays. However, this is a very slow algorithm. When we image a wide-field spectral line mosaic, this approach can be **prohibitively slow** (or say, there is a lot of CO2 footprint). This may not trouble some of us.  

**(Quality and Reproducibility)** What have troubled most of us is that, when the target sources you are imaging have rather spatially extended emission, whichi is almost *always* the case otherwise you would not consider ACA (and/or single-dish), the emission covered in between the primary beams of the ALMA (12m) and ACA (7m) dishes can appear in your dirty (i.e., pre-cleaned) images as funky structures with ambiguous synthesized beam full width at half maximum and intensity (in units of Jy/beam). If these funky structures are not cleaned or not correctly cleaned (this is hard), they will contribute to very **high level of dirty-beam features** within the primary beam of the ALMA 12m dish. Most of the other people (if not all) I know used (quasi-)interactive masking (or clean-boxing) to very carefully clean (or not clean) those funky features, which is (1) **extremely time-consuming and tedious**, (2) **subjective and irreproducible**, and (3) **limited by poor image-fidelity**.



## This Approach

**Jointly Imaging ALMA and ACA**

*The concept is to taper the primary beam of the ACA data before jointly imaging with the ALMA data.* In my implementation based on the [MIRIAD software package](https://www.astro.umd.edu/~teuben/miriad/), I followed a *sound-stupid but it works* procedure (`combine_single.sh`): 

1. **Imaging ACA data alone** to creat the clean model image (e.g., the `.model` images produced by the released .sh scripts). They are the clean components (i.e., can be delta functions to represent the intensity distribution in an approximated way). This step is very fast since ACA data have small filesizes. You do not need to use small pixel sizes in this ACA imaging.
2. **Primary beam (7m dishes) correcting** the `.model` images.
3. **Multiplying the primary beam** of the 12m dishes to the 7m-dish primary-beam corrected `.model` images. The name of the MIRIAD task for doing this is *demos*.
4. **Convert the `.model` image produced in Step 3 to visibility (i.e., Fourier transform it).** The name of the MIRIAD task for doing this is *uvmodel* if you only have one identical pointing for ALMA and ACA. This task replaces the visibility amplitudes and phases based on the input image model (i.e., the `.model` image produced in Step 3). This is what the procedure `combine_single.sh` does. If you are performing mosaic observations in the standard way in ALMA Cycle 0-9, you then need to use the MIRIAD task `uvrandom` to generate visibility samples at each ALMA-12m pointing. In the *uv* domain, the density of the visibility points need to allow slighly over-sample the ACA primary beam *in the uv domain*.
5. **Jointly image the visibility** created in Step 4 with the ALMA (12m dish) visibilities. Note that, with this approach, these visibilities have identical primary beam. You may need to interactively adjust the relative weightings between these visibilities such that the diry beam looks Gaussian. In the MIRIAD implementation, this is to replace the system temperature *tsys* of one of them with faked values. Since the ALMA and ACA observations at a certain frequency band are usually carried out in a very narrow range of weather conditions, and since the performance of the hardwares is quite uniform, my experience is that doing this does not hurt image quality at the level that is more important than thermal noise. Adjust weighting usually does not take to many trial-time. You can create just one spectral channel for this purpose. *(Note that in the case of mosaic, the more visibility points you generated to model ACA image, the high weight will the generated ACA visibility be. Once you increase/decrease the ACA visibility points, the *tsys* needs to be adjust accordingly.)*

Then it is all set.

Mosaic and single-pointing observations are not too different to this procedure. The cases of single-pionting observations and mosaic have different BASH scripts, since MIRIAD have different tasks for the former (`clean`) and later (`mossdi`), and there needs loops to process individual pointings in a mosaic observations. Ideally, the best performance may be achieved if your ACA observations have exactly the same pointing centers as the ALMA observations (i.e., super-sampling in the ACA observations). This is presently not the standard mode for the short-spacing observations. We recommend to do it this way since it does not increase too much of the overhead but will make many things simpler (i.e., we can then avoid using the MIRIAD `uvrandom` task).  

The funky features mentioned before is suppressed in Step 3. I have been beliving that this is the right thing to do, although the present implementation is not necessary the best way of doing it. 

In my experiences, this procedure works for the typical ALMA+ACA applications unless you are pursuing ultra-high dynamic range imaging (e.g., >1e4) which is also limited by other problems (e.g., phase errors, amplitude errors, polarization, etc). You may miss some faint and spatially extended features (e.g., those 1.5-sigma structures in the ACA image which are very difficult to clean). This is not a problem in most of the applications since they will be immersed in thermal noise anyway after you jointly image with the ALMA data.

Some other imperfectness is created when we produce the ACA-alone images and then re-convert the clean model back to visibility. This is especially true when you are performing mosaic observations in the standard ALMA Cycle 0-9 way using the `uvrandom` task. Nevertheless, when there are artifacts in the ACA images, it means that the sky intensity was incompletely sampled. This problem is quite fundamental. Even in the case that we can do tapering in of the ACA primary beam in the visibility, it does not necessarily mean we can produce a joint ALMA+ACA image that is dramatically better than what is produced by our present procedure. 

A more ideal way would be directly tapering the observed ACA visibilty in the uv (Fourier) domain, which requires the imaging routine to support this operation. In addition, this ideal approach is only feasible when your ACA and ALMA observations have exactly the same pointing centers or even using denser ACA samplings (e.g., OTF mosaic). To my knowledge, until 2022, such a ALMA+ACA mosaic strategy has been implemented only in one of my own mosaic observations. Without over sampling ACA mosaic, the primary beam tapered ACA mosaic will not cover the entire mosaic area (i.e., it will be patchy). So for this moment, such a ideal way is only practical for jointly imaging single-pointing ALMA+ACA observations. 

The reason for me to base on MIRIAD is that I am more familiar with manipulating headers in this environment, and I am lucky to be able get quick responses from the developers of MIRIAD when I need to (I have been working with the Submillimetary Array community who use MIRIAD as the standard imaging software package). When we try to further combine the single-dish observations from other observatories, manipulating headers can be very frustrating until you have done that multiple times. The second reason is that when I was developing this script, both Python and CASA have been evolving rapidly while MIRIAD has been stablized. The third reason was that CASA `tclean` was implemented with a primary beam mask which I sometimes did not want (when testing some procedures). If I get a suitable Master's student, I may try to make this procedure fully Pythonic. We are a very small and isolated group in a developing country. In terms of budget scale, this is about 30 to 40k USD/yr for 3 to 4 people (including me) for most of the time (for students' stipend, page charges, hardware purchases, international travel, MIS expenses, etc). *For us to acquire grant to support students and continue with the code development and release, your citation would be very helpful and would be deeply appreciated.*

In terms of combining single-dish, concept of this procedure is not too different from that of [TP2VIS](https://github.com/tp2vis/distribute) or [SDINT](https://casa.nrao.edu/casadocs/casa-6.1.0/global-task-list/task_sdintimaging/about) although the implementations are somewhat different. The performance of our procedure, if used properly, is not worse than the other two to my understanding. In the MIRIAD implementation, I use the `immerge` task to ensure that the overall flux density is conserved (e.g., most of the deconvolution procedures do not conserve flux). In the future Pythonic procedure, we will likely use  [J-comb code](https://github.com/SihanJiao/J-comb) which is more precise.


**Jointly Imaging ALMA, ACA, and TP**

The steps are (`combine_mosaic.sh`):

1. **Deconvolve the TP image (either using clean or MEM)**  
2. **Convert the deconvolved TP image to visibilities (at the pointings of ACA mosaic)**  
3. **Jointly image the ACA data and TP visibility model**  
4. **Convert the ACA+TP clean-model to visibilities (at the pointings of ALMA 12m-dish mosaic)**
5. **Jointly image the ALMA data and the ACA+TP visibility model**
6. **Finally, linearly combine the TP image again with the cleam-image produced in Step 5**

*In this procedure, the funky features are suppressed in the same way as the ALMA+ACA imaging introduced above.* In my experiences, with or without suppressing the funky features before cleaning, makes a dramatic difference.


## Release

This is the first release made on 2022-May-20.

You can simply git clone to obtain the scripts to do the joint imaging. The scripts `combine_single.sh` and `combine_mosaic.sh` are the scripts for combining single-pointing (ALMA+ACA) observations and mosaic (ALMA+ACA+TP) observations, respectively.

I have included an example in the Example folder. Basically that is the data to reproduce the example images shown above, which were used in the image combination workshop [Improving Image Fidelity on Astronomical Data: Radio Interferometer and Single-Dish Data Combination](https://www.alma-allegro.nl/data-combination/). This procedure did not join the profiling since I did not have travel budget.


## Requirement

### Platform
I have been running the procedure documented below on a x86_64 system. I am using Linux. I have tried the following distributions: 

- Redhat7, Redhat8 
- Ubuntu 14.04, 16.04, 18.04, 20.04
- Cent OS 7, 8 

They all work OK. It might work for pre-2019 Mac as long as you can successfully install the Miriad software package (binary release is OK). I have not tried it to later Mac. If it works for your Mac, I would be happy to know.

### Software packages
The implementation of this procedure is presently based on the [MIRIAD software package](https://www.astro.umd.edu/~teuben/miriad/). I am using a binary distribution that is optimized for the [CARMA](https://en.wikipedia.org/wiki/Combined_Array_for_Research_in_Millimeter-wave_Astronomy). A list of MIRIAD tasks and there documentation can be found in [this link](https://www.atnf.csiro.au/computing/software/miriad/taskindex.html). I am running it with a bash script.  
We do not need other softwares.  

Installing [ds9](https://sites.google.com/cfa.harvard.edu/saoimageds9), [CASA](https://casa.nrao.edu/), or [CARTA](https://cartavis.org/) may be handy when we need to interactively/iteratively optimize some parameters and inspect the results.
 



## Contact

These scripts have not experienced many other users. I was using them for my own works, or for those people who would not be too interested in such details (e.g., theoreticians or very senior people). Since nowadays, not many people are using Miriad, I was not motivated to oranize, document, and release this procedure, until I heard many good comments about this script from my colleague, Siyi Feng, when she was combining here ALMA and ACA data. Then I started to think it might be useful to open it to other users.

I appreciate the comments from Yuxin Lin (MPE) and Siyi Feng (XMU).

There could be still some bugs in the script that we did not notice. 
Your comment would be very much appreciated.

You are more than welcome to drop me an E-Mail if encourtering any problems. If you are an observe and if you feel confused about the procedure, we can also schedule a Google Meet con if that helps. If you do not want to get into these mess (e.g., if you are a theoretician for most of the time or you would like your student to focus on other aspects of data analyses), we welcome collaboration.

You are also welcome to let me know if there is anything unclear in this README page. I am happy to take your comment and revise.
