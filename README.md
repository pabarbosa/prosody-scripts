# prosody-scripts

This repository contains six scripts for Praat organized in six folders.
Each script is found at the root of the respective folder. 
Inside each folder there are subfolders entitled **Documents** and **Example**. 
The first contains a Manual or a ReadMe file, whereas the latter contains examples of input and output files
that help understand whats is said in the manual or readme file and how to annotate the audio files, when applicable.

1. *AcousticParametersforVowelsExtractor*
The script generates two files, one containing F1 and F2 in Hertz, and another one with F1 and F2 normalised by the Lobanov method (the other parameters are the same). Additionally, the script computes vowel duration and spectral emphasis. It requires an audio file and a TextGrid whose annotation is explained in the Test.TextGrid example file and hints on annotation are given in the manual.

1. *Beat Extractor*
This scripts generates a TextGrid file containing intervals delimited by vowel onsets. 
It only requires an audio file as input and works for any language.
Change in the inpout parameters is, though, necessary for a better performance.

1. *ForensicVowelTracking*
This script generates a set of data values for vowels for Forensic analysis: F1, F2, F3, Rate of F2 transition, Baseline, F0 median and Espectral Emphasis. 
It requires an audio file and a TextGrid whose annotation is explained in the Test.TextGrid example file.

1. *Prosody Descriptor Extractor*
This script generates a large set of acoustic-prosodic parameters computed from labelled intervals and points in a TextGrid file.
It requires an audio file and a TextGrid whose annotation is explained in the Example.TextGrid file. Only one tier is mandatory, the chunk tier. Additional tiers can be used to a complete set of rhythmic, voice quality and melodic parameters. If only if VV duration normalization is chosen to be computed by the user, a language-specific TableOfReal file will be necessary because duration normalization depends on reference duration mean and standard deviation of the language. This table is given for French, German, Spanish, American English, Brazilian and European Portuguese. Symbols for syllable-size (VV unit) annotation in BP are given in a Table of correspondance with IPA. Symbols allowed for the other languages can be seen opening the TableOfReal file in a text editor.
A version called "Prosody Descriptor ExtractorZscoreF0" was modified from the original by Gustavo Silveira for allowing F0 normalization by the Lobanov method (z-score).

1. *SGDetector*
This script normalizes syllable-size duration using two techiques applied consecutively: z−scores are computed by using the duration mean and standard deviation found in the laanguage-specific TableOfReal file and them smoothed with a 5-point moving average techique. This table is given for French, German, Spanish, British English, Brazilian and European Portuguese. Symbols for syllable-size (VV unit) annotation are given in a Table of correspondance with IPA. The local maxima of smoothed z-scores are chosen as salient VVs, defining the end of corresponding stress groups. The files are generated: a TextGrid file with stress groups' intervals and maximum z-score values at the end of each stress group; a SG.TXT file with strss groups' duration and numver of VV units; a dur.TXT file with 5 columns o fata, according to the scriot readme file.
It only requires a TextGrid file, although the corresponding audiofile is necessary to check the results.

1. *Salience Detector*
This script combines two scripts, BeatExtractor and SGdetector, to detect salient VV intervals in a sound file. 
It only requires an audio file as input and works for any language.
Change in the inpout parameters is, though, necessary for a better performance.


