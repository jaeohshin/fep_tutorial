# Free Energy Perturbation (FEP) Tutorials

Comprehensive tutorials for calculating relative protein-ligand binding free energies using different FEP approaches.

## Repository Overview

This repository contains tutorials for two main FEP methodologies:

### 1. Equilibrium Methods ([`equilibrium_methods/`](equilibrium_methods/))
Traditional FEP using multiple lambda windows with MBAR/BAR analysis.

- **Tyk2 Tutorial** - Tyrosine kinase 2 inhibitors
  - Method: Lambda windows (0.0, 0.05, 0.1, ..., 1.0)
  - Analysis: MBAR (Multistate Bennett Acceptance Ratio)
  - Time: ~12 hours per edge
  - Location: `equilibrium_methods/tyk2/`

### 2. Nonequilibrium Methods ([`nonequilibrium_methods/`](nonequilibrium_methods/))
Fast-switching FEP using Crooks Fluctuation Theorem.

- **CDK8 Tutorial** - Cyclin-Dependent Kinase 8 inhibitors
  - Method: Nonequilibrium switching (pmx)
  - Analysis: Crooks theorem with maximum likelihood
  - Time: ~6 hours per edge
  - Location: `nonequilibrium_methods/cdk8_pmx/`
  - **Complete tutorial documentation** in `tutorial/` directory

---

## Quick Start

### Equilibrium Method (Tyk2)
```bash
cd equilibrium_methods/tyk2
# Follow instructions in that directory
```

### Nonequilibrium Method (CDK8)
```bash
cd nonequilibrium_methods/cdk8_pmx/tutorial
# Read through:
# - README.md (overview)
# - 01_setup/README.md
# - 02_complex_leg/README.md
# - 03_water_leg/README.md
# - 04_analysis/README.md
```

---

## Method Comparison

| Feature | Equilibrium | Nonequilibrium |
|---------|-------------|----------------|
| **Lambda windows** | Many (10-20) | Only end states (2) |
| **Equilibration** | Short per window | Long at end states |
| **Transitions** | N/A | Many short switches |
| **Analysis** | MBAR/BAR | Crooks theorem |
| **Parallelization** | Moderate | Excellent |
| **Time per edge** | ~12 hours | ~6 hours |
| **Accuracy** | High | High |
| **Best for** | Careful studies | High-throughput |

---

## Results Summary

### Tyk2 (Equilibrium Method)
- Transformation: 0X5 → 0X6
- Result: ΔΔG = -5.99 ± 1.39 kJ/mol
- Experimental: Unknown
- Method: Traditional lambda windows + MBAR

### CDK8 (Nonequilibrium Method)
- Transformation: Ligand 16 → Ligand 14
- Result: ΔΔG = +2.85 ± 1.27 kJ/mol
- Experimental: +3.97 kJ/mol
- Error: 1.12 kJ/mol (0.27 kcal/mol) ✓
- Method: pmx nonequilibrium switching

---

## Requirements

### Software
- GROMACS 2024.5+ (or 2023.x)
- Python 3.10+
- pmx 4.1.3+ (for nonequilibrium method)
- pymbar (for equilibrium method)

### Hardware
- GPU recommended (NVIDIA RTX series)
- 16+ CPU cores
- 32+ GB RAM
- ~50 GB disk space per edge

### Installation
```bash
# Create conda environment
conda create -n fep python=3.10
conda activate fep

# Install GROMACS
conda install -c conda-forge gromacs=2024.5

# For equilibrium method
pip install pymbar alchemlyb

# For nonequilibrium method
pip install pmx_biophysics
```

---

## Repository Structure
```
fep_tutorial/
├── README.md (this file)
├── equilibrium_methods/
│   ├── tyk2/                    # Tyk2 kinase tutorial
│   └── t4_lysozyme/             # T4 lysozyme tutorial (if added)
├── nonequilibrium_methods/
│   └── cdk8_pmx/
│       ├── tutorial/            # Complete tutorial documentation
│       │   ├── README.md
│       │   ├── 01_setup/
│       │   ├── 02_complex_leg/
│       │   ├── 03_water_leg/
│       │   └── 04_analysis/
│       ├── edge_16_14/          # Hybrid topologies
│       ├── prot.pdb             # CDK8 structure
│       └── [calculation files]
├── structures/                   # Shared structure files
└── rel_ddG_MerckDataSet_JCIM/   # Merck dataset (git submodule)
```

---

## Tutorials

### Nonequilibrium Method Tutorial (Recommended for beginners)

The **CDK8 pmx tutorial** is complete with step-by-step documentation:

1. **[Setup](nonequilibrium_methods/cdk8_pmx/tutorial/01_setup/README.md)**
   - Environment preparation
   - Clone Merck dataset
   - Understand hybrid topologies

2. **[Complex Leg](nonequilibrium_methods/cdk8_pmx/tutorial/02_complex_leg/README.md)**
   - Protein-ligand complex assembly
   - Equilibration (6 ns)
   - 160 nonequilibrium transitions
   - Calculate ΔΔG_complex

3. **[Water Leg](nonequilibrium_methods/cdk8_pmx/tutorial/03_water_leg/README.md)**
   - Ligand in water setup
   - Equilibration (6 ns)
   - 160 nonequilibrium transitions
   - Calculate ΔΔG_water

4. **[Analysis](nonequilibrium_methods/cdk8_pmx/tutorial/04_analysis/README.md)**
   - Calculate ΔΔG_binding
   - Compare to experiment
   - Interpret results

**Time:** ~6 hours total for one edge

### Equilibrium Method Tutorial

Located in `equilibrium_methods/tyk2/` - traditional approach with lambda windows.

---

## Theory Background

### Thermodynamic Cycle

Both methods use the same underlying thermodynamic cycle:
```
Ligand A (water) ----ΔG_bind(A)----> Ligand A (protein)
      |                                      |
      | ΔΔG_water                            | ΔΔG_complex
      |                                      |
      v                                      v
Ligand B (water) ----ΔG_bind(B)----> Ligand B (protein)
```

**Relative binding free energy:**
```
ΔΔG_binding = ΔΔG_complex - ΔΔG_water
```

### Key Differences

**Equilibrium (MBAR):**
- Simulates many intermediate states (λ = 0.0, 0.05, 0.1, ..., 1.0)
- Uses overlap between neighboring states
- MBAR optimally combines all data

**Nonequilibrium (Crooks):**
- Simulates only end states (λ = 0.0 and 1.0)
- Many rapid "switches" between states
- Crooks Fluctuation Theorem relates work to free energy

---

## References

### Nonequilibrium Method
1. Gapsys, V., et al. (2022). Pre-Exascale Computing of Protein–Ligand Binding Free Energies. *J. Chem. Inf. Model.*, 62, 1172-1177.
2. Gapsys, V., et al. (2020). Large Scale Relative Protein Ligand Binding Affinities Using Non-Equilibrium Alchemy. *Chem. Sci.*, 11, 1140-1152.

### Equilibrium Method
1. Shirts, M. R., & Chodera, J. D. (2008). Statistically optimal analysis of samples from multiple equilibrium states. *J. Chem. Phys.*, 129, 124105.
2. Klimovich, P. V., et al. (2015). Guidelines for the analysis of free energy calculations. *J. Comput. Aided Mol. Des.*, 29, 397-411.

### Datasets
- Merck FEP dataset: https://github.com/deGrootLab/rel_ddG_MerckDataSet_JCIM
- Tyk2 structures: Custom prepared

---

## Contributing

Feel free to:
- Report issues
- Suggest improvements
- Add new tutorials
- Share results

---

## License

MIT License - See individual tutorial directories for specific licensing.

---

## Author

Jaeoh Shin  
Korea Institute for Advanced Study (KIAS)  
Computational Biophysics

---

## Acknowledgments

- Bert de Groot lab (pmx development)
- Merck for the benchmark dataset
- GROMACS development team
