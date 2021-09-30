# Prosody Descriptor Extractor.psc
# Script implemented by Plinio A. Barbosa (IEL/Univ. of Campinas, Brazil) for computing
# prosody descriptors from coupled audio/TG files 
#
# The TextGrid and Reference-statistics (xy.TableOfReal, where xy = BP, EP, F, G, or BE) files need
# to be in the same directory if a VV Tier will be used. 
# Copyright (C) 2012, 2014  Barbosa, P. A.
#
# The only obligatory tier is the Chunk Tier.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; version 2 of the License.
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
# 
#  New fonctionalities
#
# Date: 2012, 2015, new version (3.1): Sept 2021.
form File acquisition
 word FileOutPar OutPutProsParameters.txt
 word FileOutSil OutPutSil.txt
 word FileOutEff OutPutEff.txt
 word FileOutTones OutPutTones.txt
 word AudiofileExtension *.wav
 boolean HasTonesTier 1
 boolean HasVVTier 1
 boolean HasVowelTier 1
 boolean HasSilTier 1
 boolean InSemitones 1
 integer TonesTier 1
 integer VVTier 5
 integer VowelTier 3
 integer SilTier 4
 integer ChunkTier 2
 integer left_F0Threshold 75
 integer right_F0Threshold 300
 choice Reference: 1
   button BP
   button EP
   button G
   button F
   button BE
   button SP
endform
smthf0Thr = 5
f0step = 0.05
window = 0.03
spectralemphasisthreshold = 400
# Picks all audio files in the folder where the script is
Create Strings as file list... list 'audiofileExtension$'
numberOfFiles = Get number of strings
if !numberOfFiles
	exit There are no sound files in the folder!
endif
filedelete 'fileOutPar$'
# Creates the header of the mandatory output file (includes speech and articulation rate if there is a VV tier).
if hasVVTier
 if hasSilTier
   fileappend 'fileOutPar$' audiofile chunk f0med f0sd f0SAQ f0min f0max f0base sdf0peak f0peakwidth f0peak_rate sdtf0peak df0posmean df0negmean df0sdpos df0sdneg emph cvint slLTASmed slLTAShigh hnr SPI shimmer jitter sr ar 'newline$'
 else
  fileappend 'fileOutPar$' audiofile chunk f0med f0sd f0SAQ f0min f0max f0base sdf0peak f0peakwidth f0peak_rate sdtf0peak df0posmean df0negmean df0sdpos df0sdneg emph cvint slLTASmed slLTAShigh  hnr SPI shimmer jitter sr 'newline$'
endif
# Reads the reference file with the triplets (segment, mean, standard-deviation) from the 
# reference speaker. The variable nseg contains the total number of segments in the file
 Read from file... 'reference$'.TableOfReal
 nseg = Get number of rows
else
 fileappend 'fileOutPar$' audiofile chunk f0med f0sd f0SAQ f0min f0max f0base sdf0peak f0peakwidth f0peak_rate sdtf0peak df0posmean df0negmean df0sdpos df0sdneg emph cvint slLTASmed slLTAShigh  hnr SPI shimmer jitter 'newline$'
endif
# Creates the header of the output file with VQ parameters for vowels
if hasVowelTier
filedelete 'fileOutEff$'
fileappend 'fileOutEff$' audiofile excerpt vowel H1H2 CPP dur f0med_Hz f0sd_Hz f0base_Hz 'newline$'
endif
# Creates the header of the output file for tones
if hasTonesTier
filedelete 'fileOutTones$'
if hasVVTier
 fileappend 'fileOutTones$' audiofile excerpt tonetype time alignVV meanf0VV 'newline$'
else
 fileappend 'fileOutTones$' audiofile excerpt tonetype time 'newline$'
endif
endif
# Creates the header of the output file with pause-related parameters (duration and Inter Pause Intervals, IPI)
if hasSilTier
filedelete 'fileOutSil$'
fileappend 'fileOutSil$' audiofile type IPI durSIL 'newline$'
endif
##
## Start of all computations for all pairs of audio/TG files
for ifile from 1 to numberOfFiles
select Strings list
audiofile$ = Get string... ifile
Read from file... 'audiofile$'
# filename$ contains the name of the audio file
filename$ = selected$("Sound")
# F0 trace is computed, for the whole audio file
To Pitch... 0.0 'left_F0Threshold' 'right_F0Threshold'
Smooth... 'smthf0Thr'
### Harmonicity
select Sound 'filename$'
To Harmonicity (ac)... 0.01 'left_F0Threshold' 0.1 4.5
# Reads corresponding TextGrid
arq$ = filename$ + ".TextGrid"
Read from file... 'arq$'
begin = Get starting time
end = Get finishing time
###
# Normalized duration computation as in the SG Detector Script (2006)
###
if hasVVTier
# The number of intervals in the VV tier is computed
nselected = Get number of intervals... 'vVTier'
arqout$ = filename$ + "dur" + ".txt"
filedelete 'arqout$'
arqoutstrgrp$ = filename$ + "SG" + ".txt"
filedelete 'arqoutstrgrp$'
fileappend 'arqout$' audiofile chunk segment duration_ms  z filteredz  boundary 'newline$'
fileappend 'arqoutstrgrp$' audiofile stressgroupduration numberVVunits finalzfilt 'newline$'
select TextGrid 'filename$'
initialtime = Get starting point... 'vVTier' 2
# VV duration normalisation
kk = 1
 nselected = nselected - 2
 for i from 1 to nselected
  adv = i + 1
  nome$ = Get label of interval... 'vVTier' 'adv'
 itime = Get starting point... 'vVTier' 'adv'
 ftime = Get end point... 'vVTier' 'adv'
 dur = ftime - itime
 dur = dur*1000
 tint = Get starting point... 'vVTier' 'adv'
 call zscorecomp 'nome$' 'dur' 'tint'
 dur'i' = dur
 z'i' = z
 nome'i'$ = nome$
 select TextGrid 'filename$'
 adv = i + 1
endfor
### for i from 1 to nselected
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
sduruns = 0
ssyl = 0
sdurSG = 0
svar = 0
for i from 1 to nselected
 timeinchunk = Get start time of interval... 'vVTier' 'i'
 intervalchunk = Get interval at time... 'chunkTier' 'timeinchunk'
 chunk$ = Get label of interval... 'chunkTier' 'intervalchunk'
 if chunk$ = ""
  chunk$ = "no_label"
 endif
 tempsmz = smz'i'
 tpnome$ = nome'i'$
 adv1 = i + 1
 btime'i' = 0
 time = time + dur'i'/1000
 time'i' = time
 fileappend 'tempfile$' row['adv1']: "'tpnome$'" 'time' 'tempsmz' 'newline$'
 if i <> nselected 
  adv1 = i + 1
  if (deriv'i' >= 0) and (deriv'adv1' < 0)
    boundary = 1
    boundcount = boundcount + 1
    btime'i' = time
    bctime'boundcount' = time 
    smzbound'boundcount' = smz'i'
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
     smzbound'boundcount' = smz'i'
  else 
    boundary = 0
  endif
 endif
 tempz = z'i'
 tempdur = dur'i'
 sdur = sdur + tempdur
 if boundary == 0 
   sduruns = sduruns  + tempdur
 endif
 sdurSG = sdurSG + tempdur
 ssyl = ssyl + 1
 fileappend 'arqout$' 'filename$' 'chunk$' 'tpnome$' 'tempdur:0' 'tempz:2' 'tempsmz:2' 'boundary' 'newline$'
 if boundary == 1
  fileappend 'arqoutstrgrp$' 'filename$' 'sdurSG:0' 'ssyl' 'tempz:2' 'newline$'
   durSG'kk' = sdurSG
   nunits'kk' = ssyl
   zprom'kk' = tempsmz
   kk = kk+1
   sdurSG = 0
   ssyl = 0
   sdurSG = 0
   ssyl = 0
 endif
endfor
### i from 1 to nselected (VV dur norm. computation)
nprom = kk - 1
prate = nprom*1000/sdur
meandur = sdur/nselected
for i from 1 to nselected
 svar = svar + (dur'i' - meandur)^2
endfor
stddevdur = sqrt(svar/(nselected - 1))
tp = i+1
fileappend 'tempfile$' row['tp']: "X" 'end' 0 'newline$'
filedelete temp.TableOfReal
####
#  Write a TextGrid with the stress group boundaries
fileout$ = filename$ + "SG.TextGrid"
filedelete 'fileout$'
fileappend 'fileout$' File type = "ooTextFile short" 'newline$'
fileappend 'fileout$' "TextGrid" 'newline$'
fileappend 'fileout$' 'newline$'
fileappend 'fileout$' 'begin' 'newline$'
fileappend 'fileout$' 'end' 'newline$'
fileappend 'fileout$' <exists> 'newline$'
fileappend 'fileout$' 2 'newline$'
fileappend 'fileout$' "TextTier" 'newline$'
fileappend 'fileout$' "BoundDegree" 'newline$'
fileappend 'fileout$' 'begin' 'newline$'
fileappend 'fileout$' 'end' 'newline$'
fileappend 'fileout$' 'boundcount' 'newline$'
for i from 1 to boundcount
 temp = bctime'i'
 fileappend 'fileout$' 'temp' 'newline$'
 tmpzb = round(100*smzbound'i')/100
 lab$ = string$(tmpzb)
 fileappend 'fileout$' "'lab$'" 'newline$'
endfor
fileappend 'fileout$' "IntervalTier" 'newline$'
fileappend 'fileout$' "StressGroups" 'newline$'
fileappend 'fileout$' 'begin' 'newline$'
fileappend 'fileout$' 'end' 'newline$'
tmp = boundcount + 2
fileappend 'fileout$' 'tmp' 'newline$'
fileappend 'fileout$' 0.00 'newline$'
fileappend 'fileout$' 'initialtime' 'newline$'
fileappend 'fileout$' "" 'newline$'
temp = initialtime
for i from 1 to boundcount
 fileappend 'fileout$' 'temp' 'newline$'
 temp = bctime'i'
 lab$ = "SG" + string$(i)
 fileappend 'fileout$' 'temp' 'newline$'
 fileappend 'fileout$' "'lab$'" 'newline$'
endfor
fileappend 'fileout$' 'temp' 'newline$'
fileappend 'fileout$' 'end' 'newline$'
fileappend 'fileout$' "" 'newline$'
arqgrid1$ = filename$ + ".TextGrid"
Read from file... 'arqgrid1$'
Read from file... 'fileout$'
plus TextGrid 'filename$'
Merge
Save as text file... 'filename$'Enriched.TextGrid
endif
##
####
if hasSilTier
# Silence sucession descriptors, if the TG has a pause tier (SilTier)
nintersil = Get number of intervals... 'silTier'
tiniant = 0
for i from 2 to nintersil - 1
  label'i'$ = Get label of interval... 'silTier' 'i'
  if label'i'$ <> "" 
   type$ = label'i'$
   tini = Get start point... 'silTier' 'i'
   tfin = Get end point... 'silTier' 'i'
   dursil = round(('tfin'-'tini')*1000)
   if tiniant <> 0
    dIPI = tini - tiniant
   else
    dIPI = undefined
   endif
# dIPI contains the duration between the current pause onset and the previous pause onset, irrespective of pause type
# type if the pause type, marked as a label in the pause tier
# dursil is the duration of the pause
   fileappend 'fileOutSil$' 'filename$' 'type$' 'dIPI:2' 'dursil' 'newline$'
   tiniant = tini
  endif
endfor
endif
### All tones from the Tones Tier is written, together with its time instant
if hasTonesTier
npointstones = Get number of points... 'tonesTier'
for k from 1 to npointstones
 select TextGrid 'filename$'
 label$ = Get label of point... 'tonesTier' k
 time = Get time of point... 'tonesTier' k
 timeinchunk = Get interval at time... 'chunkTier' 'time'
 chunk$ = Get label of interval... 'chunkTier' 'timeinchunk'
 if hasVVTier
  intcurrentVV = Get interval at time... 'vVTier' 'time'
  startinVV = Get start point... 'vVTier' 'intcurrentVV'
  endinVV = Get end point... 'vVTier' 'intcurrentVV'
  alignperc = 100*(time - startinVV)/(endinVV-startinVV)
  select Pitch 'filename$'
  meanf0VV = Get mean... 'startinVV' 'endinVV' Hertz
  fileappend 'fileOutTones$' 'filename$' 'chunk$' 'label$' 'time:3' 'alignperc:0' 'meanf0VV:0' 'newline$'
 else
  fileappend 'fileOutTones$' 'filename$' 'chunk$' 'label$' 'time:3' 'newline$'
 endif
endfor
endif
###
if hasVowelTier
# H1 - H2 and CPP computation for all open vowels whose intervals and labels were assigned in the Vowel Tier
select TextGrid 'filename$'
ndesignatedvowels = Get number of intervals... 'vowelTier'
for i from 2 to ndesignatedvowels - 1
 select TextGrid 'filename$'
  label'i'$ = Get label of interval... 'vowelTier' 'i'
  firstseg$ = mid$(label'i'$,1,1)
  call isvowel 'firstseg$'
  if truevowel or label'i'$ = "V"
   vowel$ = label'i'$
   tini = Get start point... 'vowelTier' 'i'
   tfin = Get end point... 'vowelTier' 'i'
   durV = 1000*(tfin - tini)
   tmean = (tini+tfin)/2
   timeinchunk = Get interval at time... 'chunkTier' 'tmean'
   chunk$ = Get label of interval... 'chunkTier' 'timeinchunk'
   select Pitch 'filename$'
   f0median = Get quantile... 'tini' 'tfin' 0.5 Hertz
   f0sd = Get standard deviation... 'tini' 'tfin' Hertz
   f0base = f0median - 1.43*f0sd
   tleft = tmean - 'window'/2
   tright = tmean + 'window'/2
   select Sound 'filename$'
   Extract part... 'tleft' 'tright' rectangular 1.0 no
   To Spectrum... yes
   spect$ = selected$("Spectrum")
   To PowerCepstrum
   cpp = Get peak prominence... 60 340 Parabolic 0.001 0.0 Straight Robust
   select Spectrum 'spect$'
   To Ltas (1-to-1)
   f0min = 0
   f0max = f0median*1.5
   h1 = Get maximum... 'f0min' 'f0max' None
   f0min = f0max
   f0max = f0median*2.5
   h2 = Get maximum... 'f0min' 'f0max' None
   h1h2 = h1-h2
   fileappend 'fileOutEff$' 'filename$' 'chunk$' 'vowel$' 'h1h2:2' 'cpp:2' 'durV:0' 'f0median:0' 'f0sd:0' 'f0base:0''newline$'
  endif
endfor
endif
###
### All prosodic parameters for each labelled interval in Chunk Tier are computed:
# f0median f0max sdf0max f0min f0sd tonerate sdpitch meandf0pos meandf0neg sdf0pos sdf0neg emphasis
###
select TextGrid 'filename$'
nchunks = Get number of intervals... 'chunkTier'
# Spectral emphasis computation
for ichunk from 1 to nchunks
 initime = Get start time of interval... 'chunkTier' ichunk
 endtime = Get end time of interval... 'chunkTier' ichunk
 uttlabel$ = Get label of interval... 'chunkTier' ichunk
 if uttlabel$ <> ""
 select Sound 'filename$'
 Extract part... initime endtime rectangular 1.0 yes
 chunkfilename$ = selected$("Sound")
# Computes the long term spectrum, and gets its standard deviation
 To Ltas... 100
 sltasmedium = Get slope... 0 1000 1000 4000 energy
 sltashigh = Get slope... 0 1000 4000 8000 energy
 select Sound 'chunkfilename$'
 To Intensity... 'left_F0Threshold' 0.0 yes
 mint = Get mean... 0.0 0.0 energy
 sdint = Get standard deviation... 0 0
 cvint = 100*sdint/mint
 select Sound 'chunkfilename$'
 To Spectrum... yes
 emphasis = Get band energy difference... 0 'spectralemphasisthreshold' 0 0
# f0 descriptors and f0 rate (tonerate) computation per chunk
 select Sound 'chunkfilename$'
 To Pitch... 0.0 'left_F0Threshold' 'right_F0Threshold'
 Smooth... 'smthf0Thr'
 if inSemitones
  f0median = Get quantile... 'initime' 'endtime' 0.5 semitones re 1 Hz
  f0sd = Get standard deviation... 'initime' 'endtime' semitones
  f0min = Get quantile... 'initime' 'endtime' 0.01 semitones re 1 Hz
  f0max = Get quantile... 'initime' 'endtime' 0.99 semitones re 1 Hz
  f0base = f0median - 1.43*f0sd
  f01Q = Get quantile... 'initime' 'endtime' 0.25 semitones re 1 Hz
  f03Q = Get quantile... 'initime' 'endtime' 0.75 semitones re 1 Hz
  f0SAQ = (f03Q-f01Q)/2
 else
  f0median = Get quantile... 'initime' 'endtime' 0.5 Hertz
  f0sd = Get standard deviation... 'initime' 'endtime' Hertz
  f0min = Get quantile... 'initime' 'endtime' 0.01 Hertz
  f0max = Get quantile... 'initime' 'endtime' 0.99 Hertz
  f0base = f0median - 1.43*f0sd
  f01Q = Get quantile... 'initime' 'endtime' 0.25 Hertz
  f03Q = Get quantile... 'initime' 'endtime' 0.75 Hertz
  f0SAQ = (f03Q-f01Q)/2
 endif
 Interpolate
 To Matrix
 To Sound (slice)... 1
 Rename... Temp
 To PointProcess (extrema)... 1 yes no None
 ntones = Get number of points
 if ntones <> 0
  initone = Get time from index... 1
  endtone = Get time from index... ntones
  durtones = endtone - initone
  if durtones <> 0
   tonerate = ntones/durtones
  else
   tonerate = undefined
  endif
 else
   tonerate = undefined
 endif
 sdpitch = Get stdev period... 'initime' 'endtime' 0.04 2 1.7
# F0max descriptors (mean and sd)
 meanf0max = 0
 meandrop = 0
 nundefined = 0
 for if0max from 1 to ntones
  tf0max = Get time from index... 'if0max'
  select Pitch 'chunkfilename$'
  if inSemitones
   f0max'if0max' = Get value at time... 'tf0max' "semitones re 1 Hz" Linear
  else
   f0max'if0max' = Get value at time... 'tf0max' "Hertz" Linear
  endif
  tf0left = tf0max - 0.03
  tf0right = tf0max + 0.03
  if inSemitones
   f0maxleft = Get value at time... 'tf0left' "semitones re 1 Hz" Linear
   f0maxright = Get value at time... 'tf0right' "semitones re 1 Hz" Linear
  else
   f0maxleft = Get value at time... 'tf0left' "Hertz" Linear
   f0maxright = Get value at time... 'tf0right' "Hertz" Linear
  endif
  drop = (f0maxleft + f0maxright)/2 - f0max'if0max'
  if drop != undefined
   meandrop = meandrop + drop
  else
   nundefined = nundefined + 1
  endif
  meanf0max = meanf0max + f0max'if0max'
  select PointProcess Temp
 endfor 
 meanf0max = meanf0max/ntones
 meandrop = -1000*meandrop/((ntones - nundefined)*(f0max-f0min))
 sdf0max = 0
 for max from 1 to ntones
  sdf0max = sdf0max + (f0max'max' - meanf0max)*(f0max'max' - meanf0max)
 endfor
 sdf0max = sqrt(sdf0max/(ntones-1))
 select Pitch 'chunkfilename$'
# df0 computations
 Down to PitchTier
 f0dur = Get total duration
 meandf0pos = 0 
 meandf0neg = 0 
 f0ant = Get value at time... 0
 l = 1
 lneg = 0
 lpos = 0
 timef0 = f0step+'initime'
 while timef0 <= (f0dur + initime)
 f0current = Get value at time... 'timef0'
# Computes f0 discrete derivative, and its cumulative value
  df0'l' = f0current - f0ant
  if df0'l' > 0
   meandf0pos = meandf0pos + df0'l'
   lpos = lpos + 1
   df0pos'lpos' = df0'l'
  else
   meandf0neg = meandf0neg + df0'l'
   lneg = lneg + 1
   df0neg'lneg' = df0'l'
  endif
  f0ant = f0current
  timef0 = timef0 + f0step
  l=l+1
 endwhile
 l = l -1
 meandf0pos = meandf0pos/lpos
 meandf0neg = meandf0neg/lneg
# Computes f0 discrete derivative standard deviation
 sdf0pos = 0
 for j from 1 to lpos
  sdf0pos = sdf0pos + (df0pos'j' - meandf0pos)*(df0pos'j' - meandf0pos)
 endfor
 sdf0pos = sqrt(sdf0pos/(lpos-1))
#
 sdf0neg = 0
 for j from 1 to lneg
  sdf0neg = sdf0neg + (df0neg'j' - meandf0neg)*(df0neg'j' - meandf0neg)
 endfor
 sdf0neg = sqrt(sdf0neg/(lneg-1))
#######
 select Sound 'chunkfilename$'
 To PointProcess (periodic, cc)... 'left_F0Threshold' 'right_F0Threshold'
 plus Sound 'chunkfilename$'
 To Ltas (only harmonics)... 50 0.0001 0.02 1.3
 lowmean = Get mean... 1.4 32 dB
 highmean = Get mean... 32 64.3 dB
 sPI = lowmean - highmean
 select PointProcess 'chunkfilename$'
 jitter = Get jitter (local)... 0.0 0.0 0.0001 0.02 1.3
 jitter = 100*jitter
 plus Sound 'chunkfilename$'
 shimmer = Get shimmer (local)... 0 0 0.0001 0.02 1.3 1.6
 shimmer = 100*shimmer
 select Harmonicity 'filename$'
 hnr = Get mean... 'initime' 'endtime'
#######
# Speech rate computation per chunk
if hasVVTier
 select TextGrid 'filename$'
 startvv = Get high interval at time... 'vVTier' 'initime'
 endvv = Get high interval at time... 'vVTier' 'endtime'
 nVV = endvv - startvv - 1
 srate = nVV/(endtime-initime)
endif
###
# Tracking of pauses for computing articulation rate
if hasSilTier
 select TextGrid 'filename$'
 int = Get high interval at time... 'silTier' 'initime'
 intfinal = Get low interval at time... 'silTier' 'endtime'
 sdursil = 0
while int <= intfinal
pause$ = Get label of interval... 'silTier' 'int'
 if pause$ <> "" 
    tinisil = Get start point... 'silTier' 'int'
    tfinsil = Get end point... 'silTier' 'int'
    sdursil = sdursil + tfinsil-tinisil
 endif
 int = int + 1
endwhile
endif
# Articulation rate computation (requires Pause and VV Tiers)
if hasVVTier & hasSilTier
 artrate = nVV/(endtime-initime-sdursil)
endif
if !hasVVTier
fileappend 'fileOutPar$' 'filename$' 'uttlabel$' 'f0median:0' 'f0sd:2' 'f0SAQ:2' 'f0min:0' 'f0max:0' 'f0base:0' 'sdf0max:1' 'meandrop:1' 'tonerate:2' 'sdpitch:2' 'meandf0pos:2' 'meandf0neg:2' 'sdf0pos:2' 'sdf0neg:2' 'emphasis:1' 'cvint:0' 'sltasmedium:1' 'sltashigh:1' 'hnr:1' 'sPI:1' 'shimmer:1' 'jitter:1' 'newline$'
else
 if hasSilTier
  fileappend 'fileOutPar$' 'filename$' 'uttlabel$' 'f0median:0' 'f0sd:2' 'f0SAQ:2' 'f0min:0' 'f0max:0' 'f0base:0' 'sdf0max:1' 'meandrop:1' 'tonerate:2' 'sdpitch:2' 'meandf0pos:2' 'meandf0neg:2' 'sdf0pos:2' 'sdf0neg:2' 'emphasis:1' 'cvint:0' 'sltasmedium:1' 'sltashigh:1' 'hnr:1' 'sPI:1' 'shimmer:1' 'jitter:1' 'srate:1' 'artrate:1' 'newline$'
 else
  fileappend 'fileOutPar$' 'filename$' 'uttlabel$' 'f0median:0' 'f0sd:2' 'f0SAQ:2' 'f0min:0'  'f0max:0' 'f0base:0' 'sdf0max:1' 'meandrop:1' 'tonerate:2' 'sdpitch:2' 'meandf0pos:2' 'meandf0neg:2' 'sdf0pos:2' 'sdf0neg:2' 'emphasis:1' 'cvint:0' 'sltasmedium:1' 'sltashigh:1' 'hnr:1' 'sPI:1' 'shimmer:1' 'jitter:1' 'srate:1' 'newline$'
 endif
endif
endif
select TextGrid 'filename$'
endfor
endfor
## 
procedure zscorecomp nome$ dur tint
 sizeunit = length (nome$)
 sumofmeans = 0
 sumofvar = 0
 cpt = 1
 while cpt <= sizeunit
  nb = 1
  terminate = 0
  seg$ = mid$(nome$,cpt,1)
  if cpt < sizeunit
#    if phoneticAlphabet$ = "Other"
     if reference$ = "BP" or reference$ = "EP"
      if mid$(nome$,cpt+1,1) == "h"  or mid$(nome$,cpt+1,1) == "N"
         nb = nb + 1
         seg$ = seg$ + mid$(nome$,cpt+1,1)
      endif
      if (cpt+nb <= sizeunit)
       tp$ = mid$(nome$,1,1)
       call isvowel 'tp$'
       if ((mid$(nome$,cpt+nb,1) = "I")  or  (mid$(nome$,cpt+nb,1)  = "U"))  and truevowel
         seg$ = seg$ + mid$(nome$,cpt+nb,1)
         nb= nb+1
       endif
      endif
     endif
     if reference$ = "F"
       if mid$(nome$,cpt+1,1) == "h"  or mid$(nome$,cpt+1,1) == "N"  or mid$(nome$,cpt+1,1) == "x"
         nb = nb + 1
         seg$ = seg$ + mid$(nome$,cpt+1,1)
      endif
     endif
     endif
    else
      if mid$(nome$,cpt+1,1) == "~"
         nb = nb + 1
         seg$ = seg$ + mid$(nome$,cpt+1,1)
      endif
      if (cpt+nb <= sizeunit)
       tp$ = mid$(nome$,cpt,1)
       call isvowel 'tp$'
       if ((mid$(nome$,cpt+nb,1) = "j")  or  (mid$(nome$,cpt+nb,1)  = "w"))  and truevowel
         seg$ = seg$ + mid$(nome$,cpt+nb,1)
         nb= nb+1
       endif
      endif
#    endif
  endif    
  j = 1
  select all
  tableID = selected ("TableOfReal")
  select 'tableID'
  while (j <= nseg) and  not terminate
     label$ =  Get row label... 'j'
     if seg$ = label$
         terminate = 1
         mean = Get value... 'j' 1
         sd      = Get value... 'j' 2
         sumofmeans = mean + sumofmeans
         sumofvar= sd*sd + sumofvar
     endif
     j = j+1
  endwhile
  if not terminate
   exit Didn't find phone 'seg$' at 'tint'. Pls check the file TableOfReal
  endif
  cpt= cpt+nb
 endwhile
z = (dur - sumofmeans)/sqrt(sumofvar)
endproc
procedure isvowel temp$
 truevowel = 0
 if temp$ = "i" or temp$ = "e"  or temp$ = "a"  or temp$ = "o"  or temp$ = "u" or temp$ = "I" or temp$ = "E"
    ...or temp$ = "A"  or temp$ = "y" or temp$ = "O"  or temp$ = "U" or temp$ = "6"  or temp$ = "@"
    ...or temp$ = "2" or temp$ = "9" or temp$ = "Y"
    truevowel = 1
 endif
endproc 
