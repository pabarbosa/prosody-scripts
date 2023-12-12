# ConvertArticDatatoPraat.psc
# Script implemented by Plinio A. Barbosa (IEL/Univ. of Campinas, Brazil) for converting a Table with acoustic and articulatory data to Praat objects.
#  It also computes de 1st and 2nd derivatives of the articulator movement and created a TG markink maxima and minima of velocity and acceleration.
#
# The TextGrid and Reference-statistics (xy.TableOfReal, where xy = BP, EP, F, G, or BE) files need
# to be in the same directory if a VV Tier will be used. 
# Copyright (C) 2023  Barbosa, P. A.
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
# Date: Version (1.0): Dec 2023
form File acquisition
 word extTable *.txt
 word acoustColumn acoustics
 word articColumn Jaw_z
 integer acoustSamplingRate 22050
 integer articSamplingRate 100
 boolean withSmoothing 1
 integer degreeSmoothing_(Hz) 5
endform
# Picks all txt files in the folder where the script is
Create Strings as file list... list 'extTable$'
numberOfFiles = Get number of strings
if !numberOfFiles
	exit There are no txt files (tables) in the folder!
endif
## Start of all computations for all pairs of audio/TG files
for ifile from 1 to numberOfFiles
select Strings list
tablefile$ = Get string... ifile
Read Table from tab-separated file: "'tablefile$'"
tablename$ = selected$("Table")
Copy... temp
ncol = Get number of columns
# Isolating the acoustic data
i = 1
while i <= ncol
 labcol$ = Get column label... 'i'
 if labcol$ != "'acoustColumn$'"
  Remove column: "'labcol$'"
  ncol = ncol -1 
  i = i-1
 endif
 i = i  +1
endwhile
Down to Matrix
Transpose
To Sound
Scale times by: 1/'acoustSamplingRate'
Subtract mean
Scale peak: 0.99
durSound = Get total duration
Rename... SoundFile
selectObject: "Table 'tablename$'"
Copy... temp
ncol = Get number of columns
# Isolating the articulatory data
i = 1
while i <= ncol
 labcol$ = Get column label... 'i'
 if labcol$ != "'articColumn$'"
  Remove column: "'labcol$'"
  ncol = ncol -1 
  i = i-1
 endif
 i = i  +1
endwhile
Extract rows where column (number): "'articColumn$'", "less than", 100
Down to Matrix
Transpose
To Sound
Scale times by: 1/'articSamplingRate'
Subtract mean
Scale peak: 0.99
Rename... ArticFile
durArtic = Get total duration
if durSound > durArtic
 selectObject: "Sound SoundFile"
 Extract part: 0, 'durArtic', "rectangular", 1, "no"
 Rename... SoundFile
else
 selectObject: "Sound ArticFile"
 Extract part: 0, 'durSound', "rectangular", 1, "no"
 Rename... ArticFile
endif
selectObject: "Sound ArticFile"
if withSmoothing
 Filter (pass Hann band): 0, 'degreeSmoothing', 1
endif
Subtract mean
Scale peak: 0.99
Copy... temp
Formula: "self [col+1] - self"
Rename... deriv1st_ArticFile
if withSmoothing
 Filter (pass Hann band): 0, 'degreeSmoothing', 1
endif
Subtract mean
Scale peak: 0.99
Copy... temp
Formula: "self [col+1] - self"
Subtract mean
Rename... deriv2nd_ArticFile
Scale peak: 0.99
# Selectiing the audio file and the articulation files
selectObject: "Sound SoundFile"
plusObject: "Sound ArticFile"
plusObject: "Sound deriv1st_ArticFile"
plusObject: "Sound deriv2nd_ArticFile"
Resample: 10000, 50
selectObject: "Sound deriv2nd_ArticFile_10000"
plusObject: "Sound deriv1st_ArticFile_10000"
Combine to stereo
plusObject: "Sound ArticFile_10000"
Combine to stereo
plusObject: "Sound SoundFile_10000"
Combine to stereo
Rename... CombinedFile
Save as WAV file: "'tablename$'.wav"
# Detection of maxima of first derivative
To PointProcess (extrema): 3, "yes", "no", "cubic"
Up to TextTier: "max"
Rename... tierMaxVeloc
selectObject: "Sound CombinedFile"
To PointProcess (extrema): 3, "no", "yes", "cubic"
Up to TextTier: "min"
Rename... tierMinVeloc
selectObject: "Sound CombinedFile"
# Detection of maxima of the articulator movement
To PointProcess (extrema): 2, "no", "yes", "cubic"
npoints = Get number of points
for j from 1 to npoints 
 maxtime= Get time from index... 'j'
 selectObject: "Sound CombinedFile"
 value = Get value at time... 2 'maxtime' nearest
 selectObject: "PointProcess CombinedFile"
 if abs(value) < 0.005
   Remove point... 'j'
   npoints = npoints - 1
   j = j -1
 endif
endfor
Up to TextTier: "min"
selectObject: "TextTier tierMaxVeloc"
Copy... tierMaxVeloc
selectObject: "TextTier tierMinVeloc"
Copy... tierMinVeloc
selectObject: "TextTier CombinedFile"
plusObject: "TextTier tierMaxVeloc"
plusObject: "TextTier tierMinVeloc"
Into TextGrid
Rename... Velocity
selectObject: "Sound CombinedFile"
# Detection of maxima of the articulator acceleration
To PointProcess (extrema): 4, "yes", "no", "cubic"
Up to TextTier: "max"
Rename... tierMaxAccel
selectObject: "Sound CombinedFile"
# Detection of minima of the articulator acceleration
To PointProcess (extrema): 4, "no", "yes", "cubic"
Up to TextTier: "min"
Rename... tierMinAccel
selectObject: "TextTier tierMaxAccel"
plusObject: "TextTier tierMinAccel"
Into TextGrid
Rename... Acceleration
selectObject: "TextGrid Velocity"
plusObject: "TextGrid Acceleration"
Merge
Set tier name... 1 maxDisp
Set tier name... 2 maxVel
Set tier name... 3 minVel
Set tier name... 4 maxAcc
Set tier name... 5 minAcc
Save as text file: "'tablename$'.TextGrid"
select all
minusObject: "Strings list"
Remove
endfor
