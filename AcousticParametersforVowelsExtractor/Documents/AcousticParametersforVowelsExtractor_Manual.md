# Manual of the Praat Script
# AcousticParametersforVowelsExtractor
# by Plinio A. Barbosa (Nov, 2015)
# Version 1.3

This manual gives a general overview of how the AcousticParametersforVowelsExtractor Praat script works. Any questions can be asked directly to this email: pabarbosa.unicampbr@gmail.com.

**PART A – HOW THE SCRIPTS WORKS**

1. The script starts with the input parameters form, the window that is presented after clicking on Run (before that open the script using the command Open Praat script... in the "Praat" Menu). The window is presented with the default values for the input parameters. The script and the paired Audio/TG files should be in the same folder. For each parameter you may keep the value as it is informed (default) or writing another one if you want to modify the current value. They are:

    1. Audio file (AudioFile variable). Inform the audio file with the extension.

    1. TextGrid file. (TGFile variable). Inform the TG file with the TextGrid extension.

    1. OutPut file (OutFile variable). Inform a name of your choice for the output file without any extension. A TXT file will be generated.

    1. Spectral emphasis threshold (SEThresholdvariable). The default value is 400 Hz for the low band for computing spectral emphasis (energy in the whole frequency band minus energy in the low band), a measure of relative intensity.

    1. Tier position (VowelTier variable). Inform the position where the segmentation of the vowels was done.

    1. Number of formants (NFormant variable). Inform the expected number of formants up to the Maximum frequency given below.

    1. Maximum frequency to extract formants (MaxFormant variable). Inform the maximum frequency for extracting the formants. For male speakers the default value is 5000 Hz and for females, 5500 Hz.

1. The script generates two files, one containing F1 and F2 in Hertz, and another one with F1 and F2 normalised by the Lobanov method (the other parameters are the same). The script computes the following parameters for each vowel labelled in the TextGrid. If you do not want to measure a particular value, do not put a label for it.

    1. Duration in milliseconds (Dur in the OutPut file).
    1. F1 in the medial position of the vowel in Hz (F1 in the OutPut file).
    1. F2 in the medial position of the vowel in Hz (F2 in the OutPut file).
    1. Spectral emphasis in dB (SE in the OutPut file),

The OutPut file with "norm" attached to its name contains the same values for duration and Spectral Emphasis, but computed F1 in F2 by the Lobanov (1971) normalisation method.


*NOTE ON LOBANOV NORMALISATION*

The Lobanov normalisation is a z-score procedure, which uses a pair of mean and standard deviation values obtained from all vowels of the subject (these are called the reference values). Here we used the pre-stressed and stressed vowels (monophthongs) of the  subject for this computation.

**VOWEL LABELLING**

Use low cases for pre-stressed and stressed vowel: /i e a o u/ (pre-stressed), /i e eh a oh o u/ (stressed) and capitals for the post-stressed ones: /I E A O U/. Avoid segmenting diphthongs for analysis because the parameters F1 and F2 are computed in the medial point of the vowel interval, which can be closer to the vowel or the glide (if you do the reference values for the normalisation are the ones for the vowel, not the glide).

