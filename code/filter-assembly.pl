#!/usr/bin/perl

use strict;
use warnings;

my ($r1, $r2, $contigs) = @ARGV;
die "Usage: $0 read_1.fastq read_2.fastq contigs.fasta\n"
    unless $r1 && $r2 && $contigs;

my $GENOME_SIZE = 2_900_000;

my $sample_id = $r1;
$sample_id =~ s!.*/!!;      
$sample_id =~ s/_.*$//;

sub total_bases_fastq {
    my ($file) = @_;
    open my $fh, "<", $file or die "Cannot open $file: $!\n";
    my $total = 0;
    while (1) {
        my $id = <$fh>;         
        last unless defined $id;
        my $seq  = <$fh>;       
        my $plus = <$fh>;       
        my $qual = <$fh>;       
        chomp $seq;
        $total += length($seq);
    }
    close $fh;
    return $total;
}

sub contig_lengths_fasta {
    my ($file) = @_;
    open my $fh, "<", $file or die "Cannot open $file: $!\n";
    my @lens;
    my $len = 0;
    while (my $line = <$fh>) {
        chomp $line;
        if ($line =~ /^>/) {
            push @lens, $len if $len > 0;
            $len = 0;
        } else {
            $len += length($line);
        }
    }
    push @lens, $len if $len > 0;
    close $fh;
    return @lens;
}

# total bases in paired reads
my $bases_r1 = total_bases_fastq($r1);
my $bases_r2 = total_bases_fastq($r2);
my $total_read_bases = $bases_r1 + $bases_r2;

my $avg_depth = $GENOME_SIZE ? ($total_read_bases / $GENOME_SIZE) : 0;

# contig stats
my @lens = contig_lengths_fasta($contigs);
die "No contigs found in $contigs\n" unless @lens;

my $total_contig_len = 0;
my $longest = 0;
for my $l (@lens) {
    $total_contig_len += $l;
    $longest = $l if $l > $longest;
}

# N50
@lens = sort { $b <=> $a } @lens;
my $half = $total_contig_len / 2;
my $cum  = 0;
my $N50  = 0;
for my $l (@lens) {
    $cum += $l;
    if ($cum >= $half) {
        $N50 = $l;
        last;
    }
}

#print "sample_id\tN50\tlongest_contig\tavg_depth\n";
printf "%s\t%d\t%d\t%.2f\n", $sample_id, $N50, $longest, $avg_depth;

