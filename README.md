# MOPP-iOS

![EU Regional Development Fund](EL_Regionaalarengu_Fond_horisontaalne-vaike.jpg)

* License: LGPL 2.1
* &copy; Estonian Information System Authority

## libdigidocpp
Teek, millest sõltub RIA digidoc app, kasutab staatilist mitteametlikku libdigidocpp versiooni.
Rohkem infot: https://github.com/open-eid/libdigidocpp


## Buildi tegemine Xcode abil
Buildi tegemise eelduseks on cocoapods'i olemasolu masinas. Juhul kui cocoapods on puudu või sul on vanem versioon kui projekt ette näeb, jooksuta käsureal käsku "sudo gem install cocoapods". Rohkem infot: https://cocoapods.org/

Esimesel korral tuleb projektis ära määratud pod failid installida. Selleks tee nii:
 1. Navigeeri käsureal projekti kausta ja selle sees MoppApp kausta
 2. Jooksuta käsku "pod install"

Edaspidi võib olla vajalik "pod install" käsku korrata kui projektis on olnud pod failide osas muudatusi. Kui tegemist on ainult pod faili versiooni muudatusega siis piisab "pod update" käsust.

Ava projekt MoppApp.xcworkspace faili kaudu. Rakenduse buildimiseks kasuta MoppApp targetit.

## Dokumentide allkirjastamine kolmanda osapoole rakendustes
"Release" tabi alt leiad valmis frameworki mida saad kasutada oma rakenduses. Täpsema juhendi jaoks pöördu wiki poole.
