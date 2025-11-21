#!/usr/bin/perl

use strict;
use lib "BioPerl-1.6.1";
use Bio::SearchIO;

my $last_probe;
my $last_genome;
my $genome;
my $probe;
my $result;
my $hit;
my $hsp;
my $mismatch_pos;

my $in = new Bio::SearchIO(-format => 'blast',
                           -best   => 'true', 
                           -file   => "$ARGV[0]");
while( my $result = $in->next_result ) {
    while( my $hit = $result->next_hit ) {
        while( my $hsp = $hit->next_hsp ) {                                    
            if($hsp->percent_identity < 100){
                $mismatch_pos = join(",",$hsp->seq_inds('query','nomatch'));
            }
            else{
                $mismatch_pos = ".";
            }
            print $result->query_name."\t".$hit->name."\t".$hsp->percent_identity."\t".$result->query_length."\t".$hsp->length."\t".$hsp->start('query')."\t".$hsp->end('query')."\t".$hsp->start('hit')."\t".$hsp->end('hit')."\t".$hsp->strand('hit')."\t".$mismatch_pos."\t".$hsp->query_string."\t".$hsp->homology_string."\t".$hsp->hit_string."\t".$hit->description."\n";                
        }
    }
}
