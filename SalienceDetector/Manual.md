## Manual of the Praat script
# Salience Detector
### By Plinio A. Barbosa

This Praat script combines two scripts, BeatExtractor and SGdetector, to detect salient VV intervals in a sound file.

If praatcon is used, the syntax is:

praatcon SalienceDetector.psc Test.wav Female Butterworth 0 193 47 0 0 0 Derivative 0.15 0.08

The present script generates a TextGrid containing two tiers, (a) an interval tier with the estimations of the vowel onsets (note that this is not the same thing as finding
p-centres, which is an unsolved problem), and (b) an interval tier defining stress group boundaries. Each stress group ends with a salient VV interval (the last VV within the interval is the detected salient VV). Default parameters'values were optimised using Brazilian Portuguese utterances. In the
following a brief overview of what the script does is
presented. This may help in modifying the parameters for other
languages or datasets (I also give Cummins and Port, 1998's default values, which were
used with Irish English).

When running the script, three buttons allow: (1) to choose between a male and a female speaker
(this option automatically chooses appropriate cut-off frequencies for the filter in step 1 below), (2) to choose between a Butterworth or a Hanning filter (step 1), and (3) to choose a technique for detecting boundaries, as explained in steps 4a and 4b below.

The reference values RefMean and RefSD in the script form were those of a canonical VV of the BP reference
subject (Barbosa, 2006, p. 489). This unit was defined to be the sequence of the
most frequent vowel in BP and a plosive (/a.P/). The value of Refmean is the sum of the /a/ mean duration, and the estimation
of the duration for the voiceless plosives (the mean of the three BP voiceless plosives average durations for the reference
subject). The value of RefSD is the square root of the sum of the variances of the duration for the same segments. To
correct the mean value for the cases where there is more than one VV unit inside the automatically defined interval, an estimation of the number of VV units is given by pratio, where
ratio is dur meandur if threshold1 < dur < threshold2, and 1
otherwise. The thresholds, set to threshold1 = meandur + SDdur, and threshold2 = 1.5 × meandur, were defined in
such a way as to capture the region of the distribution that probably contains more than one VV unit but does not contain a silent pause. The values meandur,SDdur are the mean and standard-deviation of the
VV duration distribution in the analysed sound file.


Steps:

1. The speech signal is filtered with either a by-default second-order Butterworth
  filter, or a Hanning filter. This order of the first
  filter can be varied, but a filter with sharp skirts is not
  recommended.  The default order is 2 provided the value
  for the variable filter order 0 (= auto) is not modified. The default cut-off
  frequencies for the Butterworth filter are 1000 Hz and 2200 Hz (the
  latter allows the detection of front vowels) for male speakers, and 1200 Hz and 2700 Hz for
  female speakers, assigned automatically, provided the values 0 (= auto) are not modified.
  This frequency band preserves F1 for low vowels and F2 for the others (since the filter
  skirts are relatively shallow, high front vowels are included).
  Scott used a Gammtone filter with a center frequency of 597 Hz, and a band from 288 Hz to
  909 Hz, approximatively (but her interest was finding p-centres).

2. The filtered signal is rectified.

3. The rectified signal is low-pass filtered (variable Smoothing_cut_freq in the Praat form).
    I use 20 Hz as the cut-off frequency(for technique 4a. 40 Hz is chosen
    instead, automatically, in technique 4b) , since in Brazilian Portuguese, fast intensity
    changes are produced with tap in intervocalic position, when
    both vowels are reduced (e.g., "xícara", cup). (Cummins used 10 Hz, instead. Scott used
    25 Hz).

This Praat script introduces another possible technique (compared to Cummins's) for
identifying specific points associated with local rises in amplitude,
by first identifying those points where the rate of increase of the
amplitude envelope is maximal:

4 (a). A beat is associated with a local maximum of the first
derivative of the amplitude envelope (obtained after step 3),
provided
this maximum is higher than threshold 2 (expressed as a proportion of
the maximum signal derivative amplitude. Default = 0.12) and the absolute value of the amplitude
peak is higher than threshold 1 (default = 0.15) of the maximum signal amplitude (this
constraint allows the algorithm to ignore steep onsets associated
with very small rises in amplitude).

Fred's original technique is algo available with the following technique:

4 (b). A beat is associated with a local rise in the amplitude
envelope of the signal obtained after step 3. I suggest using the
point at which threshold 1 (default = 0.15) of the rise is complete.  Fred used
the 0.5 point.

5. A TextGrid containing VV intervals is generated with the above boundaries.

6. z−scores are computed by using the values of Refmean and RefSD as such: z = (VV dur−
square root (ratio).Refmean)/RefSD. Smoothed z − scores are then obtained by using
a 5-point moving average filter.

7. The local maxima of smoothed z-scores are chosen as salient VVs, defining the end of corresponding stress groups 
as a second tier of the TextGrid. The rightmost VV in this group is marked by P/B for salience, or with only B, if it matches an intensity criterion: the median of the intensity in this salient VV is 10 dB lesser than the median in the non-terminal extension of the corresponding stress group.


Use freely !!!
