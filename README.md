# Gut Microbiome Preprocessing Pipeline (PRJNA931847)

**Author:** Khushal Singh ([github.com/ksingh999267](https://github.com/ksingh999267))
**Version:** 0.1.0 (2025-06-16)

---

## 📖 Table of Contents

1. [Project Overview](#project-overview)
2. [Repository Structure](#repository-structure)
3. [Prerequisites](#prerequisites)
4. [Installation](#installation)
5. [Data Acquisition](#data-acquisition)
6. [Workflow Overview](#workflow-overview)
7. [Rule Descriptions](#rule-descriptions)

   * [rule all](#rule-all)
   * [rule prefetch](#rule-prefetch)
   * [rule fasterq\_dump](#rule-fasterq_dump)
   * [rule compress](#rule-compress)
8. [How to Run](#how-to-run)
9. [Next Steps](#next-steps)

---

## 🧐 Project Overview

This Snakemake workflow automates the download and preprocessing of raw metagenomic reads for the gut microbiome BioProject **PRJNA931847**. It is optimized to run on low-resource machines (≤4 GB RAM, 4 threads) and produces compressed paired-end FASTQ files ready for QC and downstream analysis.

---

## 📂 Repository Structure

```
gut-microbiome-prjna931847/
├── README.md                  # Project documentation
├── environment.yml            # Conda environment specification
├── config.yaml                # Pipeline parameters (paths, resources)
├── Snakefile                  # Snakemake workflow definitions
├── scripts/
│   └── get_srrs.sh            # Bash script to fetch SRR IDs
├── metadata/
│   └── srr_ids.txt            # List of SRR (or ERR) accessions
├── data/
│   ├── sra/                   # Downloaded .sra archives (not in repo)
│   ├── fq/                    # Intermediate FASTQ files (not in repo)
│   └── raw/                   # Final compressed FASTQ files (not in repo)
└── .gitignore                 # Exclude data folders from Git
```

---

## ⚙️ Prerequisites

* **Git** (version control)
* **Miniconda** or **Anaconda** (environment management)
* **Internet connection** (to fetch SRA data)

---

## 🔧 Installation

1. **Clone the repository** (no large data pulled):

   ```bash
   git clone https://github.com/ksingh999267/gut-microbiome-aging-pipleline.git
   cd gut-microbiome-prjna931847
   ```

2. **Create and activate the Conda environment**:

   ```bash
   conda env create -f environment.yml
   conda activate gut-microbiome
   ```

---

## 📥 Data Acquisition

1. **Generate SRR list**:

   ```bash
   bash scripts/get_srrs.sh
   ```

   * Fetches run accessions for BioProject `PRJNA931847`
   * Populates `metadata/srr_ids.txt`

2. **Data folders** (ignored by Git via `.gitignore`):

   ```
   /data/sra
   /data/fq
   /data/raw
   ```

---

## 🗂 Workflow Overview

The pipeline comprises four main rules:

1. **prefetch**: download `.sra` archives
2. **fasterq\_dump**: convert `.sra` to paired FASTQ
3. **compress**: gzip FASTQ into `data/raw`
4. **all**: aggregate final targets

```text
metadata/srr_ids.txt
        ↓
prefetch → data/sra/{SRR}.sra
        ↓
fasterq_dump → data/fq/{SRR}_1.fastq + {SRR}_2.fastq
        ↓
compress → data/raw/{SRR}_1.fastq.gz + {SRR}_2.fastq.gz
```

---

## 📝 Rule Descriptions

### rule all

Specifies the final files that the workflow should produce. Snakemake uses this as the default target when you run `snakemake` without arguments.

```python
rule all:
    input:
        expand(f"{RAW_DIR}/{{srr}}_1.fastq.gz", srr=SAMPLES),
        expand(f"{RAW_DIR}/{{srr}}_2.fastq.gz", srr=SAMPLES)
```

* **expand(...)** generates one filepath per SRR in `SAMPLES`.
* Ensures both mate-pair files (`_1` and `_2`) exist for every sample.

---

### rule prefetch

Downloads SRA archives using the NCBI `prefetch` tool.

```python
rule prefetch:
    output:
        temp("data/sra/{srr}.sra")
    shell:
        "prefetch {wildcards.srr} -O data/sra"
```

* **wildcards.srr**: each SRR accession (e.g., `SRR24007843`).
* **temp()**: marks the `.sra` file as intermediate—Snakemake may remove it after downstream rules complete.

---

### rule fasterq\_dump

Converts `.sra` files into raw FASTQ files.

```python
rule fasterq_dump:
    input:
        "data/sra/{srr}.sra"
    output:
        temp("data/fq/{srr}_1.fastq"),
        temp("data/fq/{srr}_2.fastq")
    threads: THREADS
    resources:
        mem_mb=MEM_MB
    shell:
        "fasterq-dump --split-files --threads {threads} {input} -O data/fq"
```

* **--split-files**: produces two files for paired-end reads.
* **threads** & **mem\_mb**: keep within resource caps defined in `config.yaml`.

---

### rule compress

Gzips the FASTQ files and moves them into the final directory.

```python
rule compress:
    input:
        r1="data/fq/{srr}_1.fastq",
        r2="data/fq/{srr}_2.fastq"
    output:
        r1=f"{RAW_DIR}/{{srr}}_1.fastq.gz",
        r2=f"{RAW_DIR}/{{srr}}_2.fastq.gz"
    shell:
        "pigz -p 2 -1 {input.r1}\n"
        "pigz -p 2 -1 {input.r2}\n"
        "mv {input.r1}.gz {output.r1}\n"
        "mv {input.r2}.gz {output.r2}"
```

* **pigz**: parallel gzip for speed, low memory.
* Final files live in `data/raw/` for downstream QC/analysis.

---

## ▶️ How to Run

```bash
# After environment setup & SRR list generation:
snakemake --use-conda -j 4 --resources mem_mb=4000 -p
```

* `-j 4`: up to 4 jobs concurrently
* `--resources mem_mb=4000`: caps per-rule memory at 4 GB

---

## 🔮 Next Steps

* **Quality Control**: integrate `fastp` or `MultiQC`
* **Host Filtering**: add a `kneaddata` rule
* **Profiling**: MetaPhlAn, HUMAnN, Kraken2
* **Visualization**: R Markdown, Streamlit dashboard

---

*End of progress-to-date documentation.*
