#!/usr/bin/perl

open(INT, $ARGV[0]) or die; # ST101_intersect_log.txt
open(COV, $ARGV[1]) or die; # filter_assembly.pl result table (tabulated)
$ST = $ARGV[2] or die; #1247

$max_length = 0;

while(<INT>){
    chomp;
    @line = split(/\t/);
    $samples{$line[0]} = 1;
}

while(<COV>){
    chomp;
    @line = split(/\t/);
    next if (!$samples{$line[0]});
    # Third column contains the longest length
    if($line[2] > $max_length){        
        $max_length = $line[2];
        $contig_path = $line[0]."/contigs.fasta";            
    }
}
print "$contig_path\n";
