## Manual of the Praat Script
# ForensicDataTracking
### by Plinio A. Barbosa (2013)

The ForensicDataTracking script generates a set of data values for vowels for Forensic analysis:
F1, F2, F3, Rate of F2 transition, Baseline, F0 median and Espectral Emphasis

Input files and parameters:
* An audio file with extension informed
* A TextGrid file (no extension should be given, it assumes it is .TextGrid)
* A chosen-by-the-user output file name for writing down the results
* The Tier number where vowel intervals were segmented
* The thresholds for computing F0 (F0Thresholdleft and F0Thresholdright) 
* The maximum number of formants and maximum frequency for computing the vowel formants
* The step in seconds for computing F1 and F2 rates.
