# BreakPredictor.psc
# Script implemented by Plinio A. Barbosa (IEL/Univ. of Campinas, Brazil) for computing
# prosody descriptors around breaks from coupled audio/TG files for syllable-size in 10-VV half windows 
# The TextGrid, Audio and Reference-statistics (xy.TableOfReal, where xy = BP, EP, F, G, or BE) files need
# to be in the same directory!!! 
# Work in collaboration with Tommaso Raso, Maryualê Mittmann and colleagues
# Copyright (C) 2016, 2018  Barbosa, P. A.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; version 2 of the License.
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
# Acknowledgement: This script was implemented with grants from FAPEMIG and CNPq.
# Date of final version: Jul 2020
form File acquisition
 word ModelParameters ModelParameters.txt
 word FileOut Prbs.txt
 word AudiofileExtension *.wav
 boolean HasVVTier 1
 integer F0Thresholdleft 75
 integer F0Thresholdright 300
 positive Smthf0Thr 5
 positive F0step 0.05
 integer AnalysisWindow 10
 positive Spectralemphasisthreshold 400
 word Reference BP.TableOfReal
endform
Create Strings as file list... list 'audiofileExtension$'
numberOfFiles = Get number of strings
if !numberOfFiles
	exit There are no sound files in the folder!
endif
filedelete 'fileOut$'
fileappend 'fileOut$' prob time 'newline$'
# Reads the reference file with the triplets (segment, mean, standard-deviation) from the 
# reference speaker. The variable nseg contains the total number of segments in the file
if hasVVTier
 Read from file... 'reference$'
 nseg = Get number of rows
 reference$ = selected$("TableOfReal")
endif
# Read the model as a Table
Read Table from whitespace-separated file... 'modelParameters$'
ncoeff = Get number of rows
for j from 1 to ncoeff
  par'j'$ = Get value... 'j' par
  coeff'j' = Get value... 'j' coeff
  mean'j' = Get value... 'j' mean
  sd'j' = Get value... 'j' sd
endfor
##
for ifile from 1 to numberOfFiles
 select Strings list
 audiofile$ = Get string... ifile
 Read from file... 'audiofile$'
 filename$ = selected$("Sound")
 Filter (pass Hann band)... 0 'spectralemphasisthreshold' 100
 filenamefiltered$ = selected$("Sound")
 select Sound 'filename$'
 To Pitch... 0.0 'f0Thresholdleft' 'f0Thresholdright'
 Smooth... 'smthf0Thr'
 Interpolate
 To Matrix
 To Sound (slice)... 1 
 Rename... temp
 To PointProcess (extrema)... 1 yes no None
#
# Silent Pause detection
 select Sound 'filename$'
 To TextGrid (silences)... 100 0 -30 0.2 0.1 "P" 
 Rename... pauses
# Reads TextGrid with a VVTier, if any. Otherwise, 200-ms regular intervals are generated
 if hasVVTier
  arq$ = filename$ + ".TextGrid"
  Read from file... 'arq$'
  select TextGrid pauses
  Copy... pauses
  plus TextGrid 'filename$'
  Merge
  Rename... 'filename$'
  vVTier = 1
  pauseTier = 2
  Insert interval tier... 3 "Boundaries"
  begin = Get starting time
  end = Get finishing time
  totaldur = end - begin
  nselected = Get number of intervals... 'vVTier'
 else
  select TextGrid pauses
  Insert interval tier... 1 "VV"
  vVTier = 1
  pauseTier = 2
  begin = Get starting point... 'pauseTier' 2
  endloop = Get finishing time
  tbound = begin + 0.2
  int = 1
  Insert boundary... 'vVTier' 'begin'
  while tbound < endloop
   Insert boundary... 'vVTier' 'tbound'
   Set interval text... 'vVTier' 'tbound' "int'int'"
   tbound = tbound + 0.2
   int = int + 1
  endwhile
  nselected = Get number of intervals... 'vVTier'
  Rename... 'filename$'
  Insert interval tier... 3 "Boundaries"
 endif
#
############################ df0, for each interval (VV or regular interval)
 select TextGrid 'filename$'
 tl = Get starting point... 'vVTier' 2
 tr = Get end point... 'vVTier' 2
 select Pitch 'filename$'
 k = nselected -1
 df0'k'  =0
 f0ant = Get quantile... 'tl' 'tr' 0.5 semitones re 1 Hz
 f0med1 = f0ant
 df0med1 = 0
 for i from 3 to nselected -1
  select TextGrid 'filename$'
  tl = Get starting point... 'vVTier' 'i'
  tr = Get end point... 'vVTier' 'i'
  select Pitch 'filename$'
  f0current = Get quantile... 'tl' 'tr' 0.5 semitones re 1 Hz
# Computes f0 discrete derivative
  j = i-1
  f0med'j' = f0current
  df0med'j' = f0current - f0ant
  f0ant = f0current
 endfor
###################
# Reading TG and computing normalized duration in smoothed z-scores, if there is an original VVTier
#
if hasVVTier
 select TextGrid 'filename$'
 initialtime = Get starting point... 'vVTier' 2
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
 tpp = nselected + 2
 time = initialtime
 boundcount = 0
# loop for 2
 for i from 1 to nselected
  tempsmz = smz'i'
  tpnome$ = nome'i'$
  adv1 = i + 1
  btime'i' = 0
  time = time + dur'i'/1000
  time'i' = time
  if i <> nselected 
   adv1 = i + 1
   if (deriv'i' >= 0) and (deriv'adv1' < 0)
     boundary'i' = 1
     boundcount = boundcount + 1
     btime'i' = time
     bctime'boundcount' = time 
   else
     boundary'i' = 0
   endif
  else
   del1 = i -1 
   if smz'i' > smz'del1'
      boundary'i' = 1
      boundcount = boundcount + 1
      btime'i' = time 
      bctime'boundcount' = time 
   else 
     boundary'i' = 0
   endif
  endif
endfor
endif # in the case of a VVTier
# end loop for 2
# Computing parameters in the two analysisWindow-VV-long half windows
endVV = nselected- analysisWindow + 1
iniVV = analysisWindow + 2
for x from iniVV to endVV
  select TextGrid 'filename$'
  tVVl = Get start time of interval... 'vVTier' 'x'
  tVVr = Get end time of interval... 'vVTier' 'x'
  tmeanVV = (tVVl+tVVr)/2
  indpause = Get interval at time... 'pauseTier' 'tmeanVV'
  pause$ = Get label of interval... 'pauseTier' 'indpause'
  if pause$ == "p" or pause$ == "P" or pause$ == "p " or pause$ == "P "
     startpause = Get starting point... 'pauseTier' 'indpause'
     durpause = Get end point... 'pauseTier' 'indpause'
     psdur = durpause - startpause
     psp = 1
  else
     psdur = 0
     psp = 0
  endif
# computing SR/AR/mz/f0med in the left half-window
    indleft = x - analysisWindow
    lefttime = Get start time of interval... 'vVTier' 'indleft'
    indright = x
    righttime = Get start time of interval... 'vVTier' 'indright'
    ileftlastwindowunit = x-1
    leftlastwindowunit = Get starting point... 'vVTier' 'ileftlastwindowunit'
    srl = analysisWindow/(righttime - lefttime)
    f0medl = 0
    df0medl = 0
    sdur = 0
    sz = 0
    prl = 0
    nunstr = analysisWindow
    for l from indleft to x-1
       ll = l - indleft + 1
       if vVTier
        if boundary'l' == 0
		sdur = sdur + dur'l'
	 else
		nunstr = nunstr - 1
                prl = prl  + 1
	 endif
        sz = sz + smz'l' 
        zl'll' = smz'l'
      endif
        f0medl = f0medl + f0med'l'
        df0medl = df0medl + df0med'l'
        f0medl'll' = f0med'l'
        df0medl'll' = df0med'l'
    endfor
   if vVTier
    arl = 1000*nunstr/sdur
    mzl = sz/analysisWindow
    zl11=smz'l'
    prl = 1000*prl/sdur
   endif
    f0medl11 = f0med'l'
    df0medl11 =  df0med'l'
    f0medl = f0medl/analysisWindow
    df0medl = df0medl/analysisWindow
# computing left z SD/f0med sD/df0med sD
    sdzl= 0
    sdf0l = 0 
    sddf0l = 0
    for l from indleft to x-1
     if vVTier
	sdzl = sdzl + (smz'l'  - mzl)*(smz'l'  - mzl)
     endif
        sdf0l =  sdf0l + (f0med'l'  - f0medl)*(f0med'l'  - f0medl)
        sddf0l =  sddf0l + (df0med'l'  - df0medl)*(df0med'l'  - df0medl)
    endfor
    if vVTier
     sdzl = sqrt(sdzl/(analysisWindow-1))
    endif
    sdf0l =  sqrt(sdf0l/(analysisWindow-1))
    sddf0l =  sqrt(sddf0l/(analysisWindow-1))
# computing left z skew/f0med skew/df0med skew
   skzl = 0
   skf0l = 0 
   skdf0l = 0
   for l from indleft to x-1
    if vVTier
       skzl = skzl + ((smz'l'  - mzl)/sdzl)^3
    endif
       skf0l = skf0l + ((f0med'l'   - f0medl)/sdf0l)^3
       skdf0l = skdf0l + ((df0med'l'   - df0medl)/sddf0l)^3
   endfor
   if vVTier
    skzl = (analysisWindow/((analysisWindow-1)*(analysisWindow-2)))*skzl
   endif
   skf0l = (analysisWindow/((analysisWindow-1)*(analysisWindow-2)))*skf0l
   skdf0l = (analysisWindow/((analysisWindow-1)*(analysisWindow-2)))*skdf0l
# Computing left f0rate
   select PointProcess temp
   f0rl = Get mean period... 'lefttime' 'righttime' 0.3 3 5
   f0rl = 1/f0rl
# Computing Left Spectral Emphasis
   select Sound 'filename$'
   allenergy = Get energy... 'lefttime' 'righttime'
   allenergylast = Get energy... 'leftlastwindowunit' 'righttime'
   select Sound 'filenamefiltered$'
   filtenergy = Get energy... 'lefttime' 'righttime'
   filtenergylast = Get energy... 'leftlastwindowunit' 'righttime'
   emphl = allenergy - filtenergy
   emphlastl = allenergylast - filtenergylast
# Computing SR/AR/mz in the right half-window
    select TextGrid 'filename$'
    indleft = x
    lefttime = Get end point... 'vVTier' 'indleft'
    indright = x + analysisWindow
    righttime = Get end point... 'vVTier' 'indright'
    irightlastwindowunit = x+1
    rightlastwindowunit = Get end point... 'vVTier' 'irightlastwindowunit'
    if vVTier
     srr = analysisWindow/(righttime - lefttime)
     srd = srr - srl
    endif
    sdur = 0
    sz = 0
    f0medr = 0
    df0medr = 0
    prr = 0
    nunstr = analysisWindow
    if indright < endVV
    for l from x+1 to indright
      ll = l - x
      if vVTier
        if boundary'l' == 0
		    sdur = sdur + dur'l'
	      else
		    nunstr = nunstr - 1
		    prr = prr  + 1
	      endif
        sz = sz + smz'l' 
        zr'll' = smz'l'
      endif
        f0medr = f0medr + f0med'l'
        df0medr = df0medr + df0med'l'
        f0medr'll' = f0med'l'
	df0medr'll' = df0med'l'
    endfor
endif
    if vVTier
     arr = 1000*nunstr/sdur
     mzr = sz/analysisWindow
     prr = 1000*prr/sdur
    endif
    f0medr = f0medr/analysisWindow
    df0medr = df0medr/analysisWindow
#computing right z SD/f0med sD/df0med sD
    sdzr= 0
    sdf0r = 0 
    sddf0r = 0
   if indright < endVV
    for l from x+1 to indright
     if vVTier
	sdzr = sdzr + (smz'l'  - mzr)*(smz'l'  - mzr)
     endif
	sdf0r =  sdf0r + (f0med'l'  - f0medr)*(f0med'l'  - f0medr)
        sddf0r =  sddf0r + (df0med'l'  - df0medr)*(df0med'l'  - df0medr)
    endfor
   endif
    if vVTier
     sdzr = sqrt(sdzr/(analysisWindow-1))
    endif
    sdf0r =  sqrt(sdf0r/(analysisWindow-1))
    sddf0r =  sqrt(sddf0r/(analysisWindow-1))
# computing right z skew/f0med skew/df0med skew
   skzr = 0
   skf0r = 0 
   skdf0r = 0
   if indright < endVV
   for l from  x+1 to indright
     if vVTier
       skzr = skzr + ((smz'l'  - mzr)/sdzr)^3
     endif
       skf0r = skf0r + ((f0med'l'   - f0medr)/sdf0r)^3
       skdf0r = skdf0r + ((df0med'l'   - df0medr)/sddf0r)^3
   endfor
endif
   if vVTier
    skzr = (analysisWindow/((analysisWindow-1)*(analysisWindow-2)))*skzr
   endif
   skf0r = (analysisWindow/((analysisWindow-1)*(analysisWindow-2)))*skf0r
   skdf0r = (analysisWindow/((analysisWindow-1)*(analysisWindow-2)))*skdf0r
  if vVTier 
   ard = arr - arl
   mzd = mzr - mzl
   zdloc = zr1 - zl11
   sdzd = sdzr - sdzl
   skzd = skzr - skzl
   prd = prr - prl
  endif
   f0medd = f0medr - f0medl
   df0medd = df0medr - df0medl
   f0meddloc = f0medr1 - f0medl11
   df0meddloc = df0medr1 - df0medl11
   sdf0d = sdf0r - sdf0l
   sddf0d = sddf0r - sddf0l
   skf0d = skf0r - skf0l
   skdf0d = skf0r - skdf0l
# Computing right f0rate
   select PointProcess temp
   f0rr = Get mean period... 'lefttime' 'righttime' 0.3 3 5
   f0rr = 1/f0rr
   f0rd = f0rr - f0rl
# Computing right Spectral Emphasis
   select Sound 'filename$'
   allenergy = Get energy... 'lefttime' 'righttime'
   allenergyfirst = Get energy... 'lefttime' 'rightlastwindowunit'
   select Sound 'filenamefiltered$'
   filtenergy = Get energy... 'lefttime' 'righttime'
   filtenergyfirst = Get energy... 'lefttime' 'rightlastwindowunit'
   emphr = allenergy - filtenergy
   emphfirstright = allenergyfirst - filtenergyfirst
   emphd = emphr - emphl
   emphdloc = emphfirstright - emphlastl
# Inserting boundaries
  select TextGrid 'filename$'
  probbound = 0
  for j from 1 to ncoeff
   temp$ = par'j'$
   if temp$ == "df0med0"
     temp$ = "df0medl11"
   endif
   if temp$ == "psp"
    temp = psp
   elif temp$ == "psdur"
    temp = psdur
   elif temp$ == "f0meddloc"
    temp = f0meddloc
   elif temp$ == "df0meddloc"
    temp = df0meddloc
   else 
    temp = df0medl11
   endif
   probbound = probbound  + coeff'j'*('temp' - mean'j')/sd'j'
  endfor
  probbound = exp(probbound)/(exp(probbound)+1)
  fileappend 'fileOut$' 'probbound:2' 'lefttime:1' 'psdur' 'newline$'
  if probbound > 0.5
   Insert boundary... 3 'lefttime'
  endif
###
endif
endfor
endfor
# All files
#select all
#Remove
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
     if reference$ = "BP" or reference$ = "EP"
      if mid$(nome$,cpt+1,1) == "h"  or mid$(nome$,cpt+1,1) == "N"
         nb = nb + 1
         seg$ = seg$ + mid$(nome$,cpt+1,1)
      endif
      if (cpt+nb <= sizeunit)
       tp$ = mid$(nome$,cpt,1)
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
