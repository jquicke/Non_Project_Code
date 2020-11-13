#!/bin/bash

# Version: 20130917

split="/mnt/customer_data/being_processed/pfguser/split"
load="/mnt/customer_data/being_processed/pfguser/load"

mv "$split/100" "$load/15_100_afi.csv"
mv "$split/125" "$load/13_125_ccounty.csv"
mv "$split/130" "$load/234_130_hale.csv"
mv "$split/140" "$load/237_140_lester.csv"
mv "$split/161" "$load/238_161_middendorf.csv"
mv "$split/165" "$load/235_165_littlerock.csv"
mv "$split/166" "$load/239_166_batesville.csv"
mv "$split/170" "$load/236_170_springfield.csv"
mv "$split/240" "$load/240_240_powell.csv"
mv "$split/300" "$load/241_300_empiresf.csv"
mv "$split/410" "$load/242_410_arizona.csv"
mv "$split/412" "$load/243_412_dallas.csv"
mv "$split/414" "$load/233_414_denver.csv"
mv "$split/421" "$load/244_421_minnesota.csv"
mv "$split/425" "$load/231_425_nocal.csv"
mv "$split/427" "$load/230_427_portland.csv"
mv "$split/431" "$load/17_431_philly.csv"
