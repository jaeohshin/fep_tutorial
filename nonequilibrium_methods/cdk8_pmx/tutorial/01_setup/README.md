# 01 - Setup

Initial setup for pmx nonequilibrium FEP calculations.

## Prerequisites

### Conda/Mamba Installation

If you don't have conda/mamba:
```bash
# Install miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh

# Install mamba (faster than conda)
conda install mamba -n base -c conda-forge
```

## Step 1: Create Conda Environment
```bash
# Create environment with GROMACS 2024.5 and pmx
conda create -n fep python=3.10
conda activate fep
conda install -c conda-forge gromacs=2024.5
pip install pmx_biophysics

# Verify installations
gmx --version
pmx --version
python -c "import pmx; print(pmx.__version__)"
```

**Expected output:**
- GROMACS: 2024.5
- pmx: 4.1.3 or newer

## Step 2: Clone Merck Dataset Repository

This repository contains pre-prepared structures and topologies for 8 protein-ligand systems.
```bash
# Create working directory
mkdir -p ~/fep_tutorial/nonequilibrium_methods
cd ~/fep_tutorial/nonequilibrium_methods

# Clone dataset
git clone https://github.com/deGrootLab/rel_ddG_MerckDataSet_JCIM.git

# Verify
ls rel_ddG_MerckDataSet_JCIM/
```

**Expected output:**
```
cdk8  cmet  ddg_data  eg5  hif2a  mdp  pfkfb3  shp2  syk  tnks2
```

## Step 3: Understand Repository Structure

### Main Directories
```
rel_ddG_MerckDataSet_JCIM/
├── cdk8/                          # Our target system
│   ├── ligands_gaff2/             # Ligand topologies (GAFF2)
│   │   ├── lig_13/
│   │   ├── lig_14/                # Ligand 14 (state B)
│   │   ├── lig_16/                # Ligand 16 (state A)
│   │   └── ...
│   ├── ligands_cgenff/            # Alternative: CGenFF
│   ├── ligands_openff/            # Alternative: OpenFF
│   ├── protein_amber/             # Protein topology (AMBER)
│   │   ├── prot.pdb
│   │   ├── prot.itp
│   │   └── topol.top
│   ├── protein_charmm/            # Alternative: CHARMM
│   ├── transformations_gaff2/    # Hybrid topologies
│   │   ├── edge_16_14/           # Our edge!
│   │   │   ├── mergedA.pdb       # Hybrid structure (state A)
│   │   │   ├── mergedB.pdb       # Hybrid structure (state B)
│   │   │   ├── merged.itp        # Hybrid topology
│   │   │   ├── ffmerged.itp      # Dummy atom types
│   │   │   └── pairs.dat         # Atom mapping
│   │   └── edge_*/
│   └── ...
├── ddg_data/                      # Experimental values
│   └── cdk8.dat
└── mdp/                          # Simulation parameters
    ├── em_l0.mdp                 # EM state A
    ├── em_l1.mdp                 # EM state B
    ├── eq_nvt_l0.mdp             # NVT state A
    ├── eq_nvt_l1.mdp             # NVT state B
    ├── eq_l0.mdp                 # Equilibration state A (6 ns)
    ├── eq_l1.mdp                 # Equilibration state B (6 ns)
    ├── ti_l0.mdp                 # Transition A→B (50 ps)
    └── ti_l1.mdp                 # Transition B→A (50 ps)
```

### Key Files for edge_16_14

**Hybrid Topologies (already created by pmx):**
- `mergedA.pdb` / `mergedB.pdb`: Starting structures for states A/B
- `merged.itp`: Contains both ligand topologies with lambda parameters
- `ffmerged.itp`: Dummy atom types (zero Lennard-Jones parameters)
- `pairs.dat`: Atom mapping between ligand 16 and 14

**Example pairs.dat:**
```
1    1     # Atom 1 in lig_16 maps to atom 1 in lig_14
13   13    # Atom 13 maps to 13
29   25    # Atom 29 in lig_16 maps to 25 in lig_14 (deletion)
```

## Step 4: Inspect Experimental Data
```bash
# View experimental ΔΔG values
head -15 rel_ddG_MerckDataSet_JCIM/ddg_data/cdk8.dat
```

**Find edge_16_14:**
```
edge_16_14  3.97  3.52  1.33  14.18  2.31  5.18  3.08  ...
```

Columns:
- Column 1: Edge name
- Column 2: **Experimental ΔΔG (kJ/mol)** = 3.97
- Column 3: gaff2 calculated
- Column 4: gaff2 error
- Columns 5+: Other force fields

## Step 5: Create Working Directory
```bash
# Create project directory
mkdir -p ~/fep_tutorial/nonequilibrium_methods/cdk8_fep_test
cd ~/fep_tutorial/nonequilibrium_methods/cdk8_fep_test

# Copy edge of interest
cp -r ../rel_ddG_MerckDataSet_JCIM/cdk8/transformations_gaff2/edge_16_14 .
cp ../rel_ddG_MerckDataSet_JCIM/cdk8/protein_amber/prot.pdb .

# Verify
ls edge_16_14/
```

**Expected:**
```
ffmerged.itp  merged.itp  mergedA.pdb  mergedB.pdb  merged_posre.itp  pairs.dat
```

## Step 6: Understanding Lambda States

The hybrid topology allows simulation at any lambda value (0 to 1):

**Lambda = 0 (State A):**
- Ligand 16 fully interacting
- Ligand 14 atoms are "dummy" (non-interacting)

**Lambda = 1 (State B):**
- Ligand 14 fully interacting
- Ligand 16 atoms are "dummy"

**Lambda = 0.5 (Intermediate):**
- Both ligands partially interacting
- Used during transitions only

### Controlling Lambda

Lambda is set in `.mdp` files:

**For equilibration (end states):**
```
# em_l0.mdp, eq_nvt_l0.mdp, eq_l0.mdp
free-energy = yes
init-lambda = 0          # State A
```

**For transitions:**
```
# ti_l0.mdp (A→B)
free-energy = yes
init-lambda = 0          # Start at A
delta-lambda = 4e-5      # Move toward B
# Over 25000 steps: 25000 × 4e-5 = 1.0 (reach B)
```

## Step 7: Verify pmx Force Field

pmx includes the required force field:
```bash
# Find pmx force fields
python -c "import pmx; import os; print(os.path.join(os.path.dirname(pmx.__file__), 'data/mutff'))"

# List available
ls $(python -c "import pmx; import os; print(os.path.join(os.path.dirname(pmx.__file__), 'data/mutff'))")
```

**Expected:**
```
amber99sb-star-ildn-mut.ff
amber99sb-star-ildn-bsc1-mut.ff
amber99sb-star-ildn-dna-mut.ff
```

## Step 8: Hardware Check

### GPU Check
```bash
# Check NVIDIA GPU
nvidia-smi

# Test GROMACS GPU support
gmx -version | grep -i gpu
```

**Expected:** GPU support: CUDA

### CPU Info
```bash
# Check CPU cores
nproc
```

**Recommended:** 16+ cores for efficient CPU-based calculations

## Quick Validation

Run these commands to ensure everything is ready:
```bash
cd ~/fep_tutorial/nonequilibrium_methods/cdk8_fep_test

# 1. Check files exist
test -f prot.pdb && echo "✓ Protein structure"
test -f edge_16_14/mergedA.pdb && echo "✓ Hybrid ligand A"
test -f edge_16_14/merged.itp && echo "✓ Hybrid topology"

# 2. Check GROMACS
gmx -version &> /dev/null && echo "✓ GROMACS installed"

# 3. Check pmx
python -c "import pmx" 2>/dev/null && echo "✓ pmx installed"

# 4. Check GPU (optional but recommended)
nvidia-smi &> /dev/null && echo "✓ GPU available" || echo "⚠ No GPU (will use CPU)"
```

**All checks should pass!**

## File Size Expectations

Approximate disk space needed:

| Component | Size |
|-----------|------|
| Input files | ~10 MB |
| Complex equilibration | ~5 GB |
| Complex transitions | ~10 GB |
| Water equilibration | ~500 MB |
| Water transitions | ~1 GB |
| **Total per edge** | **~30 GB** |

Make sure you have sufficient disk space!

## Summary

At this point you should have:
- ✅ Conda environment with GROMACS 2024.5 and pmx
- ✅ Cloned Merck dataset repository
- ✅ Working directory with edge_16_14 files
- ✅ Understanding of hybrid topology concept
- ✅ Hardware verified (GPU recommended)

## Troubleshooting

**Problem: conda install gromacs fails**
```bash
# Try specific version
conda install -c conda-forge gromacs=2024.5

# Or use mamba (faster)
mamba install -c conda-forge gromacs=2024.5
```

**Problem: pmx import error**
```bash
# Reinstall
pip uninstall pmx_biophysics
pip install pmx_biophysics
```

**Problem: Force field not found**
```bash
# Copy manually to working directory (done in complex leg tutorial)
cp -r $CONDA_PREFIX/lib/python3.10/site-packages/pmx/data/mutff/amber99sb-star-ildn-mut.ff .
```

## Next Steps

Proceed to [02_complex_leg](../02_complex_leg/README.md) to start the actual FEP calculations!

---

**Checkpoint:** Setup complete ✅
