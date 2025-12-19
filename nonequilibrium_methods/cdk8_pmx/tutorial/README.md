# Protein-Ligand Binding Free Energy with pmx Nonequilibrium Approach

Complete tutorial for calculating relative protein-ligand binding free energies using the pmx nonequilibrium switching method.

## Table of Contents
- [Overview](#overview)
- [Theory Background](#theory-background)
- [System Details](#system-details)
- [Requirements](#requirements)
- [Workflow](#workflow)
- [Expected Results](#expected-results)
- [Troubleshooting](#troubleshooting)
- [References](#references)

## Overview

This tutorial demonstrates **nonequilibrium alchemical free energy calculations** for protein-ligand binding using the open-source pmx software and GROMACS.

**Key Features:**
- Method: Nonequilibrium switching with Crooks Fluctuation Theorem
- Complete thermodynamic cycle (complex + water legs)
- Fast: ~6 hours on single GPU for one edge
- Accurate: Within 1 kcal/mol of experiment

**System:**
- Protein: CDK8 kinase
- Ligands: edge_16_14 (ligand 16 ↔ ligand 14)
- Transformation: Chlorine position change (ortho vs meta)
- Experimental ΔΔG: 3.97 kJ/mol

## Theory Background

### Equilibrium vs Nonequilibrium FEP

**Traditional Equilibrium FEP:**
```
λ=0.0 → λ=0.1 → λ=0.2 → ... → λ=1.0
  |       |       |             |
 5ns     5ns     5ns           5ns
```
- Many intermediate λ windows
- Long equilibration at each window
- BAR/MBAR analysis

**Nonequilibrium pmx Approach:**
```
State A (λ=0)          State B (λ=1)
    |                      |
  6 ns equilibration    6 ns equilibration
    |                      |
    └──── 50 ps ──────────> (80× forward, measure work)
    <──── 50 ps ──────────┘ (80× reverse, measure work)
```
- Only end states (λ=0, λ=1)
- Long equilibration (6 ns)
- Many short "switches" (50 ps)
- Crooks Fluctuation Theorem for analysis

### Crooks Fluctuation Theorem

The free energy difference ΔG can be extracted from work distributions:
```
P_forward(W) / P_reverse(-W) = exp[(W - ΔG) / kT]
```

Where:
- W = work done during nonequilibrium transition
- Forward: A→B transitions
- Reverse: B→A transitions
- Maximum likelihood estimator extracts ΔG

### Thermodynamic Cycle
```
Ligand A (water) ----ΔG_bind(A)----> Ligand A (protein)
      |                                      |
      | ΔΔG_water                            | ΔΔG_complex
      |                                      |
      v                                      v
Ligand B (water) ----ΔG_bind(B)----> Ligand B (protein)
```

**Key equation:**
```
ΔΔG_binding = ΔΔG_complex - ΔΔG_water
```

This gives the relative binding free energy: how much better/worse B binds compared to A.

## System Details

**Protein:** CDK8 (Cyclin-Dependent Kinase 8)
- Force field: AMBER99SB*ILDN
- ~6000 atoms

**Ligands:**
- Ligand 16 and Ligand 14 (from Merck dataset)
- Force field: GAFF 2.11
- Transformation: Single Cl position change

**Simulation Box:**
- Complex: ~123,000 atoms (protein + ligand + water + ions)
- Water: ~3,200 atoms (ligand + water + ions)

## Requirements

### Software
- GROMACS 2024.5 or newer
- pmx 4.1.3 or newer
- Python 3.10+

### Hardware
- GPU strongly recommended (NVIDIA RTX series ideal)
- ~16 CPU cores
- ~32 GB RAM
- ~50 GB disk space per edge

### Time Requirements
- Complex leg: ~4 hours (GPU)
- Water leg: ~1.5 hours (GPU/CPU)
- **Total per edge: ~6 hours**

## Workflow

The complete workflow consists of 4 main sections:

### 1. Setup ([01_setup](01_setup/README.md))
- Clone Merck dataset repository
- Setup environment and force fields
- Create hybrid topologies (already provided)

### 2. Complex Leg ([02_complex_leg](02_complex_leg/README.md))
- Assemble protein-ligand complex
- Solvation and ionization
- Energy minimization
- NVT equilibration (100 ps)
- **Equilibration (6 ns, state A and B)**
- Extract 80 frames from each state
- **Transitions (50 ps × 160 total)**
- Analysis → ΔΔG_complex

### 3. Water Leg ([03_water_leg](03_water_leg/README.md))
- Setup ligand in water
- Solvation and ionization
- Energy minimization
- NVT equilibration (100 ps)
- **Equilibration (6 ns, state A and B)**
- Extract 80 frames from each state
- **Transitions (50 ps × 160 total)**
- Analysis → ΔΔG_water

### 4. Final Analysis ([04_analysis/README.md])
- Calculate ΔΔG_binding = ΔΔG_complex - ΔΔG_water
- Compare to experimental value
- Error analysis

## Expected Results

### Our Results

| Calculation | Value (kJ/mol) | Error (kJ/mol) |
|------------|----------------|----------------|
| ΔΔG_complex | -1.96 ± 0.91 | - |
| ΔΔG_water | -4.81 ± 0.89 | - |
| **ΔΔG_binding** | **+2.85** | **-1.12** |
| Experimental | +3.97 | - |

**Absolute error: 1.12 kJ/mol (~0.27 kcal/mol)** ✅

### Literature Comparison

From Gapsys et al. (2022) for edge_16_14:
- GAFF2: 3.52 kJ/mol (error: -0.45)
- CGenFF: 14.18 kJ/mol (error: +10.21)
- Our GAFF2: 2.85 kJ/mol (error: -1.12)

Our result is within expected accuracy range!

## Troubleshooting

### Common Issues

**1. Force field files not found**
```bash
# Copy pmx force fields
cp -r $CONDA_PREFIX/lib/python3.10/site-packages/pmx/data/mutff/amber99sb-star-ildn-mut.ff .
```

**2. "Pressure scaling >1%" warnings**
- Normal during initial equilibration (~500 steps)
- If simulation crashes, use Berendsen barostat instead

**3. Slow GPU performance**
- For water leg (small system), CPU may be faster
- Use: `gmx mdrun -ntmpi 1 -ntomp 16` instead of GPU flags

**4. Missing .xvg files**
- Check `nstdhdl = 1` in ti_l0.mdp and ti_l1.mdp
- Ensure transitions completed successfully

**5. Large BAR errors**
- Check work distribution overlap (should have good overlap)
- May need longer transitions or more snapshots

## References

### Primary Paper
Gapsys, V., Hahn, D. F., Tresadern, G., Mobley, D. L., Rampp, M., & de Groot, B. L. (2022). 
**Pre-Exascale Computing of Protein–Ligand Binding Free Energies with Open Source Software for Drug Design.** 
*Journal of Chemical Information and Modeling*, 62(5), 1172-1177.
https://doi.org/10.1021/acs.jcim.1c01445

### Methodology Papers
1. Gapsys, V., Pérez-Benito, L., Aldeghi, M., et al. (2020). 
   **Large Scale Relative Protein Ligand Binding Affinities Using Non-Equilibrium Alchemy.**
   *Chemical Science*, 11, 1140-1152.
   https://doi.org/10.1039/C9SC03754C

2. Crooks, G. E. (1999). 
   **Entropy production fluctuation theorem and the nonequilibrium work relation for free energy differences.**
   *Physical Review E*, 60(3), 2721.

### Software
- pmx: https://github.com/deGrootLab/pmx
- GROMACS: https://www.gromacs.org
- Dataset: https://github.com/deGrootLab/rel_ddG_MerckDataSet_JCIM

---

**Author:** Jaeoh Shin  
**Date:** December 2025  
**License:** MIT
