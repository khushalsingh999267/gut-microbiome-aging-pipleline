# Gut-microbiome‑PRJNA931847

A reproducible, beginner‑friendly Snakemake workflow to download and preprocess raw metagenomic reads for BioProject **PRJNA931847** (gut‑microbiome shotgun data). This repository documents:

* Environment setup (Conda)
* Fetching SRA run accessions
* Downloading and converting `.sra` files to paired FASTQ (≤1 GB RAM)
* Project structure and usage instructions

---

## 📁 Repository Structure

```
gut-microbiome-prjna931847/
├── environment.yml         # Conda environment specification
├── config.yaml             # Project parameters for Snakemake
├── Snakefile               # Snakemake download & conversion workflow
├── metadata/
│   └── srr_ids.txt         # List of SRR IDs for PRJNA931847
├── data/
│   └── raw/                # Output: paired FASTQ files
├── scripts/
│   └── get_srrs.sh         # Bash script to fetch SRR run list
└── README.md               # This documentation
```

## 🔧 Prerequisites

* **Git** (for version control)
* **Miniconda** or **Anaconda** (for environment management)
* Internet connection to fetch data from NCBI

## ⚙️ Setup

1. **Clone this repository**

   ```bash
   git clone https://github.com/khushalsingh999267/gut-microbiome-prjna931847.git
   cd gut-microbiome-prjna931847
   ```

2. **Create and activate the Conda environment**

   ```bash
   conda env create -f environment.yml
   conda activate gut-microbiome
   ```

3. **Install Snakemake (if not included)**
   Snakemake is declared in `environment.yml`; activation should provide the `snakemake` command.

## 🗂️ Fetching SRR Accessions

Generate the list of SRR run IDs for BioProject **PRJNA931847**:

```bash
bash scripts/get_srrs.sh
```

* Populates `metadata/srr_ids.txt` (43 runs)
* Easy to re-run if new samples are added

## 🚀 Running the Download & Conversion Workflow

This step downloads each `.sra` file, splits into paired FASTQ, and compresses them—all within a 1 GB RAM budget.

```bash
snakemake --use-conda -j 2 --resources mem_mb=1000
```

* `-j 2`: at most two concurrent jobs
* `--resources mem_mb=1000`: caps each rule’s RAM usage

**Output:** `data/raw/SRRxxxxx_1.fastq.gz` and `SRRxxxxx_2.fastq.gz` for each run.

## 📈 Next Steps

1. **Quality Control & Host‑read Removal** (`fastp` + `kneaddata`)
2. **Taxonomic Profiling** (MetaPhlAn)
3. **Functional Profiling** (HUMAnN)
4. **Statistical Analysis & Visualization** (R scripts)
5. **Interactive Dashboard** (Streamlit)

We will extend this pipeline step‑by‑step while maintaining reproducibility and low‑resource requirements.

## 📬 Contributions & Contact

Feel free to open issues or pull requests. For questions, contact:

> Khushal Singh (github.com/ksingh999267)

---

*Version*: 0.1.0 | *Date*: 2025‑05‑20
