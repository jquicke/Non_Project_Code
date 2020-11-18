#!/usr/local/bin/perl -w
open(LIST,"names.txt") or die "Can't open the input file\n";
open(OUTFILE,"> bcp_table.sh") or die "Can't create output file\n";
while(<LIST>) {
        $name = $_;
        chomp $name;
        print OUTFILE ("bcp HRPROD..$name out $name.out -Usa -Plolly99
-RTAHR -c\n");
        }
close(OUTFILE);
close(LIST);