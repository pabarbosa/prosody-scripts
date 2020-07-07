# ForensicDataTracking.psc
# Script implemented by Plinio A. Barbosa (IEL/Univ. of Campinas, Brazil) for computing
# a set of data values for Forensic analysis (F1, F2, F3, Rate of F2 transition, Baseline, medianf0, Espectral Emphasis)
# Copyright (C) Jun, 2013  Barbosa, P. A.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; version 2 of the License.
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
# Date: version 1.1: Jun, 2013.
form File acquisition
 word File_(TextGrid) KM_CELULAR
 word Audiofile KM_CELULAR.wav
 word OutFile KM_CELULAR.txt
 integer VowelTier 2
 integer F0Thresholdleft_(Hz) 75
 integer F0Thresholdright_(Hz) 300
 integer Fmax_(Hz) 5000
 integer MaxFormant 5
 real Step 0.010
endform
#
filedelete 'outFile$'
fileappend 'outFile$' vowel F1(Hz) F2(Hz) F3(Hz) rateF2(Hz/ms) f0Median(Hz) Baseline(Hz) SpectEmph(dB) 'newline$'
# Reads AudioFile
Read from file... 'audiofile$'
audiofilename$ = selected$("Sound")
To Formant (burg)... 0.0 'maxFormant' 'fmax' 0.025 50
select Sound 'audiofilename$'
To Pitch... 0.0 'f0Thresholdleft' 'f0Thresholdright'
Copy... 'audiofilename$'
Smooth... 1.5
Rename... filteredpitch
Interpolate
To Matrix
To Sound (slice)... 1
To PointProcess (extrema)... 1 yes no None
npt = Get number of points
arqout2$ = audiofilename$ + "Out2.txt"
filedelete 'arqout2$'
fileappend 'arqout2$' interf0peakduration_s 'newline$'
t0 = Get time from index... 1
for j from 2 to npt
 t = Get time from index... 'j'
 periodpeak = t-t0
 t0 = t
 k = j-1
 fileappend 'arqout2$' 'periodpeak:3' 'newline$'
endfor
select Pitch 'audiofilename$'
Smooth... 10
# Reads TG File
arq$ = file$ + ".TextGrid"
Read from file... 'arq$'
begin = Get starting time
end = Get finishing time
totaldur = end - begin
nvowels = Get number of intervals... 'vowelTier'
nvow = 0
sdur = 0
for i from 2 to nvowels - 1
 vowel'i'$ = Get label of interval... 'vowelTier' 'i'
 if vowel'i'$  != ""
  nvow = nvow + 1
  itime = Get starting point... 'vowelTier' 'i'
  ftime = Get end point... 'vowelTier' 'i'
  dur = ftime - itime
  dur'nvow' = dur*1000
  sdur = sdur + dur'nvow'
  name'nvow'$ = vowel'i'$
  select Pitch 'audiofilename$'
  f0med'nvow' = Get quantile... 'itime' 'ftime' 0.5 Hertz
  f0SD = Get standard deviation... 'itime' 'ftime' Hertz
  baseline'nvow' =  f0med'nvow' - 1.43*f0SD
  spectralemphasisthreshold = 1.43*f0med'nvow'
  select Sound 'audiofilename$'
  Extract part... 'itime' 'ftime' rectangular 1.0 yes
  To Spectrum... yes
  if spectralemphasisthreshold != undefined
   emphasis'nvow' = Get band energy difference... 0 'spectralemphasisthreshold' 0 0
  else
   emphasis'nvow' = undefined
  endif
# Tracking formant movement rate
  select Formant 'audiofilename$'
  onsetF2 = Get value at time... 2 'itime' Hertz Linear
  timeonsetF2 = itime
  currtime = itime
  prevF2 = onsetF2
  repeat
   currtime = currtime + 'step'
   currF2 = Get value at time... 2 'currtime' Hertz Linear
   deltaF2 = currF2 - prevF2
   prevF2 = currF2
   endloop = 0
   if abs(deltaF2/onsetF2) < 0.05
    endloop = 1
   endif
  until endloop or currtime >= ftime
  if endloop
    rateF2'nvow' = (currF2-onsetF2)/(currtime-timeonsetF2)/1000
  else
    rateF2'nvow' = undefined
  endif
# F2 value
  mtime = (itime+ftime)/2
  select TextGrid 'file$'
  select Formant 'audiofilename$'
  f2'nvow' = Get value at time... 2 'mtime' Hertz Linear
  f1'nvow' = Get value at time... 1 'mtime' Hertz Linear
  f3'nvow' = Get value at time... 3 'mtime' Hertz Linear
 endif
  select TextGrid 'file$'
endfor
for j from 1 to nvow
 name$ = name'j'$
 f1 = f1'j'
 f2 = f2'j'
 f3 = f3'j'
 f0med = f0med'j'
 ratef2 = rateF2'j'
 bsline = baseline'j'
 emp = emphasis'j'
 fileappend 'outFile$' 'name$' 'f1:0' 'f2:0' 'f3:0' 'ratef2:1' 'f0med:0' 'bsline:0' 'emp:1' 'newline$'
endfor
select all
Remove
