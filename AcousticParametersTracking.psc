# FormantTracking.psc
# Script implemented by Plinio A. Barbosa (IEL/Univ. of Campinas, Brazil) for computing
# a set of data values for Forensic analysis (F1, F2, F3, Rate of F2 transition, Baseline, medianf0, Espectral Emphasis). Modified in August 2023 for use by the Variem group.
# Copyright (C) Jun, 2013, 2023  Barbosa, P. A.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; version 2 of the License.
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
# Version 2.0, customized for Livia Oushiro and Danielle Bento in Sept 2023.
form File acquisition
 word File_(TextGrid) PRC_F3C_MaluG
 word Audiofile PRC_F3C_MaluG.wav
 word OutPutFile OutPutFile.txt
 integer WordTier 2
 integer SegTier 6
 integer RtranscTier 3
 integer PartTier 8
 integer Fmax_(Hz) 5500
 integer MaxFormant 5
endform
#
filedelete 'outPutFile$'
fileappend 'outPutFile$' word vowel r_transc part dur F1.1 F1.2 F1.3 F1.4 F1.5 F1.6 F1.7 F1.8 F1.9 F1.10 F2.1 F2.2 F2.3 F2.4 F2.5 F2.6 F2.7 F2.8 F2.9 F2.10 F3.1 F3.2 F3.3 F3.4 F3.5 F3.6 F3.7 F3.8 F3.9 F3.10 'newline$'
# Reads AudioFile
Read from file... 'audiofile$'
audiofilename$ = selected$("Sound")
To Formant (burg)... 0.0 'maxFormant' 'fmax' 0.025 50
select Sound 'audiofilename$'
# Reads TG File
arq$ = file$ + ".TextGrid"
Read from file... 'arq$'
begin = Get starting time
end = Get finishing time
totaldur = end - begin
nsegs = Get number of intervals... 'segTier'
nvow = 0
sdur = 0
for i from 2 to nsegs - 1
 seg'i'$ = Get label of interval... 'segTier' 'i'
 if seg'i'$  != ""
  temp$ = mid$(seg'i'$,1,1)
  call isvowel 'temp$'
  if truevowel
   nvow = nvow + 1
   itime = Get starting point... 'segTier' 'i'
   ftime = Get end point... 'segTier' 'i'
   dur = (ftime - itime)*1000
   middle_vow = (ftime + itime)/2
   dur'nvow' = dur
   sdur = sdur + dur'nvow'
   intword = Get interval at time... 'wordTier' 'middle_vow'
   inttransc = Get interval at time... 'rtranscTier' 'middle_vow'
   intpart = Get interval at time... 'partTier' 'middle_vow'
   wordname'nvow'$ = Get label of interval... 'wordTier' 'intword'
   sent'nvow'$ = Get label of interval... 'rtranscTier' 'inttransc'
   part'nvow'$ = Get label of interval... 'partTier' 'intpart'
   name'nvow'$ = seg'i'$
# Tracking formant movement rate
   select Formant 'audiofilename$'
   step = (ftime-itime)/10
   select TextGrid 'file$'
   select Formant 'audiofilename$'
   tcurr = itime
   ct = 1
   repeat
    f1'nvow''ct' = Get value at time... 1 'tcurr' Hertz Linear
    f2'nvow''ct' = Get value at time... 2 'tcurr' Hertz Linear
    f3'nvow''ct' = Get value at time... 3 'tcurr' Hertz Linear
    tcurr = tcurr + step
    ct = ct + 1
   until tcurr > ftime
  endif
 endif
  select TextGrid 'file$'
endfor
for j from 1 to nvow
 name$ = name'j'$
 wordname$ = wordname'j'$
 sent$ = sent'j'$
 part$ = part'j'$
 f11 = f1'j'1
 f12 = f1'j'2
 f13 = f1'j'3
 f14 = f1'j'4
 f15 = f1'j'5
 f16 = f1'j'6
 f17 = f1'j'7
 f18 = f1'j'8
 f19 = f1'j'9
 f110 = f1'j'10
 f21 = f2'j'1
 f22 = f2'j'2
 f23 = f2'j'3
 f24 = f2'j'4
 f25 = f2'j'5
 f26 = f2'j'6
 f27 = f2'j'7
 f28 = f2'j'8
 f29 = f2'j'9
 f210 = f2'j'10
 f31 = f3'j'1
 f32 = f3'j'2
 f33 = f3'j'3
 f34 = f3'j'4
 f35 = f3'j'5
 f36 = f3'j'6
 f37 = f3'j'7
 f38 = f3'j'8
 f39 = f3'j'9
 f310 = f3'j'10
 dur = dur'j'
 fileappend 'outPutFile$' 'wordname$' 'name$' 'sent$' 'part$' 'dur:0' 'f11:0' 'f12:0' 'f13:0' 'f14:0' 'f15:0' 'f16:0' 'f17:0' 'f18:0' 'f19:0' 'f110:0' 'f21:0' 'f22:0' 'f23:0' 'f24:0' 'f25:0' 'f26:0' 'f27:0' 'f28:0' 'f29:0' 'f210:0' 'f31:0' 'f32:0' 'f33:0' 'f34:0' 'f35:0' 'f36:0' 'f37:0' 'f38:0' 'f39:0' 'f310:0''newline$'
endfor
procedure isvowel temp$
 truevowel = 0
 if temp$ = "i" or  temp$ = "e"  or temp$ = "^"  or temp$ = "a"  or temp$ = "o"  or temp$ = "u" or temp$ = "I" or temp$ = "E"
    ...or temp$ = "A"  or temp$ = "y" or temp$ = "O"  or temp$ = "U" or temp$ = "6"  or temp$ = "@"
    ...or temp$ = "2" or temp$ = "9" or temp$ = "Y" or temp$ = "Ä" or temp$ = "Å" or temp$ = "Ö" or temp$ = "x"
    truevowel = 1
 endif
endproc 