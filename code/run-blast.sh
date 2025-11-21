
ST=$1

perl get-primers-fasta.pl ST${ST}_primers/ST${ST}_primers.txt > ST${ST}_primers/ST${ST}_primers.fasta

for ST2 in 5 7 8 9 29 37 87 101 121 155 173 177 451 425 551 580 1247
do
    blastn -task blastn -query ST${ST}_primers/ST${ST}_primers.fasta -db blast_db/${ST2}_contigs.fasta -out ST${ST}_primers/ST${ST}_vs_ST${ST2}.blastn -outfmt 0 -num_threads 24 -qcov_hsp_perc 100
    perl parse_blast.pl ST${ST}_primers/ST${ST}_vs_ST${ST2}.blastn > ST${ST}_primers/ST${ST}_vs_ST${ST2}.blastn.parsed.txt
    perl filter-blast-results.pl ST${ST}_primers/ST${ST}_primers.fasta ST${ST}_primers/ST${ST}_vs_ST${ST2}.blastn.parsed.txt > ST${ST}_primers/ST${ST}_vs_ST${ST2}_good_primers.txt
done
