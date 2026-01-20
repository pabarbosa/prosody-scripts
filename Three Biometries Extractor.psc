# Three Biometries Extractor.psc
# Script implemented by Plinio A. Barbosa (IEL/Univ. of Campinas, Brazil) for computing
# prosody descriptors from coupled audio/TG files 
#
# The TextGrid and Reference-statistics (xy.TableOfReal, where xy = BP, EP, F, G, or BE) files need
# to be in the same directory if a VV Tier will be used. 
# Copyright (C) 2019, 2020, 2025  Barbosa, P. A.
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
form File acquisition
 word FileOutPar OutPutProsParameters.txt
 word FileOutSil OutPutSil.txt
 word FileOutPromBound OutPutPromBound.txt
 word AudiofileExtension *.wav
 boolean HasSilTier 1
 boolean InSemitones 0
 integer ChunkTier 1
 integer SilTier 2
 integer PromTier 9
 integer NSyllablesTier 3
 integer MaxJawTier 5
 integer MinJawTier 6
 integer MaxVelJawTier 7
 integer MinVelJawTier 8
 integer AudioChannel 1
 integer JawChannel 2
 integer VelJawChannel 3
 integer left_F0Threshold 75
 integer right_F0Threshold 500
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
# Creates the header of the mandatory output file (includes speech and articulation rate).
 fileappend 'fileOutPar$' subj group cond text sex chunk minjaw ampjaw rminjaw sdjaw cvjaw minvjaw f0med f0sd f0SAQ f0min f0max sdf0peak f0peakwidth f0peak_rate sdtf0peak df0posmean df0negmean df0sdpos df0sdneg emph cvint hnr shimmer jitter nminjaw sr ar nsyl 'newline$'
# Creates the header of the output file with pause-related parameters (duration and Inter Pause Intervals, IPI)
if hasSilTier
filedelete 'fileOutSil$'
fileappend 'fileOutSil$' subj group cond text sex type IPI durSIL 'newline$'
filedelete 'fileOutPromBound$'
fileappend 'fileOutPromBound$' subj group cond text sex type f0max f0min f0amp minjaw maxvjaw rminjaw ampjaw minvjaw 'newline$'
endif
##
## Start of all computations for all pairs of audio/TG files
for ifile from 1 to numberOfFiles
select Strings list
audiofile$ = Get string... ifile
Read from file... 'audiofile$'
# filename$ contains the name of the audio file
filename$ = selected$("Sound")
cond$ = left$(filename$,3)
text$ = left$(filename$,4) 
subj$ = mid$(filename$,6,2) 
sex$ =  mid$(filename$,9,1) 
group$ = mid$(filename$,10,2)
Extract one channel... 'audioChannel'
filenameAudio$ = selected$("Sound")
select Sound 'filename$'
Extract one channel... 'jawChannel'
filenameJaw$ = selected$("Sound")
select Sound 'filename$'
Extract one channel... 'velJawChannel'
filenameVelJaw$ = selected$("Sound")
select Sound 'filenameAudio$'
# F0 trace is computed, for the whole audio file
To Pitch... 0.0 'left_F0Threshold' 'right_F0Threshold'
Smooth... 'smthf0Thr'
### Harmonicity
select Sound 'filenameAudio$'
To Harmonicity (ac)... 0.01 'left_F0Threshold' 0.1 4.5
select Sound 'filenameAudio$'
To Intensity... 'left_F0Threshold' 0.0 yes
# Reads corresponding TextGrid
arq$ = filename$ + ".TextGrid"
Read from file... 'arq$'
begin = Get starting time
end = Get finishing time
intchunks = Get number of intervals... 'chunkTier'
absstart = Get start time of interval... 'chunkTier' 2
absend = Get start time of interval... 'chunkTier' 'intchunks'
jawstart = Get high index from time... 'minJawTier' 'absstart'
jawend = Get low index from time... 'minJawTier' 'absend'
higherminvalue = -3
for jawminind from jawstart to jawend
 timejaw = Get time of point... 'minJawTier' 'jawminind'
 select Sound 'filenameJaw$'
 minvalue = Get value at time... 1 'timejaw' cubic
 if minvalue  > higherminvalue
   higherminvalue = minvalue
 endif
 select TextGrid 'filename$'
endfor
higherminvalue = round('higherminvalue'*1000)
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
   fileappend 'fileOutSil$' 'subj$' 'group$' 'cond$' 'text$' 'sex$' 'type$' 'dIPI:2' 'dursil' 'newline$'
   tiniant = tini
  endif
endfor
endif
## Output for intervals of prominent words and pre-boundary words
ninterprom = Get number of intervals... 'promTier'
### Prominent/Preboundary Words
for i from 2 to ninterprom - 1
  label$ = Get label of interval... 'promTier' 'i'
  if label$ == "" 
   label$ = "NPRO"
  endif
  itime = Get start time of interval... 'promTier' i
  ftime = Get end time of interval... 'promTier' i
  select Sound 'filenameJaw$'
  Extract part... itime ftime rectangular 1.0 yes
  chunkprofilename$ = selected$("Sound")
  minjaw = Get minimum... 0 0 cubic
  minjaw  = round('minjaw'*10000)
  maxjaw = Get maximum... 0 0 cubic
  maxjaw = round('maxjaw'*10000)
  ampjaw = maxjaw - minjaw
  rminjaw = abs(minjaw - higherminvalue) 
  select Sound 'filenameVelJaw$'
  Extract part... itime ftime rectangular 1.0 yes
  minvjaw = Get minimum... 0 0 cubic
  minvjaw = round('minvjaw'*10000)
  maxvjaw = Get maximum... 0 0 cubic
  maxvjaw = round('maxvjaw'*10000)
  select Pitch 'filenameAudio$'
  f0min = Get quantile... 'itime' 'ftime' 0.01 Hertz
  f0max = Get quantile... 'itime' 'ftime' 0.99 Hertz
  f0amp = f0max - f0min
  fileappend 'fileOutPromBound$' 'subj$' 'group$' 'cond$' 'text$' 'sex$' 'label$' 'f0max:0' 'f0min:0' 'f0amp:0' 'minjaw:0' 'maxvjaw:0' 'rminjaw:0' 'ampjaw:0' 'minvjaw:0' 'newline$'
  select TextGrid 'filename$'
endfor
### All prosodic parameters for each labelled interval in Chunk Tier are computed
###
select TextGrid 'filename$'
nchunks = Get number of intervals... 'chunkTier'
for ichunk from 1 to nchunks
 initime = Get start time of interval... 'chunkTier' ichunk
 endtime = Get end time of interval... 'chunkTier' ichunk
 uttlabel$ = Get label of interval... 'chunkTier' ichunk
 if uttlabel$ <> ""
 Extract part... initime endtime no
 nminjaw = Get number of points... 'minVelJawTier'
 select Sound 'filenameJaw$'
 Extract part... initime endtime rectangular 1.0 yes
 minjaw = Get minimum... 0 0 cubic
 minjaw  = round('minjaw'*10000)
 maxjaw = Get maximum... 0 0 cubic
 maxjaw = round('maxjaw'*10000)
 ampjaw = maxjaw - minjaw
 rminjaw = abs(minjaw - higherminvalue)
 sdjaw = Get standard deviation... 1 0 0
 sdjaw = round('sdjaw'*100000)
 cvjaw = sdjaw/rminjaw
 select Sound 'filenameVelJaw$'
 Extract part... initime endtime rectangular 1.0 yes
 minvjaw = Get minimum... 0 0 cubic
 minvjaw = round('minvjaw'*1000)
# CV int computation
 select Intensity 'filenameAudio$'
 mint = Get mean... 0.0 0.0 energy
 sdint = Get standard deviation... 0 0
 cvint = 100*sdint/mint
# Spectral emphasis computation
 select Sound 'filenameAudio$'
 Extract part... initime endtime rectangular 1.0 yes
 To Spectrum... yes
 emphasis = Get band energy difference... 0 'spectralemphasisthreshold' 0 0
# f0 descriptors and f0 rate (tonerate) computation per chunk
 select Sound 'filenameAudio$'
 Extract part... initime endtime rectangular 1.0 yes
 To Pitch... 0.0 'left_F0Threshold' 'right_F0Threshold'
 chunkfilename$ = selected$("Pitch")
 Smooth... 'smthf0Thr'
 if inSemitones
  f0median = Get quantile... 'initime' 'endtime' 0.5 semitones re 1 Hz
  f0sd = Get standard deviation... 'initime' 'endtime' semitones
  f0min = Get quantile... 'initime' 'endtime' 0.01 semitones re 1 Hz
  f0max = Get quantile... 'initime' 'endtime' 0.99 semitones re 1 Hz
  f01Q = Get quantile... 'initime' 'endtime' 0.25 semitones re 1 Hz
  f03Q = Get quantile... 'initime' 'endtime' 0.75 semitones re 1 Hz
  f0SAQ = (f03Q-f01Q)/2
 else
  f0median = Get quantile... 'initime' 'endtime' 0.5 Hertz
  f0sd = Get standard deviation... 'initime' 'endtime' Hertz
  f0min = Get quantile... 'initime' 'endtime' 0.01 Hertz
  f0max = Get quantile... 'initime' 'endtime' 0.99 Hertz
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
 select Sound 'filenameAudio$'
 Extract part... initime endtime rectangular 1.0 yes
 chunkfilenameaudio$ = selected$("Sound")
 To PointProcess (periodic, cc)... 'left_F0Threshold' 'right_F0Threshold'
 jitter = Get jitter (local)... 0.0 0.0 0.0001 0.02 1.3
 jitter = 100*jitter
 plus Sound 'chunkfilenameaudio$'
 shimmer = Get shimmer (local)... 0 0 0.0001 0.02 1.3 1.6
 shimmer = 100*shimmer
 select Harmonicity 'filenameAudio$'
 hnr = Get mean... 'initime' 'endtime'
#######
# Speech rate computation per chunk
 select TextGrid 'filename$'
 medialpoint = (initime+endtime)/2
 intTA = Get interval at time... 'nSyllablesTier' 'medialpoint'
 nVVstring$ = Get label of interval... 'nSyllablesTier' 'intTA'
 nVV = number(nVVstring$)
 srate = nVV/(endtime-initime)
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
 artrate = nVV/(endtime-initime-sdursil)
 if hasSilTier
  fileappend 'fileOutPar$' 'subj$' 'group$' 'cond$' 'text$' 'sex$' 'uttlabel$' 'minjaw:1' 'ampjaw:1' 'rminjaw:1' 'sdjaw:2' 'cvjaw:2' 'minvjaw:2' 'f0median:0' 'f0sd:2' 'f0SAQ:2' 'f0min:0' 'f0max:0' 'sdf0max:1' 'meandrop:1' 'tonerate:2' 'sdpitch:2' 'meandf0pos:2' 'meandf0neg:2' 'sdf0pos:2' 'sdf0neg:2' 'emphasis:1' 'cvint:0' 'hnr:1' 'shimmer:1' 'jitter:1' 'nminjaw' 'srate:1' 'artrate:1' 'nVV' 'newline$'
 else
  fileappend 'fileOutPar$' 'subj$' 'group$' 'cond$' 'text$' 'sex$' 'uttlabel$' 'minjaw:1' 'ampjaw:1' 'rminjaw:1' 'sdjaw:2' 'cvjaw:2' 'minvjaw:2' 'f0median:0' 'f0sd:2' 'f0SAQ:2' 'f0min:0'  'f0max:0' 'sdf0max:1' 'meandrop:1' 'tonerate:2' 'sdpitch:2' 'meandf0pos:2' 'meandf0neg:2' 'sdf0pos:2' 'sdf0neg:2' 'emphasis:1' 'cvint:0' 'hnr:1' 'shimmer:1' 'jitter:1' 'nminjaw' 'srate:1' 'nVV' 'newline$'
 endif
endif
select TextGrid 'filename$'
endfor
select all
minus Strings list
Remove
endfor
