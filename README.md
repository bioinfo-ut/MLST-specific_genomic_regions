# MLST-specific genomic regions

This repository contains code implements of the computational workflow for:

- assembling *L. monocytogenes* genomes and calling MLST types
- finding type-specific k-mers from reads
- mapping type-specific k-mers to assemblies to obtain candidate regions
- designing and cross-checking type-specific PCR primers

---

## Contents

All scripts referenced in the paper are in the `code/` directory:

**Main shell pipelines (entry points)**

- `run-assembly-and-MLST.sh` – trim reads, assemble with SPAdes, call MLST
- `run-primer-design.sh` – for a given ST, map type-specific k-mers, extract regions, design primers
- `run-blast.sh` – check designed primers against other STs to remove cross-reactive primers.

**Helper Perl scripts**

Used internally by the shell pipelines:

- `filter-assembly.pl` – compute N50, longest contig and average depth for a sample
- `make-fasta-from-list.pl` – convert k-mer lists to FASTA
- `get-best-contig-for-ST.pl` – choose best contig for a given ST from coverage stats
- `extract-genomic-regions.pl` – merge BLAST hits into genomic regions and extract sequences
- `fix-columns.pl` – clean/normalize BLAST tabular output.
- `run-primer3.pl` – wrapper for `primer3_core` (60–1000 bp products, 18–22 nt primers).
- `get-primers-fasta.pl` – convert primer table to FASTA with metadata in headers.
- `parse_blast.pl`, `filter-blast-results.pl` – parse BLAST of primers vs non-target STs and keep “good” primers.

You normally do not need to call the Perl scripts directly as they are used by the shell pipelines.

---

## Requirements

- [`GenomeTester4`](https://github.com/bioinfo-ut/GenomeTester4)
- [`fastp`](https://github.com/OpenGene/fastp)
- [`SPAdes`](https://github.com/ablab/spades)
- [`mlst`](https://github.com/tseemann/mlst) with *L. monocytogenes* scheme
- [`primer3_core`](https://github.com/primer3-org/primer3)
- [`NCBI BLAST+`](https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/)
- [`BioPerl`](https://github.com/bioperl/bioperl-live)

Optional:
- [`MultiPLX`](https://bioinfo.ut.ee/download/)

Some inputs (k-mer sets, intersect logs, coverage statistics, BLAST databases for each ST) are produced by upstream GenomeTester4-based steps that are **not** in this `code/` directory. Those files must be prepared beforehand as described in the Methods section of the manuscript.

---

## Usage

### 1. Assembly and MLST typing

```bash
bash run-assembly-and-MLST.sh sample_PE_1.fastq sample_PE_2.fastq OUTPUT_DIR
```

**Does:**

1. Trims adapters and low-quality bases with `fastp`
2. Assembles the genome with SPAdes (`--isolate`)
3. Runs `mlst` on the resulting `contigs.fasta`

**Inputs**

- `sample_1.fastq`, `sample_2.fastq` – raw paired-end reads
- `OUTPUT_DIR` – directory to create; will contain cleaned reads, SPAdes output and MLST result

**Outputs (in `OUTPUT_DIR`)**

- `*.clean.fq` – trimmed reads
- `contigs.fasta` – assembled genome
- `*.mlst.txt` – MLST call for this sample

You can post-filter assemblies using `filter-assembly.pl`:

```bash
perl filter-assembly.pl sample_1.fastq sample_2.fastq OUTPUT_DIR/contigs.fasta
# prints: sample_id  N50  longest_contig  avg_depth
```

---

### 2. Finding unique k-mers for a given sequence type

At first create a full list of k-mers for each sample (reads):

```bash
glistmaker sample_1.fastq sample_2.fastq --wordlength 32 -o sample
```

For non-target samples, create a common list of k-mers (union of all k-mers):

```bash
glistcompare nontarget_1.list nontarget_2.list --union --cutoff 5 -o nontargets
```

For target samples, create an intersection list of k-mers (only shared k-mers):

```bash
glistcompare target_1.list target_2.list --intersection --cutoff 5 -o targets
```

Then generate a complement (k-mers in the first file and NOT in second file) of words in both lists:

```bash
glistcompare targets_32_intrsec.list nontargets_32_union.list --difference --cutoff 5 -o ST<ST>_kmers
```
Where `ST` is the MLST sequence type number (e.g. `5`, `121`, `451`).

Finally, generate a list of all unique k-mers with their frequencies:

```bash
glistquery ST<ST>_kmers_32_0_diff1.list > ST<ST>_kmers.txt
```

---

### 3. Primer design for a given sequence type

```bash
bash run-primer-design.sh ST
```
Where `ST` is the MLST sequence type number (e.g. `5`, `121`, `451`)-

**Expects in the current working directory**

- `data/ST<ST>_kmers.txt` – list of ST-specific k-mers (one per line)
- `data/ST<ST>_intersect_log.txt` – list of sample names used for the ST
- `contig_statistics.txt` – per-contig coverage/length stats used by `get-best-contig-for-ST.pl`
- All helper Perl scripts and `primer3_core` available in `PATH`

**Does:**

1. Selects the “best” contig for the given ST using `get-best-contig-for-ST.pl`
2. Converts the k-mer list to FASTA (`make-fasta-from-list.pl`)
3. Builds a BLAST database from the contig and runs `blastn` with 100% identity / 100% coverage
4. Cleans BLAST output (`fix-columns.pl`), merges nearby hits into regions (`extract-genomic-regions.pl`)
5. Calls `run-primer3.pl` to design primers (60–1000 bp amplicons, 18–22 nt primers)

**Outputs (in `ST<ST>_primers/`)**

Typical files include:

- `contigs.fasta` – selected contig for this ST
- `ST<ST>_kmers.fasta` – k-mers used as queries
- `ST<ST>_regions.fasta` – candidate genomic regions
- `ST<ST>_primers.txt` – primer list (used by downstream scripts)

---

### 4. Cross-reactivity check of primers

```bash
bash run-blast.sh ST
```

**Does:**

1. Converts `ST<ST>_primers/ST<ST>_primers.txt` to FASTA (`get-primers-fasta.pl`)
2. For a hard-coded list of other STs (5, 7, 8, 9, 29, 37, 87, 101, 121, 155, 173, 177, 425, 451, 551, 580, 1247):
   - runs `blastn` of primers vs each non-target ST database
   - parses the results (`parse_blast.pl`)
   - filters to retain primers that meet the specificity criteria (`filter-blast-results.pl`)

**Expects in the current working directory**

- `ST<ST>_primers/ST<ST>_primers.txt` from `run-primer-design.sh`
- BLAST databases for each non-target ST named consistently with the BLAST commands in the script
- Helper Perl scripts

**Outputs (in `ST<ST>_primers/`)**

For each non-target ST2:

- `ST<ST>_vs_ST<ST2>.blastn` and `.parsed.txt`
- `ST<ST>_vs_ST<ST2>_good_primers.txt` – primers that passed filters against that ST

Final primer sets for the paper were obtained by combining “good” primers across all non-target STs and then selecting panels manually or with [MultiPLX](https://bioinfo.ut.ee/download/).

---

## Citation

If you use these scripts or the overall workflow, please cite:

**Andreson R., Brauer A., Kaplinski L., Külaots M., Saumaa S., Kurg A., Remm M.**
K-mer based method for finding sequence type specific PCR primers for *Listeria monocytogenes*.

If you use GenomeTester4 package software, please cite:

**Kaplinski L, Lepamets M, Remm M. (2015).**
GenomeTester4: a toolkit for performing basic set operations – union, intersection and complement on k-mer lists.
GigaScience, 4:58 [https://doi.org/10.1186/s13742-015-0097-y]

---

## Contact

For questions or contributions, please open an issue in GitHub or contact the developers reidar.andreson@ut.ee.
