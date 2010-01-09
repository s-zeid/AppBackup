# -*- coding: utf-8 -*-
# AppBackup
# An iPhoneOS application that backs up and restores the saved data and
# preferences of App Store apps.
#
# Copyright (C) 2008-2010 Scott Wallace
# http://www.scott-wallace.net/iphone/appbackup
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
#
# Loosely based on Dave Arter's (dave@minus-zero.org) sample code from the
# iPhone/Python package.

# Latin Diacritical Marks
# These were taken from the "Letters with diacritics" section of the Wikipedia
# article, "List of Latin Letters"
# (http://en.wikipedia.org/wiki/List_of_Latin_letters#Letters_with_diacritics).
# At the time of this writing (2009-08-17), it was released under the Creative
# Commons Attribution-ShareAlike license.

shared.latin_diacritics = {
 "A": u"ÁÀĂẮẰẴẲÂẤẦẪẨǍÅǺÄǞÃȦǠĄĀẢȀȂẠẶẬḀȺǼǢ",
 "B": u"ḂḄḆɃƁƂ",
 "C": u"ĆĈČĊÇḈȻƇ",
 "D": u"ĎḊḐḌḒḎĐƉƊƋ",
 "E": u"ÉÈĔÊẾỀỄỂĚËẼĖȨḜĘĒḖḔẺȄȆẸỆḘḚɆ",
 "F": u"ḞƑ",
 "G": u"ǴĞĜǦĠĢḠǤƓ",
 "H": u"ĤȞḦḢḨḤḪH̱ĦⱧ",
 "I": u"ÍÌĬÎǏÏḮĨİĮĪỈȈȊỊḬIƗᵻ",
 "J": u"ĴJ̌Ɉ",
 "K": u"ḰǨĶḲḴꝄꝂꝀƘⱩ",
 "L": u"ĹĽĻḶḸḼḺŁŁĿȽⱠⱢꝈꝆ",
 "M": u"ḾṀṂ",
 "N": u"ŃǸŇÑṄŅṆṊṈƝȠN",
 "O": u"ÓÒŎÔỐỒỖỔǑÖȪŐÕṌṎȬȮȰØǾǪǬŌṒṐỎȌȎƠỚỜỠỞỢỌỘƟꝊꝌ",
 "P": u"ṔṖⱣꝐƤꝒꝔP",
 "Q": u"ꝘɊ",
 "R": u"ŔŘṘŖȐȒṚṜṞɌꞂⱤ",
 "S": u"ŚṤŜŠṦṠŞṢṨȘSꞄ",
 "T": u"ŤTṪŢṬȚṰṮŦȾƬƮ",
 "U": u"ÚÙŬÛǓŮÜǗǛǙǕŰŨṸŲŪṺỦȔȖƯỨỪỮỬỰỤṲṶṴɄᵾ",
 "V": u"ṼṾƲ",
 "W": u"ẂẀŴW̊ẄẆẈꝠ",
 "X": u"ẌẊ",
 "Y": u"ÝỲŶY̊ŸỸẎȲỶỴʏɎƳ",
 "Z": u"ŹẐŽŻẒẔƵȤⱫǮꝢ",
 "a": u"áàăắằẵẳâấầẫẩǎåǻäǟãȧǡąāảȁȃạặậḁⱥᶏǽǣᶐ",
 "b": u"ḃḅḇƀᵬᶀɓƃ",
 "c": u"ćĉčċçḉȼƈɕ",
 "d": u"ďḋḑḍḓḏđᵭᶁɖɗᶑƌȡ",
 "e": u"éèĕêếềễểěëẽėȩḝęēḗḕẻȅȇẹệḙḛɇᶒᶕɚᶓᶔɝ",
 "f": u"ḟᵮᶂƒ",
 "g": u"ǵğĝǧġģḡǥᶃɠ",
 "h": u"ĥȟḧḣḩḥḫẖħⱨ",
 "i": u"íìĭîǐïḯĩiįīỉȉȋịḭıɨᶖ",
 "j": u"ĵǰȷɉʝɟʄ",
 "k": u"ḱǩķḳḵꝅꝃꝁᶄƙⱪ",
 "l": u"ĺľļḷḹḽḻłł̣ŀƚⱡɫꝉꝇɬᶅɭȴ",
 "m": u"ḿṁṃᵯᶆɱ",
 "n": u"ńǹňñṅņṇṋṉᵰɲƞᶇɳȵn̈",
 "o": u"óòŏôốồỗổǒöȫőõṍṏȭȯȱøǿǫǭōṓṑỏȍȏơớờỡởợọộɵꝋꝍ",
 "p": u"ṕṗᵽꝑᶈƥꝓꝕp̃",
 "q": u"ʠꝙɋ",
 "r": u"ŕřṙŗȑȓṛṝṟɍᵲᶉɼꞃɽɾᵳ",
 "s": u"śṥŝšṧṡẛşṣṩșᵴᶊʂȿs̩ꞅᶋᶘ",
 "t": u"ťẗṫţṭțṱṯŧⱦᵵƫƭʈȶ",
 "u": u"úùŭûǔůüǘǜǚǖűũṹųūṻủȕȗưứừữửựụṳṷṵʉᶙᵿ",
 "v": u"ṽṿᶌʋⱴ",
 "w": u"ẃẁŵẘẅẇẉꝡ",
 "x": u"ẍẋᶍ",
 "y": u"ýỳŷẙÿỹẏȳỷỵɏƴ",
 "z": u"źẑžżẓẕƶᵶᶎȥʐʑɀⱬǯᶚƺꝣ"
}
