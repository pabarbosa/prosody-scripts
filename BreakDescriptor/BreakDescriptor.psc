# BreakDescriptor-2.psc
# Script implemented by Plinio A. Barbosa (IEL/Univ. of Campinas, Brazil) for computing
# prosody descriptors around breaks from coupled audio/TG files for syllable-size in 10-VV half windows 
# The TextGrid, Audio and Reference-statistics (xy.TableOfReal, where xy = BP, EP, F, G, or BE) files need
# to be in the same directory!!! 
# Work in collaboration with Tommaso Raso, Maryualê Mittmann and colleagues
# Copyright (C) 2016  Barbosa, P. A.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; version 2 of the License.
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
# Date: Jul 2016, Jan 2019: 
form File acquisition
 word FileOut OutPutParameters.txt
 word AudiofileExtension *.wav
 integer VVTier 1
 integer NTBTier 2
 integer TBTier 3
 integer RetrctTier 4
 integer IntrupTier 5
 integer PauseTier 6
 integer F0Thresholdleft 75
 integer F0Thresholdright 300
 positive Smthf0Thr 5
 positive F0step 0.05
 positive Njudges 19
 positive Criterion 0.7
 integer AnalysisWindow 10
 positive Spectralemphasisthreshold 400
 choice Reference: 1
   button BP
   button EP
   button G
   button F
   button BE
   button S
endform
# Reads the reference file with the triplets (segment, mean, standard-deviation) from the 
# reference speaker. The variable nseg contains the total number of segments in the file
Create Strings as file list... list 'audiofileExtension$'
numberOfFiles = Get number of strings
if !numberOfFiles
	exit There are no sound files in the folder!
endif
Read from file... 'reference$'.TableOfReal
nseg = Get number of rows
filedelete 'fileOut$'
fileappend 'fileOut$' audiofile boundtime intnb tb ntb tbN ntbN rtN intN bound type psp psdur srl srr srd arl arr ard mzl mzr mzd zdloc SDzl SDzr SDzd skzl skzr skzd prl prr prd f0medl f0medr f0medd f0meddloc sdf0l sdf0r sdf0d skf0l skf0r skf0d df0medl df0medr df0medd df0meddloc sddf0l sddf0r sddf0d skdf0l skdf0r skdf0d f0rl f0rr f0rd emphl emphr emphd emphdloc zl1 zr1 f0medl1 f0medr1 df0medl1 df0medr1 zl0 f0med0 df0med0 
if analysisWindow == 1
 fileappend 'fileOut$' 'newline$'
else
for t from 2 to analysisWindow
 fileappend 'fileOut$' zl't' zr't' f0medl't' f0medr't' df0medl't' df0medr't' 
endfor
fileappend 'fileOut$' 'newline$'
endif
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
# Reads TextGrid
 arq$ = filename$ + ".TextGrid"
 Read from file... 'arq$'
 ntiers = Get number of tiers
 if ntiers < 6
 	pauseTier = 4
 endif
 begin = Get starting time
 end = Get finishing time
 totaldur = end - begin
 nselected = Get number of intervals... 'vVTier'
 npotbreaks = Get number of points... 'tBTier'
#
############################ df0, VVwise
 tl = Get starting point... 'vVTier' 2
 tr = Get end point... 'vVTier' 2
 select Pitch 'filename$'
 #Down to PitchTier
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
# Reading TG and computing normalized duration in smoothed z-scores
#
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
# for i from 1 to nselected
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
# end loop for 2
# Computing parameters in the two analysisWindow-VV-long half windows
endVV = nselected- analysisWindow + 1
for x from 1 to npotbreaks
  select TextGrid 'filename$'
  timeVV = Get time of point... 'tBTier' 'x'
  indexVV = Get interval at time... 'VVTier' 'timeVV'
  iVV = indexVV - 1
  if iVV > analysisWindow and iVV < endVV
# Agreement judges
    tbtime = Get time of point... 'tBTier' 'x'
    tb20 = tbtime + 0.02
    tb$ = Get label of point... 'tBTier' 'x'
    tb = number(tb$)
    ntb$ = Get label of point... 'nTBTier' 'x'
    ntb = number(ntb$)
if ntiers > 5
    rt$ = Get label of point... 'retrctTier' 'x'
    rt = number(rt$)
    int$ = Get label of point... 'intrupTier' 'x'
    int = number(int$)
endif
    indpause = Get interval at time... 'pauseTier' 'tb20'
    pause$ = Get label of interval... 'pauseTier' 'indpause'
    if pause$ == "p" or pause$ == "P" or pause$ == "p " or pause$ == "P "
		prespause = 1
        durpause = Get end point... 'pauseTier' 'indpause'
		startpause = Get starting point... 'pauseTier' 'indpause'
		durpause = durpause - startpause
    else
		prespause = 0
        durpause = 0
    endif
# computing SR/AR/mz/f0med in the left half-window
    indleft = iVV - analysisWindow
    lefttime = Get starting point... 'VVTier' 'indleft'
    indright = iVV
    righttime = Get starting point... 'VVTier' 'indright'
    ileftlastwindowunit = iVV-1
    leftlastwindowunit = Get starting point... 'VVTier' 'ileftlastwindowunit'
    srl = analysisWindow/(righttime - lefttime)
    sdur = 0
    sz = 0
    prl = 0
    f0medl = 0
    df0medl = 0
    nunstr = 10
    for l from indleft to iVV-1
        if boundary'l' == 0
		sdur = sdur + dur'l'
	else
		nunstr = nunstr - 1
                prl = prl  + 1
	endif
        sz = sz + smz'l' 
        f0medl = f0medl + f0med'l'
        df0medl = df0medl + df0med'l'
        ll = l - indleft + 1
        zl'll' = smz'l'
        f0medl'll' = f0med'l'
        df0medl'll' = df0med'l'
    endfor
    zl11=smz'l'
    f0medl11 = f0med'l'
    df0medl11 =  df0med'l'
    arl = 1000*nunstr/sdur
    mzl = sz/analysisWindow
    f0medl = f0medl/analysisWindow
    df0medl = df0medl/analysisWindow
    prl = 1000*prl/sdur
# computing left z SD/f0med sD/df0med sD
    sdzl= 0
    sdf0l = 0 
    sddf0l = 0
    for l from indleft to iVV-1
	sdzl = sdzl + (smz'l'  - mzl)*(smz'l'  - mzl)
        sdf0l =  sdf0l + (f0med'l'  - f0medl)*(f0med'l'  - f0medl)
        sddf0l =  sddf0l + (df0med'l'  - df0medl)*(df0med'l'  - df0medl)
    endfor
    sdzl = sqrt(sdzl/(analysisWindow-1))
    sdf0l =  sqrt(sdf0l/(analysisWindow-1))
    sddf0l =  sqrt(sddf0l/(analysisWindow-1))
# computing left z skew/f0med skew/df0med skew
   skzl = 0
   skf0l = 0 
   skdf0l = 0
   for l from indleft to iVV-1
       skzl = skzl + ((smz'l'  - mzl)/sdzl)^3
       skf0l = skf0l + ((f0med'l'   - f0medl)/sdf0l)^3
       skdf0l = skdf0l + ((df0med'l'   - df0medl)/sddf0l)^3
   endfor
   skzl = (analysisWindow/((analysisWindow-1)*(analysisWindow-2)))*skzl
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
    indleft = iVV
    lefttime = Get end point... 'VVTier' 'indleft'
    indright = iVV + analysisWindow
    righttime = Get end point... 'VVTier' 'indright'
    irightlastwindowunit = iVV+1
    rightlastwindowunit = Get end point... 'VVTier' 'irightlastwindowunit'
    srr = analysisWindow/(righttime - lefttime)
    srd = srr - srl
    sdur = 0
    sz = 0
    f0medr = 0
    df0medr = 0
    prr = 0
    nunstr = analysisWindow
    for l from iVV+1 to indright
        if boundary'l' == 0
		sdur = sdur + dur'l'
	else
		nunstr = nunstr - 1
		prr = prr  + 1
	endif
        sz = sz + smz'l' 
        f0medr = f0medr + f0med'l'
        df0medr = df0medr + df0med'l'
        ll = l - iVV
        zr'll' = smz'l'
        f0medr'll' = f0med'l'
	df0medr'll' = df0med'l'
    endfor
    arr = 1000*nunstr/sdur
    mzr = sz/analysisWindow
    f0medr = f0medr/analysisWindow
    df0medr = df0medr/analysisWindow
    prr = 1000*prr/sdur
#computing right z SD/f0med sD/df0med sD
    sdzr= 0
    sdf0r = 0 
    sddf0r = 0
    for l from iVV+1 to indright
	sdzr = sdzr + (smz'l'  - mzr)*(smz'l'  - mzr)
	sdf0r =  sdf0r + (f0med'l'  - f0medr)*(f0med'l'  - f0medr)
        sddf0r =  sddf0r + (df0med'l'  - df0medr)*(df0med'l'  - df0medr)
    endfor
    sdzr = sqrt(sdzr/(analysisWindow-1))
    sdf0r =  sqrt(sdf0r/(analysisWindow-1))
    sddf0r =  sqrt(sddf0r/(analysisWindow-1))
# computing right z skew/f0med skew/df0med skew
   skzr = 0
   skf0r = 0 
   skdf0r = 0
   for l from  iVV+1 to indright
       skzr = skzr + ((smz'l'  - mzr)/sdzr)^3
       skf0r = skf0r + ((f0med'l'   - f0medr)/sdf0r)^3
       skdf0r = skdf0r + ((df0med'l'   - df0medr)/sddf0r)^3
   endfor
   skzr = (analysisWindow/((analysisWindow-1)*(analysisWindow-2)))*skzr
   skf0r = (analysisWindow/((analysisWindow-1)*(analysisWindow-2)))*skf0r
   skdf0r = (analysisWindow/((analysisWindow-1)*(analysisWindow-2)))*skdf0r
   ard = arr - arl
   mzd = mzr - mzl
   zdloc = zr1 - zl11
   sdzd = sdzr - sdzl
   skzd = skzr - skzl
   prd = prr - prl
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
       type$ = "NA"
       if tb >= njudges*criterion
	      tb$ = "YES"
          type$ = "TB"
       else
          tb$ = "NO"
       endif
       if ntb >= njudges*criterion
	   	   ntb$ = "YES"
           type$ = "NTB"
       else
           ntb$ = "NO"
       endif
if ntiers > 5
	   if rt >= njudges*criterion
	   	   rt$ = "YES"
           type$ = "RET"
       else
           rt$ = "NO"
       endif
       if int >= njudges*criterion
	   	   int$ = "YES"
           type$ = "INT"
       else
           int$ = "NO"
       endif
else
    rt$ = "NO"
	int$ = "NO"
endif
   if ntb$ = "NO" and tb$ = "NO" and rt$ = "NO" and int$ = "NO"
       bound$ = "NO"
   else
       bound$ = "YES"
   endif
   fileappend 'fileOut$' 'filename$' 'tbtime:3' 'x' 'tb$' 'ntb$'  'tb' 'ntb' 'rt' 'int' 'bound$' 'type$' 'prespause' 'durpause:3' 'srl:2' 'srr:2' 'srd:2' 'arl:2' 'arr:2' 'ard:2' 'mzl:2' 'mzr:2' 'mzd:2' 'zdloc:2' 'sdzl:2' 'sdzr:2' 'sdzd:2' 'skzl:2' 'skzr:2' 'skzd:2' 'prl:2' 'prr:2' 'prd:2' 'f0medl:0' 'f0medr:0' 'f0medd:0' 'f0meddloc:0' 'sdf0l:2' 'sdf0r:2' 'sdf0d:2' 'skf0l:2' 'skf0r:2' 'skf0d:2' 'df0medl:2' 'df0medr:2' 'df0medd:2' 'df0meddloc:2' 'sddf0l:2' 'sddf0r:2' 'sddf0d:2' 'skdf0l:2' 'skdf0r:2' 'skdf0d:2' 'f0rl:2' 'f0rr:2' 'f0rd:2' 'emphl:5' 'emphr:5' 'emphd:5' 'emphdloc:5' 'zl1:2' 'zr1:2' 'f0medl1:0' 'f0medr1:0' 'df0medl1:2' 'df0medr1:2' 'zl11:2' 'f0medl11:0' 'df0medl11:0' 
   if analysisWindow == 1
          fileappend 'fileOut$' 'newline$'
   else
          for t from 2 to analysisWindow
			 zl = zl't'
			 zr = zr't'
			 f0medl = f0medl't'
			 f0medr = f0medr't'
			 df0medl = df0medl't'
			 df0medr = df0medr't'
             fileappend 'fileOut$' 'zl:2' 'zr:2' 'f0medl:0' 'f0medr:0' 'df0medl:2' 'df0medr:2' 
          endfor
          fileappend 'fileOut$' 'newline$'
   endif
endif
endfor
# Loop:  for x from 1 to npotbreaks
endfor
# All files
select all
Remove
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
