# deaconizer

Minimal nf-core-style Nextflow pipeline for paired-end reads:

1. `fastp` read cleaning
2. `deacon index build` once per reference FASTA
3. `deacon filter` per sample
4. `kraken2` on Deacon-filtered reads
5. `multiqc` report aggregation

## Input

CSV with exactly these columns:

```csv
sample_id,reads_r1,reads_r2
sample_a,/path/sample_a_R1.fastq.gz,/path/sample_a_R2.fastq.gz
```

Use only letters, numbers, dots, underscores, and hyphens in `sample_id`.

## Run

Docker:

```bash
nextflow run . \
  -profile docker \
  --input samples.csv \
  --ref reference.fasta \
  --db /path/to/kraken2db \
  --outdir results
```

Singularity or Apptainer on HPC:

```bash
nextflow run . \
  -profile singularity,slurm \
  --input samples.csv \
  --ref reference.fasta \
  --db /path/to/kraken2db \
  --outdir results
```

Kubernetes with a shared ReadWriteMany PVC:

```bash
nextflow run . \
  -profile docker,k8s \
  -w /workspace/work \
  --k8s_storage_claim_name my-rwm-pvc \
  --k8s_storage_mount_path /workspace \
  --input /workspace/data/samples.csv \
  --ref /workspace/data/reference.fasta \
  --db /workspace/data/kraken2db \
  --outdir /workspace/results
```

For Kubernetes, the samplesheet, reads, reference, database, work directory, and output directory must be visible inside the mounted PVC path unless your site provides another storage layer.

## Outputs

```text
{outdir}/reads/fastp/      fastp cleaned reads
{outdir}/reads/deacon/     Deacon-filtered reads
{outdir}/report/fastp/     fastp HTML and JSON reports
{outdir}/report/deacon/    Deacon JSON summaries
{outdir}/report/kraken2/   Kraken2 TSV reports and classification output
{outdir}/report/           MultiQC report and data directory
{outdir}/pipeline_info/    Nextflow execution reports
```

## Key parameters

Deacon index defaults are `--deacon_kmer_length 31`, `--deacon_window_size 15`, and `--deacon_entropy_threshold 0.0`.

Deacon filter defaults are `--deacon_abs_threshold 1`, `--deacon_rel_threshold 0.0`, `--deacon_prefix_length 0`, and `--deacon_deplete true`.

Pass additional tool arguments with `--fastp_args`, `--deacon_index_args`, `--deacon_filter_args`, `--kraken2_args`, and `--multiqc_args`.

## Stub test

This checks Nextflow syntax and channel wiring without running the real tools:

```bash
nextflow run . -profile test,docker -stub-run
```
