# SalienceDetector.psc
# Script implemented by Plinio A. Barbosa (pabarbosa.unicampbr@gmail.com),IEL/Unicamp,Brazil,
# based on the integration of the BeatExtractor with the SGDetector scripts, with new insights.
# Please, DO NOT DISTRIBUTE WITHOUT THE README FILE SALIENCEDETECTOR_RDM.TXT
# Copyright (C) 2009  Barbosa, P. A.
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
  word File_(with_extension) AvelReadP1.wav
  choice Speaker_sex 2
    button Male
    button Female
  choice Filter 1
    button Butterworth
    button Hanning
  integer Filter_order 0 (= auto)
  integer Refmean 193
  integer RefSD 47
  real left_Cut_off_frequency_(Hz) 0 (= auto)
  real right_Cut_off_frequency_(Hz) 0 (= auto)
  real Smoothing_cut_freq_(Hz) 0 (= auto)
  choice Technique 2
    button Amplitude
    button Derivative
  positive Threshold1_(0.05..0.50) 0.15
  positive Threshold2_(0.05..0.15) 0.12
endform
##
# mindur is the minimum duration allowed between two consecutive boundaries
# fcut is the cut-off frequency of the low-pass filters used here
# fe/male default are the default cut-off frequencies according to speaker sex
mindur = 0.040
male_default_left = 1000
male_default_right = 2200
female_default_left = 1200
female_default_right = 2700
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
fil$ = file$
Read from file... 'fil$'
filename$ = selected$ ("Sound")
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
select all
nb = numberOfSelected ("LongSound")
if nb <> 0
 select LongSound 'temp$'
 Remove
endif
select Sound 'filename$'
plus Sound 'beatwave$'
filedelete 'filext$'
Combine to stereo
nowarn Write to WAV file... 'filext$'
Open long sound file... 'filext$'
tmp$ = filename$ + "_filt"
select all
Remove
Read from file... 'fileout$'
begin = Get starting time
end = Get finishing time
nselected = Get number of intervals... 1
nselected = nselected - 2
arqout$ = filename$ + "dur" + ".txt"
filedelete 'arqout$'
arqoutstrgrp$ = filename$ + "SG" + ".txt"
filedelete 'arqoutstrgrp$'
fileappend 'arqout$' % Segmentos acusticos, duracao (ms) , z, z suav.,  fronteira 'newline$'
fileappend 'arqoutstrgrp$' % Duração do grupo acentual | Número de sílabas 'newline$'
select TextGrid 'filename$'
initialtime = Get starting point... 1 2
mdur = 0
for i from 1 to nselected
 adv = i + 1
 label$ = "s'i'"
 Set interval text... 1 'adv'  'label$'
 label'i'$ = label$
 itime = Get starting point... 1 'adv' 
 ftime = Get end point... 1 'adv'
 ftime'i' = ftime
 dur = ftime - itime
 dur = round(dur*1000)
 dur'i' = dur
 mdur = mdur + dur
endfor
mdur = mdur/nselected
sddur = 0
for i from 1 to nselected
 sddur = sddur + (dur'i' - mdur)*(dur'i' - mdur)
endfor
Write to text file... 'fileout$'
sddur = sqrt(sddur/(nselected-1))
threshold = mdur + sddur
for i from 1 to nselected
 if (dur'i' < threshold) and (dur'i' > 1.5*mdur)
   ratio = dur'i'/mdur
 else
   ratio = 1
 endif 
   z'i' = (dur'i'/sqrt(ratio) - sqrt(ratio)*refmean)/refSD
endfor
smz1 = (2*z1 + z2)/3
deriv1 = smz1
smz2 = (2*z2 + z1)/3
deriv2 = smz2 - smz1
i = 3
if smz1 < smz2
 minsmz = smz1
 maxsmz = smz2
else
 minsmz = smz2
 maxsmz = smz1
endif
while i <= (nselected-2)
 del1 = i - 1
 del2 = i - 2
 adv1 = i + 1
 adv2 = i + 2
 smz'i' = (5*z'i' + 3*z'del1' + 3*z'adv1' + z'del2' + 1*z'adv2')/13
 deriv'i' = smz'i' - smz'del1'
 if smz'i' < minsmz
  minsmz = smz'i'
 endif
 if smz'i' > maxsmz
  maxsmz = smz'i'
 endif
 i = i + 1
endwhile
tp1 = nselected -1
tp2 = nselected -2
smz'tp1' = (3*z'tp1'+ z'tp2' + z'nselected')/5
deriv'tp1' = smz'tp1' - smz'tp2'
 if smz'tp1' < minsmz
  minsmz = smz'tp1'
 endif
 if smz'tp1' > maxsmz
  maxsmz = smz'tp1'
 endif
smz'nselected' = (2*z'nselected' + z'tp1')/3  
deriv'nselected' = smz'nselected' - smz'tp1'
 if smz'nselected' < minsmz
  minsmz = smz'nselected' 
 endif
 if smz'nselected' > maxsmz
  maxsmz = smz'nselected' 
 endif
tempfile$ = "temp.TableOfReal"
filedelete 'tempfile$'
fileappend 'tempfile$' File type = "ooTextFile short" 'newline$'
fileappend 'tempfile$' "TableOfReal"  'newline$'
fileappend 'tempfile$'  'newline$'
fileappend 'tempfile$' 2 'newline$'
fileappend 'tempfile$' columnLabels []:  'newline$'
fileappend 'tempfile$' "position" "smoothed z" 'newline$'
tpp = nselected + 2
fileappend 'tempfile$' 'tpp' 'newline$'
time = initialtime
fileappend 'tempfile$' row[1]: "0" 0.0 0.0 'newline$'
boundcount = 0
sdur = 0
ssyl = 0
sdurSG = 0
for i from 1 to nselected
 tempsmz = smz'i'
 tplabel$ = label'i'$
 adv1 = i + 1
 btime'i' = 0
 time = time + dur'i'/1000
 fileappend 'tempfile$' row['adv1']: "'tpnome$'" 'time' 'tempsmz' 'newline$'
 if i <> nselected 
  adv1 = i + 1
  if (deriv'i' >= 0) and (deriv'adv1' < 0)
    boundary = 1
    boundcount = boundcount + 1
    btime'i' = time
    bctime'boundcount' = time 
  else
    boundary = 0
  endif
 else
  del1 = i -1 
  if smz'i' > smz'del1'
     boundary = 1
     boundcount = boundcount + 1
     btime'i' = time 
     bctime'boundcount' = time 
  else 
    boundary = 0
  endif
 endif
 tempz = z'i'
 tempdur = dur'i'
 tempftime = ftime'i'
 sdur = sdur + tempdur
 sdurSG = sdurSG + tempdur
 ssyl = ssyl + 1
 fileappend 'arqout$' 'tplabel$' 'tempftime:3' 'tempdur' 'tempz:2' 'tempsmz:2' 'boundary' 'newline$'
 if boundary == 1
  fileappend 'arqoutstrgrp$' 'sdurSG' 'ssyl' 'newline$'
  sdurSG = 0
  ssyl = 0
 endif
endfor
tp = i+1
fileappend 'tempfile$' row['tp']: "X" 'end' 0 'newline$'
select all
Remove
fileout2$ = filename$ + "2.TextGrid"
filedelete 'fileout2$'
fileappend 'fileout2$' File type = "ooTextFile short" 'newline$'
fileappend 'fileout2$' "TextGrid" 'newline$'
fileappend 'fileout2$' 'newline$'
fileappend 'fileout2$' 'begin' 'newline$'
fileappend 'fileout2$' 'end' 'newline$'
fileappend 'fileout2$' <exists> 'newline$'
fileappend 'fileout2$' 1 'newline$'
fileappend 'fileout2$' "IntervalTier" 'newline$'
fileappend 'fileout2$' "StressGroups" 'newline$'
fileappend 'fileout2$' 'begin' 'newline$'
fileappend 'fileout2$' 'end' 'newline$'
tmp = boundcount + 2
fileappend 'fileout2$' 'tmp' 'newline$'
fileappend 'fileout2$' 0.00 'newline$'
fileappend 'fileout2$' 'initialtime' 'newline$'
fileappend 'fileout2$' "" 'newline$'
temp = initialtime
for i from 1 to boundcount
 fileappend 'fileout2$' 'temp' 'newline$'
 temp = bctime'i'
 fileappend 'fileout2$' 'temp' 'newline$'
 fileappend 'fileout2$' "" 'newline$'
endfor
fileappend 'fileout2$' 'temp' 'newline$'
fileappend 'fileout2$' 'end' 'newline$'
fileappend 'fileout2$' "" 'newline$'
##
arqgrid1$ = filename$ + ".TextGrid"
arqgrid2$ = fileout2$
Read from file... 'arqgrid1$'
Read from file... 'arqgrid2$'
select all
Merge
filedelete temp.TableOfReal
Read from file... 'file$'
To Intensity... 100 0.0 yes
Rename... TotalInt
i=2
repeat
 select TextGrid merged
 sp = Get start point... 2 'i'
 ep = Get end point... 2 'i'
 select TextGrid merged
 ep = ep - 0.01
 interval = Get interval at time... 1 'ep'
 spVV = Get start point... 1 'interval'
 epVV = Get end point... 1 'interval'
 select Intensity TotalInt
# Computes the median of the intensity of the  last VV in the stress group, that is, the salient VV
   medlastVVinSG = Get quantile... 'spVV' 'epVV' 0.5
 if sp <> spVV
   select TextGrid merged
   Insert boundary... 2 'spVV'
   i = i+1
   boundcount = boundcount +1
# Computes the median of the intensity for the stress group excluding the rightmost VV (salient VV)
   select Intensity TotalInt
   medSG = Get quantile... 'sp' 'spVV' 0.5
 else
   medSG = medlastVVinSG
 endif
 select TextGrid merged
 if medlastVVinSG - medSG  < -10
   Set interval text... 2 'i' B
 else
   Set interval text... 2 'i' P/B
 endif
i = i+1
until i > boundcount +1