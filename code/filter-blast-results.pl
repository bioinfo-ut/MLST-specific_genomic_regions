#!/usr/bin/perl

open(PRIMERS, $ARGV[0]) or die;
open(BLAST, $ARGV[1]) or die;

while(<PRIMERS>){
    chomp;
    if(/^>/){
        $_ =~ s/\s+//;
        @line = split(/\|/);
        push (@L_primers, substr($line[0], 1));
        $name = substr($line[0], 1);
        $L_prim_name{$name} = $_;
        
        $_ = <PRIMERS>;
        chomp;
        $L_prim_seq{$name} = $_;
        $_ = <PRIMERS>;
        $_ =~ s/\s+//;
        @line = split(/\|/);
        $name = substr($line[0], 1);
        $R_prim_name{$name} = $_;
        
        $_ = <PRIMERS>;
        chomp;
        $R_prim_seq{$name} = $_;
    }
}

while(<BLAST>){
    chomp;
    @line = split(/\t/);
    $line[0] =~ s/\s+//;
    @tmp = split(/\|/, $line[0]);
    $line[1] =~ s/\s+//;    
    
    $contigs{$line[1]} = 1;
    
    if($last_genome ne $line[1] || $last_primer ne $tmp[0]){
        $ident{$tmp[0]}{$line[1]} = $line[2];
        $q_len{$tmp[0]}{$line[1]} = $line[3];
        $h_len{$tmp[0]}{$line[1]} = $line[4];
        $q_start{$tmp[0]}{$line[1]} = $line[5];
        $q_end{$tmp[0]}{$line[1]} = $line[6];
        $h_start{$tmp[0]}{$line[1]} = $line[7];
        $h_end{$tmp[0]}{$line[1]} = $line[8];
        $h_strand{$tmp[0]}{$line[1]} = $line[9];
        $mm_pos{$tmp[0]}{$line[1]} = $line[10];
        $q_seq{$tmp[0]}{$line[1]} = $line[11];
        $a_seq{$tmp[0]}{$line[1]} = $line[12];
        $h_seq{$tmp[0]}{$line[1]} = $line[13];
        
        $tm_L{$tmp[0]}{$line[1]} = $tmp[1];
        $tm_R{$tmp[0]}{$line[1]} = $tmp[2]; 
        $prod{$tmp[0]}{$line[1]} = $tmp[3];
        
        $last_genome = $line[1];
        $last_primer = $tmp[0];
    }
}

foreach $L_primer (@L_primers){
    $prod_size = "";
    foreach $contig (keys (%contigs)){
        $R_primer = $L_primer;
        $R_primer =~ s/\_L/\_R/;
        
        #remove hits having missing mate
        if(!$ident{$L_primer}{$contig} || !$ident{$R_primer}{$contig}){
            $error1{$L_primer} = 1;
            next;
        }
        
        @L_three_end_mm_pos = split(/\,/, $mm_pos{$L_primer}{$contig});
        @R_three_end_mm_pos = split(/\,/, $mm_pos{$R_primer}{$contig});
        
        #remove hits having a mismatch in 3' end (6 nt)
        if($q_len{$L_primer}{$contig} - $L_three_end_mm_pos[-1] < 6 || $q_len{$R_primer}{$contig} - $R_three_end_mm_pos[-1] < 6){
            $error2{$L_primer} = 1;
            next;
        }
        
        if($h_strand{$L_primer}{$contig} < 0){
            $prod_start = $h_start{$R_primer}{$contig};
            $prod_end = $h_end{$L_primer}{$contig}                
        }
        else{
            $prod_start = $h_start{$L_primer}{$contig};
        }   $prod_end = $h_end{$R_primer}{$contig};
        
        $prod_size = $prod_end - $prod_start + 1;
        if($prod_size > 1 && $prod_size < 1000){
            $error3{$L_primer} = 1;
            $not_good_primers{$L_primer} = 1;
        }        
    }
}

foreach $L_primer (@L_primers){
    $R_primer = $L_primer;
    $R_primer =~ s/\_L/\_R/;
    if(!$not_good_primers{$L_primer}){
        print $L_prim_name{$L_primer}."\n".$L_prim_seq{$L_primer}."\n";
        print $R_prim_name{$R_primer}."\n".$R_prim_seq{$R_primer}."\n";
    }        
}
