## Manual of the Praat script
# SGDetector
### by Plinio A. Barbosa
### Versions: May 27th, 2004. New version Jul 2016, jul 2020

**Warning:** It cannot run without the corresponding TableOfReal file for the specific language. TableOfReal files for BP, EP, German (G), French (F), British English (BE) and Spanish (SP) are given

### This Praat script generates as outputs:

1. A TXT file with 5 columns: VV labels, raw duration in ms, duration z-scores, smoothed duration z-scores and boundary identification (0 = no SG boundary and 1  = stress group boundary).
2. A TXT file with 2 columns: duration of stress groups (SG) and number of VV within each SG.
3. A TextGrid file ending in SG.TextGrid with a point tier and and interval tier defining stress group boundaries and the final smoothed z-score of the corresponding stress group. Each stress group ends with a salient VV interval (the last VV within the interval is the detected salient VV).
4. If the option DrawLines is chosen, it also draws the z-scored VV duration contour.

The duration z−scores are computed by using the  as such: z = (VV_dur− Sum_ Refmean)/SQRT(Sum_RefVar) and smoothed z − scores are then obtained by using a 5-point moving average filter. Refmean are the phone duration means and RefVar are the seared values of the phone duration standard deviation, both found in the TableOfReal file.

The local maxima of smoothed z-scores are chosen as salient VVs, defining the end of corresponding stress groups. 
At the input the TextGrid can be segmented in either phones of VV intervals.

