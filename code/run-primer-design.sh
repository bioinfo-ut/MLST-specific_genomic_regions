
# MLST type
ST=$1
# data location
kmer_path="data"
work_path="ST${ST}_primers"

mkdir -p ${work_path}

contig=`perl get-best-contig-for-ST.pl ${kmer_path}/ST${ST}_intersect_log.txt contig_statistics.txt ${ST}`

cp ${contig} ${work_path}/contigs.fasta

cat ${kmer_path}/ST${ST}_kmers.txt | perl make-fasta-from-list.pl > ${work_path}/ST${ST}_kmers.fasta

# BLAST
makeblastdb -in ${work_path}/contigs.fasta -dbtype nucl
blastn -task blastn -query ${work_path}/ST${ST}_kmers.fasta -db ${work_path}/contigs.fasta -out ${work_path}/ST${ST}_pos.blastn -outfmt 6 -num_threads 24 -perc_identity 100 -qcov_hsp_perc 100

perl fix-columns.pl ${work_path}/ST${ST}_pos.blastn > ${work_path}/ST${ST}_pos_corrected.blastn
sort -k9n ${work_path}/ST${ST}_pos_corrected.blastn > ${work_path}/ST${ST}_pos_corrected_sorted.blastn
perl extract-genomic-regions.pl ${work_path}/ST${ST}_pos_corrected_sorted.blastn ${work_path}/contigs.fasta > ${work_path}/ST${ST}_regions.fasta
  
# Primer3
perl run-primer3.pl ${work_path}/ST${ST}_regions.fasta 60-1000 > ${work_path}/ST${ST}_primers.txt
