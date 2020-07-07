# SGDetector Script Readme file (this is a guide for the use of the SGDetector script)
# By Plinio A. Barbosa (pabarbosa.unicampbr@gmail.com)
# Versions May 27th, 2004. New version Jul 2016
#
# It cannot run without the corresponding TableOfReal file for the specific language. TableOfReal files for BP,
# EP, German (G), French (F), American English (AmE) and Spanish (SP) are given


This Praat script generates as outputs:

1. A TXT file with 5 columns: VV labels, raw duration in ms, duration z-scores, smoothed duration z-scores and boundary identification (0 = no SG boundary and 1  = stress group boundary).
2. A TXT file with 2 columns: duration of stress groups (SG) and number of VV within each SG.
3. An interval tier defining stress group boundaries from a TextGrid with either phones intervals of VV intervals. Each stress group ends with a salient VV interval (the last VV within the interval is the detected salient VV).
4. If the option DrawLines is chosen, it also draws the z-scored VV duration contour.

The duration z−scores are computed by using the  as such: z = (VV_dur− Sum_ Refmean)/SQRT(Sum_RefVar) and smoothed z − scores are then obtained by using a 5-point moving average filter. Refmean are the phone duration means and RefVar are the seared values of the phone duration standard deviation, both found in the TableOfReal file.

The local maxima of smoothed z-scores are chosen as salient VVs, defining the end of corresponding stress groups. 

