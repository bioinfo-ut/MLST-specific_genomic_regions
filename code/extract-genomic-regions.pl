#!/usr/bin/perl

open BLASTN, $ARGV[0] or die;
open FASTA, $ARGV[1] or die;

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
    if(!$last_reg_end){
        $reg_start = $start;
    }
    
    if($last_reg_end && ($start - $last_reg_end) > 32){
        push(@left, $reg_start);
        push(@right, $last_reg_end);
        $reg_start = $start;
    }    
    $last_reg_end = $end;    
}

if($last_reg_end && ($start - $last_reg_end) > 32){
    push(@left, $reg_start);
    push(@right, $last_reg_end);
}

while(<FASTA>){
    chomp;
    next if(/^>/);
    $seq .= $_;
}

for($i = 0; $i < scalar(@left); $i++){
    if($right[$i] - $left[$i] > 60){
        $j++;
        print ">region".$j."|$left[$i]|$right[$i]|".($right[$i] - $left[$i])."\n";
        print substr($seq, $left[$i]-1, $right[$i]-$left[$i])."\n";
    }
}
