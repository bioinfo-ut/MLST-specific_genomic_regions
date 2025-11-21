#!/usr/bin/perl

open BLASTN, $ARGV[0] or die;

while(<BLASTN>){
    chomp;
    @line = split(/\t/);
    if($line[8] > $line[9]){
        $start = $line[9];
        $end = $line[8];
    }
    else{
        $start = $line[8];
        $end = $line[9];
    }
    print "$line[0]\t$line[1]\t$line[2]\t$line[3]\t$line[4]\t$line[5]\t$line[6]\t$line[7]\t$start\t$end\t$line[10]\t$line[11]\n";
}
