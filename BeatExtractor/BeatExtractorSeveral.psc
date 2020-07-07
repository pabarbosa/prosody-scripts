# BeatExtractor.psc
# Script implemented by Plinio A. Barbosa (plinio@iel.unicamp.br),IEL/Unicamp,Brazil,
# based originally on Fred Cummins' beat extractor with some modifications of the default
# parameters and some additions (an additional filter, and another technique for searching for beats.
# Please, DO NOT DISTRIBUTE WITHOUT THE README FILE BEATEXTRACTOR_RDM.TXT
# Credits:	Fred Cummins, for tips about his own beatextractor, and suggestions
#	Sophie Scott, for support on her p-centre predictor model
#	Paul Boersma, for crucial tips/suggestions on programming in Praat
#	Pablo Arantes, Jussara Vieira, Alexsandro Meireles, and Ana C. Matte, for comments during a debugging phase
# Parameters' input
# Copyright (C) 2003, 2019  Barbosa, P. A.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; version 2 of the License.
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
form Parameters' specification
  word AudioFileExtension *.wav
  choice Speaker_sex 2
    button Male
    button Female
  choice Filter 1
    button Butterworth
    button Hanning
  integer Filter_order 0 (= auto)
  real left_Cut_off_frequency_(Hz) 0 (= auto)
  real right_Cut_off_frequency_(Hz) 0 (= auto)
  real Smoothing_cut_freq_(Hz) 0 (= auto)
  choice Technique 2
    button Amplitude
    button Derivative
  positive Threshold1_(0.05..0.50) 0.15
  positive Threshold2_(0.05..0.15) 0.1
endform
##
# mindur is the minimum duration allowed between two consecutive boundaries
# fcut is the cut-off frequency of the low-pass filters used here
# fe/male default are the default cut-off frequencies according to speaker sex
mindur = 0.040
male_default_left = 1000
male_default_right = 1800
female_default_left = 1150
female_default_right = 2100
if left_Cut_off_frequency = 0  ; automatic
   left_Cut_off_frequency = if speaker_sex$ = "Male" then 'male_default_left' else 'female_default_left' fi
endif
if right_Cut_off_frequency = 0  ; automatic
   right_Cut_off_frequency = if speaker_sex$ = "Male" then 'male_default_right' else 'female_default_right' fi
endif
if filter_order = 0  ; automatic
   filter_order = if filter = 1 then 2 else 0 fi
endif
if smoothing_cut_freq = 0  ; automatic
   smoothing_cut_freq = if technique$ = "Amplitude" then 40 else 20 fi
endif
fcut = smoothing_cut_freq
##
# Read all files in the folder:
Create Strings as file list... list 'audioFileExtension$'
numberOfFiles = Get number of strings
if !numberOfFiles
	exit There are no sound files in the folder!
endif
for ifile from 1 to numberOfFiles
select Strings list
audiofile$ = Get string... ifile
Read from file... 'audiofile$'
filename$ = selected$("Sound")
printline Reading file 'filename$': 'ifile'/'numberOfFiles'
centerf = ('right_Cut_off_frequency'  + 'left_Cut_off_frequency')/2
w = ('right_Cut_off_frequency'  - 'left_Cut_off_frequency')/2
select Sound 'filename$'
# The sound file is filtered according to the preceding choices
if filter = 1
 Filter (formula)... sqrt(1.0/(1.0 + ((x-centerf)/w)^(2*'filter_order')))*self; butterworth filter
elif filter = 2
 Filter (pass Hann band)... 'left_Cut_off_frequency' 'right_Cut_off_frequency' 100
endif
Copy... temp
# Filtered sound file's rectification
Formula... abs(self)
w2 =  'smoothing_cut_freq'/10
# Rectified file is low-pass-band filtered producing the beat wave file
Filter (pass Hann band)... 0 'smoothing_cut_freq' w2
max = Get maximum... 0.0 0.0 None
# Beat wave is normalised
Formula... self/max
beatwave$ = filename$ + "_beatwave"
Rename... 'beatwave$'
select Sound 'beatwave$'
derivbeatwave$ = filename$ + "_drvbeatwave"
Copy... temp3
# The derivative of beat wave file is computed and low-pass filtered
Formula... (self[col+1] - self[col])/dx
Filter (pass Hann band)... 0 fcut fcut/10
Rename... 'derivbeatwave$'
max = Get maximum... 0.0 0.0 None
Formula... self/max
select Sound temp3
Remove
select Sound 'beatwave$'
begin = Get starting time
end = Get finishing time
beginindex = Get index from time... 'begin'
beginindex = round(beginindex)
endindex = Get index from time... 'end'
endindex = round(endindex)
fileout$ = filename$ + ".TextGrid"
# Start writing of the TextGrid file
filedelete 'fileout$'
fileappend 'fileout$' File type = "ooTextFile short" 'newline$'
fileappend 'fileout$' "TextGrid" 'newline$'
fileappend 'fileout$' 'newline$'
fileappend 'fileout$' 'begin' 'newline$'
fileappend 'fileout$' 'end' 'newline$'
fileappend 'fileout$' <exists> 'newline$'
fileappend 'fileout$' 1 'newline$'
fileappend 'fileout$' "IntervalTier" 'newline$'
fileappend 'fileout$' "VowelOnsets" 'newline$'
fileappend 'fileout$' 'begin' 'newline$'
fileappend 'fileout$' 'end' 'newline$'
i = beginindex
t = begin
cpt = 0
# Choice of technique
### Technique = 1
# This technique takes the values of the beatwave around threshold 1, within the rising parts (derivative > 0)
if technique = 1
 epsilon = 'threshold1'/5
 repeat
  select Sound 'beatwave$'
  value = Get value at index... 'i'
  value = round(1000*value)/1000
  select Sound 'derivbeatwave$'
  valuederiv = Get value at index... 'i'
  if (value < ('threshold1' + epsilon) and value > ('threshold1' - epsilon)) and (valuederiv > 0.01)
     time'cpt' = Get time from index... 'i'
     if cpt <> 0 
       delayedcpt = cpt -1
       if (time'cpt' - time'delayedcpt') <= mindur
          cpt = cpt -1
       endif
     endif
     cpt = cpt + 1
 endif
 t = t + 0.001
 i = Get index from time... 't'
 i = round(i)
 until (i >= endindex-1)
###
# Technique = 2
# This technique takes the values of the maxima of the derivative of the beatwave
# greater than threshold 2, where the amplitude of the beatwave is greater than threshold 1
elif technique = 2
 select Sound 'derivbeatwave$'
 drv2beatwave$ = filename$ + "_drv2beatwave"
 Copy... temp2
 Formula... (self[col+1] - self[col])/dx
 Filter (pass Hann band)... 0 fcut fcut/10
 Rename... 'drv2beatwave$'
 max = Get maximum... 0.0 0.0 None
 Formula... self/max
 repeat
  select Sound 'drv2beatwave$'
  drvvalue = Get value at index... 'i'
  drvvalue = round(drvvalue)
  select Sound 'derivbeatwave$'
  value = Get value at index... 'i'
  select Sound 'beatwave$'
  valuebeat = Get value at index... 'i'
  if (drvvalue = 0) and (value > 'threshold2') and (valuebeat > 'threshold1') and (valuebeat < 0.3)
     time'cpt' = Get time from index... 'i'
     if cpt <> 0 
       delayedcpt = cpt -1
       if (time'cpt' - time'delayedcpt') <= mindur
          cpt = cpt -1
       endif
     endif
     cpt = cpt + 1
 endif
 t = t + 0.001
 i = Get index from time... 't'
 i = round(i)
 until (i >= endindex-1)
 select Sound 'drv2beatwave$'
 plus Sound temp2
 Remove
endif 
#####
tmp = cpt+1
fileappend 'fileout$' 'tmp' 'newline$'
temp = 0
for i from 0 to cpt-1
 fileappend 'fileout$' 'temp' 'newline$'
 temp = time'i'
 fileappend 'fileout$' 'temp' 'newline$'
 fileappend 'fileout$' "" 'newline$'
endfor
fileappend 'fileout$' 'temp' 'newline$'
fileappend 'fileout$' 'end' 'newline$'
fileappend 'fileout$' "" 'newline$'
fil$ = filename$ + "integr"
# Creates a long sound file containing the original sound and the beat wave 
# Select the created TextGrid file containing the detected boundaries
filext$ = fil$ + ".wav"
temp$ = filename$ + "integr"
select Sound 'filename$'
plus Sound 'beatwave$'
filedelete 'filext$'
Combine to stereo
nowarn Write to WAV file... 'filext$'
Read from file... 'filext$'
tmp$ = filename$ + "_filt"
Read from file... 'fileout$'
endfor