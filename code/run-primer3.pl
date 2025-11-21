#!/usr/bin/perl

open SEQ, "$ARGV[0]" or die; #fasta file
$prod_size = $ARGV[1] or die; #product range: 100-200

while(<SEQ>){
    chomp;
    if(/^>/){
        $id =~ s/>//;
        $id = $_;
    }
    else{
        $seq{$id} .= $_;
    }
}

foreach $sequence (keys %seq){
    $count = 0;
    open P3IN, ">p3_input.txt" or die;
    
print P3IN<<content;
SEQUENCE_TEMPLATE=$seq{$sequence}
PRIMER_TASK=generic
PRIMER_PICK_LEFT_PRIMER=1
PRIMER_PICK_INTERNAL_OLIGO=0
PRIMER_PICK_RIGHT_PRIMER=1
PRIMER_OPT_SIZE=20
PRIMER_MIN_SIZE=18
PRIMER_MAX_SIZE=22
PRIMER_PAIR_MAX_DIFF_TM=3
PRIMER_PRODUCT_SIZE_RANGE=$prod_size
PRIMER_NUM_RETURN=1
PRIMER_EXPLAIN_FLAG=1
=
content
  
    close P3IN;
    system("./primer3_core --strict_tags < p3_input.txt > p3_output.txt");
    
    open P3OUT, "p3_output.txt" or die;    
    print "$sequence";
    while(<P3OUT>){
        chomp;
        @line = split(/\=/);
        if($line[0] =~ /_SEQUENCE/){
            $count++;
            if($count > 2){
                $count = 1;
                print "\n$sequence\t$line[1]";
            }
            else{
                print "\t$line[1]";
            }
        }        
        elsif($line[0] =~ /0_TM/ || $line[0] =~ /_GC_PERCENT/){
            print "\t$line[1]";            
        }
        elsif($line[0] =~ /PRIMER_PAIR_0_PRODUCT_SIZE/){
            print "\t$line[1]";
        }
    }
    print "\n";
    close P3OUT;
}
