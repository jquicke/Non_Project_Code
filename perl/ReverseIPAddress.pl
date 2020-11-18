#!/usr/bin/perl

open(INFILE,"file.txt") or die "Can't open the input file\n";
open(OUTFILE,"> file.out") or die "Can't create output file\n";
while(my $row = <INFILE>) {
  chomp $row;
  my @mod_row = split(/\./, $row);
  my $col0 = $mod_row[0];
  my $col1 = $mod_row[1];
  my $col2 = $mod_row[2];
  my $col3 = $mod_row[3];
  print OUTFILE ("$col3.$col2.$col1.$col0\n");
}
close(OUTFILE);
close(INFILE);