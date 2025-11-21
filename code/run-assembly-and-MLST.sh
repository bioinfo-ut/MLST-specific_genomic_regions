#!/bin/bash

outdir=$3

echo "Input file1: $1"
echo "Input file2: $2"
echo "Output dir: $outdir"

mkdir $outdir

basename1=${1##*/}
basename2=${2##*/}

# adapter removal output
a_output1=$outdir"/"$basename1".clean.fq"
a_output2=$outdir"/"$basename2".clean.fq"

# SPAdes output dir
g_output=$outdir"/"$basename1"_assembly"

# mlst result file
m_output=$outdir"/"$basename1".mlst.txt"

fastp --in1 $1 --out1 $a_output1 --in2 $2 --out2 $a_output2 --length_required 50 --cut_tail --cut_front --cut_mean_quality 30 --detect_adapter_for_pe --thread 32

# Genome assembly with SPAdes
# https://github.com/ablab/spades

spades.py -1 $a_output1 -2 $a_output2 --threads 24 --memory 32 --isolate -o $g_output

# MLST typing
# https://github.com/tseemann/mlst

mlst $g_output/contigs.fasta > $m_output
