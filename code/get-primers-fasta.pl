#!/usr/bin/perl

open(PRIMERS, $ARGV[0]) or die; 

while(<PRIMERS>){
    chomp;
    @line = split(/\t/);
    @tmp = split(/\|/, $line[0]);
    
    if($line[7]){
        print $tmp[0]."_L|".$line[3]."|".$line[5]."|".$line[7]."\n";
        print "$line[1]\n";
        print $tmp[0]."_R|".$line[4]."|".$line[6]."|".$line[7]."\n";
        print "$line[2]\n";
    }
}
