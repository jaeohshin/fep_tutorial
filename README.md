# Free Energy Perturbation (FEP) Tutorial

Relative Binding Free Energy (RBFE) calculation for Tyk2 kinase inhibitors using GROMACS and pmx.

## Overview

This tutorial demonstrates how to calculate the relative binding free energy difference (ΔΔG) between two ligands binding to Tyk2 kinase using the Free Energy Perturbation (FEP) method.

**Target**: Tyk2 (Tyrosine kinase 2)  
**Ligands**: 0X5 (PDB: 4GIH) → 0X6 (PDB: 4GII)  
**Result**: ΔΔG = -5.99 ± 1.39 kJ/mol (-1.43 ± 0.33 kcal/mol)

## Background

### What is FEP?

FEP calculates the free energy difference between two states by gradually "morphing" one ligand into another during molecular dynamics simulation. Instead of calculating absolute binding energies (which is computationally expensive), we calculate the **relative** difference using a thermodynamic cycle:

```
ΔΔG_bind = ΔG_protein - ΔG_water
```

Where:
- ΔG_protein: Free energy change of A→B transformation in protein
- ΔG_water: Free energy change of A→B transformation in water

### Lambda (λ) Windows

The transformation is performed gradually using λ parameter:
- λ = 0: Ligand A (0X5)
- λ = 1: Ligand B (0X6)

We simulate at multiple λ values (0.0, 0.1, 0.2, ... 1.0) and integrate the energy changes.

## Requirements

### Software
- GROMACS 2024+ (with CUDA for GPU acceleration)
- pmx (for hybrid topology generation)
- acpype (for ligand parameterization)
- Open Babel (for hydrogen addition)

### Installation

```bash
# Create conda environment
conda create -n fep python=3.10 -y
conda activate fep

# Install packages
pip install pmx-biobb
pip install scipy==1.12.0  # Required for pmx compatibility
conda install -c conda-forge acpype openbabel gromacs -y
```

## Workflow

### Step 1: Structure Preparation

Download and prepare protein and ligand structures from PDB:

```bash
mkdir -p structures && cd structures

# Download Tyk2 structures
wget https://files.rcsb.org/download/4GIH.pdb  # Ligand 0X5
wget https://files.rcsb.org/download/4GII.pdb  # Ligand 0X6

# Extract protein and ligands
grep "^ATOM" 4GIH.pdb > protein_tyk2.pdb
grep "0X5" 4GIH.pdb > ligand_0X5.pdb
grep "0X6" 4GII.pdb > ligand_0X6.pdb

# Add hydrogens (required for parameterization)
obabel ligand_0X5.pdb -O ligand_0X5_h.pdb -h
obabel ligand_0X6.pdb -O ligand_0X6_h.pdb -h
```

### Step 2: Ligand Parameterization

Generate force field parameters for ligands using GAFF:

```bash
# Generate topology files with AM1-BCC charges
acpype -i ligand_0X5_h.pdb -c bcc -n 0
acpype -i ligand_0X6_h.pdb -c bcc -n 0
```

**Output**: `ligand_*_GMX.gro` (coordinates) and `ligand_*_GMX.itp` (topology)

### Step 3: Hybrid Topology Generation

Create hybrid topology that can morph between ligand A and B:

```bash
mkdir -p hybrid && cd hybrid

# Copy ligand files
cp ../ligand_0X5_h.acpype/ligand_0X5_h_GMX.gro ligandA.gro
cp ../ligand_0X5_h.acpype/ligand_0X5_h_GMX.itp ligandA.itp
cp ../ligand_0X6_h.acpype/ligand_0X6_h_GMX.gro ligandB.gro
cp ../ligand_0X6_h.acpype/ligand_0X6_h_GMX.itp ligandB.itp

# Atom mapping
pmx atomMapping -i1 ligandA.gro -i2 ligandB.gro \
    -o1 pairs1.dat -o2 pairs2.dat \
    -opdb1 alignedA.pdb -opdb2 alignedB.pdb

# Generate hybrid topology
pmx ligandHybrid -i1 alignedA.pdb -i2 alignedB.pdb \
    -itp1 ligandA.itp -itp2 ligandB.itp \
    -pairs pairs1.dat \
    -oA hybridA.pdb -oB hybridB.pdb -oitp hybrid.itp
```

**Output**: `hybrid.itp` (contains A and B state parameters), `ffmerged.itp` (dummy atom types)

### Step 4: System Setup

Build the simulation system with protein, ligand, water, and ions:

```bash
mkdir -p system && cd system

# Copy necessary files
cp ../protein_tyk2.pdb .
cp ../hybrid/hybridA.pdb .
cp ../hybrid/hybrid.itp .
cp ../hybrid/ffmerged.itp .

# Generate protein topology
gmx pdb2gmx -f protein_tyk2.pdb -o protein.gro -p topol.top \
    -ff amber99sb-ildn -water tip3p -ignh

# Combine protein and ligand coordinates
# (manual step - see detailed instructions)

# Create atomtypes.itp from ligand topologies
# (extract GAFF atom types from acpype output)

# Edit topol.top to include:
# - ffmerged.itp
# - atomtypes.itp  
# - hybrid.itp

# Add simulation box
gmx editconf -f complex.gro -o boxed.gro -c -d 1.2 -bt cubic

# Add water
gmx solvate -cp boxed.gro -cs spc216.gro -o solvated.gro -p topol.top

# Add ions (neutralize + 0.15M concentration)
gmx grompp -f ions.mdp -c solvated.gro -p topol.top -o ions.tpr -maxwarn 5
gmx genion -s ions.tpr -o ionized.gro -p topol.top -pname NA -nname CL -neutral -conc 0.15
```

### Step 5: Equilibration

Minimize energy and equilibrate the system:

```bash
# Energy minimization
gmx grompp -f em.mdp -c ionized.gro -p topol.top -o em.tpr
gmx mdrun -v -deffnm em

# NVT equilibration (100 ps)
gmx grompp -f nvt.mdp -c em.gro -r em.gro -p topol.top -o nvt.tpr
gmx mdrun -v -deffnm nvt

# NPT equilibration (100 ps)
gmx grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p topol.top -o npt.tpr
gmx mdrun -v -deffnm npt
```

### Step 6: FEP Production

Run FEP simulations at each λ window:

```bash
mkdir -p lambda && cd lambda

# Generate MDP files for each lambda (see mdp/fep_template.mdp)
# Key parameters:
#   free_energy = yes
#   init_lambda_state = 0-10
#   fep_lambdas = 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0

# Generate TPR files
for i in 0 1 2 3 4 5 6 7 8 9 10; do
    gmx grompp -f fep_$i.mdp -c ../npt.gro -t ../npt.cpt \
        -p ../topol.top -o fep_$i.tpr -maxwarn 5
done

# Run simulations (with GPU acceleration)
for i in 0 1 2 3 4 5 6 7 8 9 10; do
    gmx mdrun -deffnm fep_$i -nb gpu -pme gpu
done
```

### Step 7: Analysis

Calculate ΔG using Bennett Acceptance Ratio (BAR):

```bash
gmx bar -f fep_*.xvg -o bar.xvg -oi barint.xvg
```

## Results

### Final ΔG

| Unit | Value |
|------|-------|
| kT | -2.40 ± 0.56 |
| kJ/mol | -5.99 ± 1.39 |
| kcal/mol | -1.43 ± 0.33 |

**Interpretation**: Ligand 0X6 binds ~1.4 kcal/mol stronger to Tyk2 than ligand 0X5.

### Free Energy Profile

The free energy integral shows the transformation pathway:

```
λ     ΔG (kT)
0     0.00
1     0.40
2    -10.29
3    -21.19
4    -27.99
5    -30.12  ← minimum
6    -27.51
7    -20.32
8    -9.85
9     0.09
10   -2.40   ← final ΔΔG
```

Note: Only the endpoint difference (λ=0 → λ=10) has physical meaning. The intermediate pathway is a mathematical construct.

## MDP Parameters

### FEP-specific settings

```mdp
; Free energy parameters
free_energy = yes
init_lambda_state = 0           ; 0-10 for each window
fep_lambdas = 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0
calc-lambda-neighbors = -1      ; Calculate all neighbors

; Softcore parameters (prevent singularities)
sc-alpha = 0.5
sc-power = 1
sc-sigma = 0.3
sc-coul = yes

; Output frequency for dH/dl
nstdhdl = 100
```

## Performance

| Hardware | Time per λ window (10 ns) | Total time (11 windows) |
|----------|---------------------------|-------------------------|
| RTX 4090 | ~50 min | ~9 hours |
| CPU only (16 cores) | ~4 hours | ~44 hours |

## Directory Structure

```
fep-tutorial/
├── README.md
├── structures/
│   ├── 4GIH.pdb
│   ├── 4GII.pdb
│   ├── protein_tyk2.pdb
│   ├── ligand_0X5.pdb
│   └── ligand_0X6.pdb
├── ligand_param/
│   ├── ligand_0X5_h.acpype/
│   └── ligand_0X6_h.acpype/
├── hybrid/
│   ├── hybrid.itp
│   ├── ffmerged.itp
│   └── pairs1.dat
├── system/
│   ├── topol.top
│   ├── complex.gro
│   └── ionized.gro
├── mdp/
│   ├── em.mdp
│   ├── nvt.mdp
│   ├── npt.mdp
│   └── fep_template.mdp
├── lambda/
│   ├── fep_0.xvg
│   ├── ...
│   └── fep_10.xvg
└── results/
    ├── bar.xvg
    └── barint.xvg
```

## Troubleshooting

### Common Issues

1. **pmx import error (scipy.integrate.simps)**
   ```bash
   pip install scipy==1.12.0
   ```

2. **Atom type not found error**
   - Create `atomtypes.itp` from acpype output
   - Include it in `topol.top` after `ffmerged.itp`

3. **GPU not detected**
   - Use CPU version: remove `-nb gpu -pme gpu` flags
   - Check GROMACS was compiled with CUDA: `gmx --version | grep GPU`

## References

1. Bennett, C. H. (1976). Efficient estimation of free energy differences from Monte Carlo data. *Journal of Computational Physics*, 22(2), 245-268.

2. Gapsys, V., et al. (2015). pmx: Automated protein structure and topology generation for alchemical perturbations. *Journal of Computational Chemistry*, 36(5), 348-354.

3. Wang, L., et al. (2015). Accurate and reliable prediction of relative ligand binding potency in prospective drug discovery by way of a modern free-energy calculation protocol and force field. *Journal of the American Chemical Society*, 137(7), 2695-2703.

## License

MIT License

## Author

Jaeoh Shin  
Korea Institute for Advanced Study (KIAS)

---

*Created: December 2025*
# fep_tutorial
