# -*- coding: utf-8 -*-
# AppBackup
# An iOS application that backs up and restores the saved data and
# preferences of App Store apps.
#
# Copyright (C) 2008-2014 Scott Zeid
# https://s.zeid.me/projects/appbackup/
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# 
# Except as contained in this notice, the name(s) of the above copyright holders
# shall not be used in advertising or otherwise to promote the sale, use or
# other dealings in this Software without prior written authorization.

# Utility classes and functions

__all__ = ["escape_utf8", "safe_print", "strip_latin_diacritics", "to_unicode"]

# Table of Latin Diacritical Marks
# These were taken from the "Letters with diacritics" section of the Wikipedia
# article, "List of Latin Letters"
# (http://en.wikipedia.org/wiki/List_of_Latin_letters#Letters_with_diacritics).
# At the time of this writing (2009-08-17), it was released under the Creative
# Commons Attribution-ShareAlike license.
LATIN_DIACRITICS_TABLE = {
 "A": u"ÁÀĂẮẰẴẲÂẤẦẪẨǍÅǺÄǞÃȦǠĄĀẢȀȂẠẶẬḀȺǼǢ", "B": u"ḂḄḆɃƁƂ", "C": u"ĆĈČĊÇḈȻƇ",
 "D": u"ĎḊḐḌḒḎĐƉƊƋ", "E": u"ÉÈĔÊẾỀỄỂĚËẼĖȨḜĘĒḖḔẺȄȆẸỆḘḚɆ", "F": u"ḞƑ",
 "G": u"ǴĞĜǦĠĢḠǤƓ", "H": u"ĤȞḦḢḨḤḪH̱ĦⱧ", "I": u"ÍÌĬÎǏÏḮĨİĮĪỈȈȊỊḬIƗᵻ",
 "J": u"ĴJ̌Ɉ", "K": u"ḰǨĶḲḴꝄꝂꝀƘⱩ", "L": u"ĹĽĻḶḸḼḺŁŁĿȽⱠⱢꝈꝆ", "M": u"ḾṀṂ",
 "N": u"ŃǸŇÑṄŅṆṊṈƝȠN", "O": u"ÓÒŎÔỐỒỖỔǑÖȪŐÕṌṎȬȮȰØǾǪǬŌṒṐỎȌȎƠỚỜỠỞỢỌỘƟꝊꝌ",
 "P": u"ṔṖⱣꝐƤꝒꝔP", "Q": u"ꝘɊ", "R": u"ŔŘṘŖȐȒṚṜṞɌꞂⱤ", "S": u"ŚṤŜŠṦṠŞṢṨȘSꞄ",
 "SS": u"ẞ", "T": u"ŤTṪŢṬȚṰṮŦȾƬƮ", "U": u"ÚÙŬÛǓŮÜǗǛǙǕŰŨṸŲŪṺỦȔȖƯỨỪỮỬỰỤṲṶṴɄᵾ",
 "V": u"ṼṾƲ", "W": u"ẂẀŴW̊ẄẆẈꝠ", "X": u"ẌẊ", "Y": u"ÝỲŶY̊ŸỸẎȲỶỴʏɎƳ",
 "Z": u"ŹẐŽŻẒẔƵȤⱫǮꝢ",
 "a": u"áàăắằẵẳâấầẫẩǎåǻäǟãȧǡąāảȁȃạặậḁⱥᶏǽǣᶐ", "b": u"ḃḅḇƀᵬᶀɓƃ",
 "c": u"ćĉčċçḉȼƈɕ", "d": u"ďḋḑḍḓḏđᵭᶁɖɗᶑƌȡ",
 "e": u"éèĕêếềễểěëẽėȩḝęēḗḕẻȅȇẹệḙḛɇᶒᶕɚᶓᶔɝ", "f": u"ḟᵮᶂƒ", "g": u"ǵğĝǧġģḡǥᶃɠ",
 "h": u"ĥȟḧḣḩḥḫẖħⱨ", "i": u"íìĭîǐïḯĩiįīỉȉȋịḭıɨᶖ", "j": u"ĵǰȷɉʝɟʄ",
 "k": u"ḱǩķḳḵꝅꝃꝁᶄƙⱪ", "l": u"ĺľļḷḹḽḻłł̣ŀƚⱡɫꝉꝇɬᶅɭȴ", "m": u"ḿṁṃᵯᶆɱ",
 "n": u"ńǹňñṅņṇṋṉᵰɲƞᶇɳȵn̈", "o": u"óòŏôốồỗổǒöȫőõṍṏȭȯȱøǿǫǭōṓṑỏȍȏơớờỡởợọộɵꝋꝍ",
 "p": u"ṕṗᵽꝑᶈƥꝓꝕp̃", "q": u"ʠꝙɋ", "r": u"ŕřṙŗȑȓṛṝṟɍᵲᶉɼꞃɽɾᵳ",
 "s": u"śṥŝšṧṡẛşṣṩșᵴᶊʂȿs̩ꞅᶋᶘ", "ss": u"ß", "t": u"ťẗṫţṭțṱṯŧⱦᵵƫƭʈȶ",
 "u": u"úùŭûǔůüǘǜǚǖűũṹųūṻủȕȗưứừữửựụṳṷṵʉᶙᵿ", "v": u"ṽṿᶌʋⱴ", "w": u"ẃẁŵẘẅẇẉꝡ",
 "x": u"ẍẋᶍ", "y": u"ýỳŷẙÿỹẏȳỷỵɏƴ", "z": u"źẑžżẓẕƶᵶᶎȥʐʑɀⱬǯᶚƺꝣ"
}

def escape_utf8(s):
 """Escapes UTF-8 characters; there's probably a much simpler way to do this."""
 r = repr(s.encode("utf8", "replace"))
 if len(r) >= 2:
  if r[0] == "'" and r[-1] == "'":
   return r[1:-1]
  if r[0] == '"' and r[-1] == '"':
   return r[1:-1]
 return r

def safe_print(s):
 """Prints the given string, compensating for Unicode errors."""
 try: print s
 except UnicodeError: print strip_latin_diacritics(s).encode("ascii", "replace")

def strip_latin_diacritics(s):
 """Strip diacritical marks from Latin letters.

Replaces Latin letters with diacritical marks with the same letters without
diacritics, preserving case.  Input must be in Unicode.

Letter to diacritical mark mappings are found in latin_diacritics.py and sourced
from Wikipedia.

"""
 ret = to_unicode(s, errors="ignore")
 for letter in LATIN_DIACRITICS_TABLE:
  for i in LATIN_DIACRITICS_TABLE[letter]:
   ret = ret.replace(i, letter)
 return ret

def to_unicode(s, encoding="utf8", errors="strict"):
 if isinstance(s, unicode):
  return s
 if isinstance(s, (str, buffer)):
  return unicode(s, encoding, errors=errors)
 return unicode(s, errors=errors)
