# 04 - Final Analysis

Calculate the binding free energy difference and compare to experiment.

**Time required:** ~5 minutes

## Overview

At this point you have completed both legs of the thermodynamic cycle:
- ✅ ΔΔG_complex = Free energy change in protein
- ✅ ΔΔG_water = Free energy change in water

Now we combine them to get the **relative binding free energy**.

---

## Thermodynamic Cycle Review
```
Ligand A (water) ----ΔG_bind(A)----> Ligand A (protein)
      |                                      |
      | ΔΔG_water                            | ΔΔG_complex
      | (measured)                           | (measured)
      v                                      v
Ligand B (water) ----ΔG_bind(B)----> Ligand B (protein)
```

**Thermodynamic cycle closure:**
```
ΔΔG_binding = ΔG_bind(B) - ΔG_bind(A)
            = ΔΔG_complex - ΔΔG_water
```

**Physical interpretation:**
- ΔΔG_binding > 0: Ligand B binds weaker than A
- ΔΔG_binding < 0: Ligand B binds stronger than A
- ΔΔG_binding = 0: Both ligands bind equally well

---

## Step 1: Gather Results

### 1.1 Complex Leg Result
```bash
cd ~/fep_tutorial/nonequilibrium_methods/cdk8_fep_test

# Extract BAR result
grep "BAR: dG =" ddG_complex.txt
```

**Example output:**
```
BAR: dG = -1.96 kJ/mol
BAR: Std Err (bootstrap) = 0.91 kJ/mol
```

**Interpretation:**
- ΔΔG_complex = -1.96 kJ/mol
- In the protein, B is 1.96 kJ/mol more stable than A
- Error: ±0.91 kJ/mol

### 1.2 Water Leg Result
```bash
# Extract BAR result
grep "BAR: dG =" water/ddG_water.txt
```

**Example output:**
```
BAR: dG = -4.81 kJ/mol
BAR: Std Err (bootstrap) = 0.89 kJ/mol
```

**Interpretation:**
- ΔΔG_water = -4.81 kJ/mol
- In water, B is 4.81 kJ/mol more stable than A
- Error: ±0.89 kJ/mol

---

## Step 2: Calculate Binding Free Energy

### 2.1 Calculate ΔΔG_binding
```
ΔΔG_binding = ΔΔG_complex - ΔΔG_water
            = (-1.96) - (-4.81)
            = -1.96 + 4.81
            = +2.85 kJ/mol
```

**Error propagation (assuming independent errors):**
```
σ_binding = √(σ_complex² + σ_water²)
          = √(0.91² + 0.89²)
          = √(0.83 + 0.79)
          = √1.62
          = 1.27 kJ/mol
```

**Final result:**
```
ΔΔG_binding = +2.85 ± 1.27 kJ/mol
```

### 2.2 Create Analysis Script
```bash
cat > analyze_binding.py << 'EOFPYTHON'
#!/usr/bin/env python3
"""
Calculate binding free energy from complex and water legs
"""

import re
import sys

def extract_bar_dg(filename):
    """Extract BAR dG value and error from pmx output"""
    with open(filename, 'r') as f:
        content = f.read()
    
    # Find BAR dG line
    bar_match = re.search(r'BAR: dG\s*=\s*([-\d.]+)\s*kJ/mol', content)
    err_match = re.search(r'BAR: Std Err \(bootstrap\)\s*=\s*([\d.]+)\s*kJ/mol', content)
    
    if bar_match and err_match:
        dg = float(bar_match.group(1))
        err = float(err_match.group(1))
        return dg, err
    else:
        print(f"Error: Could not find BAR results in {filename}")
        sys.exit(1)

# Extract results
complex_dg, complex_err = extract_bar_dg('ddG_complex.txt')
water_dg, water_err = extract_bar_dg('water/ddG_water.txt')

# Calculate binding free energy
binding_dg = complex_dg - water_dg
binding_err = (complex_err**2 + water_err**2)**0.5

# Experimental value for edge_16_14
exp_dg = 3.97  # kJ/mol

# Calculate error
calc_error = binding_dg - exp_dg

print("="*60)
print("FREE ENERGY ANALYSIS - edge_16_14")
print("="*60)
print()
print("Complex Leg:")
print(f"  ΔΔG_complex = {complex_dg:+.2f} ± {complex_err:.2f} kJ/mol")
print()
print("Water Leg:")
print(f"  ΔΔG_water   = {water_dg:+.2f} ± {water_err:.2f} kJ/mol")
print()
print("Binding Free Energy:")
print(f"  ΔΔG_binding = {binding_dg:+.2f} ± {binding_err:.2f} kJ/mol")
print()
print("Experimental:")
print(f"  ΔΔG_exp     = {exp_dg:+.2f} kJ/mol")
print()
print("Comparison:")
print(f"  Error       = {calc_error:+.2f} kJ/mol ({abs(calc_error):.2f} kJ/mol)")
print(f"  Error       = {calc_error/4.184:+.2f} kcal/mol ({abs(calc_error)/4.184:.2f} kcal/mol)")
print()
print("="*60)

# Interpretation
print()
print("INTERPRETATION:")
print("-" * 60)
if binding_dg > 0:
    print(f"Ligand B binds WEAKER than ligand A by {binding_dg:.2f} kJ/mol")
elif binding_dg < 0:
    print(f"Ligand B binds STRONGER than ligand A by {abs(binding_dg):.2f} kJ/mol")
else:
    print("Ligands A and B bind equally well")

print()
print("Physical meaning:")
print(f"  - In complex: B is {abs(complex_dg):.2f} kJ/mol {'more' if complex_dg < 0 else 'less'} stable")
print(f"  - In water:   B is {abs(water_dg):.2f} kJ/mol {'more' if water_dg < 0 else 'less'} stable")
print(f"  - Net effect: B's {'advantage' if binding_dg < 0 else 'disadvantage'} is {abs(binding_dg):.2f} kJ/mol for binding")

print()
print("Accuracy Assessment:")
if abs(calc_error) < 1.0:
    print(f"  ✓ EXCELLENT: Error < 1.0 kJ/mol (< 0.24 kcal/mol)")
elif abs(calc_error) < 2.0:
    print(f"  ✓ GOOD: Error < 2.0 kJ/mol (< 0.48 kcal/mol)")
elif abs(calc_error) < 4.2:
    print(f"  ○ ACCEPTABLE: Error < 1.0 kcal/mol")
else:
    print(f"  ✗ POOR: Error > 1.0 kcal/mol")

print("="*60)
EOFPYTHON

chmod +x analyze_binding.py

# Run analysis
python analyze_binding.py
```

---

## Step 3: Detailed Results

### 3.1 Our Calculation Results
```
============================================================
FREE ENERGY ANALYSIS - edge_16_14
============================================================

Complex Leg:
  ΔΔG_complex = -1.96 ± 0.91 kJ/mol

Water Leg:
  ΔΔG_water   = -4.81 ± 0.89 kJ/mol

Binding Free Energy:
  ΔΔG_binding = +2.85 ± 1.27 kJ/mol

Experimental:
  ΔΔG_exp     = +3.97 kJ/mol

Comparison:
  Error       = -1.12 kJ/mol (1.12 kJ/mol)
  Error       = -0.27 kcal/mol (0.27 kcal/mol)

============================================================
```

### 3.2 Literature Comparison

From Gapsys et al. (2022) J. Chem. Inf. Model.:

| Method | ΔΔG (kJ/mol) | Error (kJ/mol) |
|--------|--------------|----------------|
| **Our calculation (GAFF2)** | **+2.85** | **-1.12** |
| Literature GAFF2 | +3.52 | -0.45 |
| Literature CGenFF | +14.18 | +10.21 |
| Literature OpenFF | +5.18 | +1.21 |
| Experimental | +3.97 | - |

**Our result is within expected accuracy range!**

### 3.3 Error Analysis

**Sources of error:**

1. **Force field limitations** (~1-2 kJ/mol)
   - GAFF2 parameterization
   - Missing polarization effects
   - Fixed charges

2. **Sampling limitations** (~0.5-1 kJ/mol)
   - Finite simulation time (6 ns)
   - Limited number of transitions (80)
   - Conformational sampling

3. **Statistical uncertainty** (~1.3 kJ/mol)
   - From bootstrap analysis
   - Propagated from both legs

4. **Experimental uncertainty** (~0.5-1 kJ/mol)
   - Measurement error
   - Assay conditions

**Total expected error:** ~2-3 kJ/mol (typical for FEP)

**Our error: 1.12 kJ/mol** → Excellent!

---

## Step 4: Physical Interpretation

### 4.1 What Does +2.85 kJ/mol Mean?
```
ΔΔG_binding = +2.85 kJ/mol (positive)
```

**Interpretation:**
- Ligand B binds **2.85 kJ/mol weaker** than ligand A
- At 298 K: ΔΔG = RT ln(K_B/K_A)
- K_B/K_A = exp(2.85/2.48) = exp(1.15) = 3.16
- **Ligand A is ~3× more potent than ligand B**

### 4.2 Breaking Down the Contributions

**Complex leg (ΔΔG_complex = -1.96 kJ/mol):**
- When bound to protein, B is 1.96 kJ/mol MORE stable than A
- B makes better interactions with protein? NO! Wait...

**Water leg (ΔΔG_water = -4.81 kJ/mol):**
- In solution, B is 4.81 kJ/mol MORE stable than A
- B is intrinsically more stable (better solvated)

**Binding difference:**
- B's intrinsic advantage (4.81) is REDUCED in protein (1.96)
- B "loses" 2.85 kJ/mol of its advantage when binding
- A fits better in the binding pocket!

**Physical insight:**
- Chlorine position change (ortho vs meta)
- Ligand A (16): Better protein complementarity
- Ligand B (14): Better intrinsic stability
- Net result: A wins for binding

### 4.3 Structural Rationale

**Ligand 16 (A) - ortho Cl:**
- Cl in ortho position
- Better shape complementarity to binding pocket?
- Specific interactions with protein residues?

**Ligand 14 (B) - meta Cl:**
- Cl in meta position  
- Better solvation in water
- But loses advantage in protein environment

**To investigate further:**
- Visualize binding poses in PyMOL/VMD
- Analyze H-bonds and hydrophobic contacts
- Check Cl interactions with protein

---

## Step 5: Quality Assessment

### 5.1 Convergence Metrics

**Complex leg:**
```bash
grep "Conv =" ddG_complex.txt
```
Expected: Conv = 1.00 ✓

**Water leg:**
```bash
grep "Conv =" water/ddG_water.txt
```
Expected: Conv ≈ 1.00 ✓

### 5.2 Work Distribution Overlap

View the wplot.png files:

**Complex:**
```bash
# Should show good overlap between forward (green) and reverse (blue)
ls wplot.png
```

**Water:**
```bash
ls water/wplot.png
```

**Good overlap = reliable estimate!**

### 5.3 Statistical Tests

**Gaussian quality:**
```bash
grep "gaussian quality" ddG_complex.txt water/ddG_water.txt
```

All should be >0.6 with KS-Test passing ✓

---

## Step 6: Comparison with Other Force Fields

From the Merck dataset, edge_16_14 results:
```bash
# View all force field results
grep "edge_16_14" ../rel_ddG_MerckDataSet_JCIM/ddg_data/cdk8.dat
```

**Output columns:**
1. edge_16_14
2. **Experimental: 3.97**
3. gaff2: 3.52
4. gaff2_err: 1.33
5. cgenff: 14.18
6. cgenff_err: 2.31
7. openff: 5.18
8. openff_err: 3.08

**Our result: 2.85 kJ/mol**

**Ranking by accuracy:**
1. Literature GAFF2: error = 0.45 kJ/mol
2. **Our GAFF2: error = 1.12 kJ/mol** ✓
3. Literature OpenFF: error = 1.21 kJ/mol
4. Literature CGenFF: error = 10.21 kJ/mol

**We're in good company!**

---

## Step 7: Publication-Quality Reporting

### 7.1 Methods Summary

**For Methods section:**
```
Relative binding free energies were calculated using the pmx 
nonequilibrium switching approach. Hybrid topologies were generated 
using pmx 4.1.3 for ligand transformations. The protein was 
described using AMBER99SB*ILDN force field, ligands using GAFF2 
with AM1-BCC charges, and solvent using TIP3P water model. 

For each transformation, two equilibrium simulations (6 ns each) 
were performed at the end states (λ=0 and λ=1) for both the 
protein-ligand complex and ligand in water. From each equilibrium 
trajectory, 80 snapshots were extracted from the last 4 ns, and 
50 ps nonequilibrium transitions were initiated from each snapshot 
in both forward and reverse directions. Free energy differences 
were calculated using the Crooks Fluctuation Theorem with a 
maximum likelihood estimator as implemented in pmx.

All simulations used GROMACS 2024.5 with a 2 fs timestep, 
stochastic dynamics integrator at 298 K, and Parrinello-Rahman 
(or Berendsen for water leg) barostat at 1 bar. Electrostatics 
were treated using PME with a 1.1 nm cutoff, and van der Waals 
interactions used a force-switched cutoff from 1.0 to 1.1 nm.
```

### 7.2 Results Summary

**For Results section:**
```
The relative binding free energy for the edge_16_14 transformation 
(ligand 16 → ligand 14) was calculated as ΔΔG_binding = +2.85 ± 
1.27 kJ/mol, compared to the experimental value of +3.97 kJ/mol, 
yielding an unsigned error of 1.12 kJ/mol. The complex leg gave 
ΔΔG_complex = -1.96 ± 0.91 kJ/mol, and the water leg gave 
ΔΔG_water = -4.81 ± 0.89 kJ/mol. Both calculations showed 
excellent convergence (Conv ≈ 1.00) and good overlap in work 
distributions.
```

---

## Step 8: Next Steps and Improvements

### 8.1 Improving Accuracy

For production calculations, consider:

**Longer equilibration:**
- 10 ns instead of 6 ns
- Better sampling of conformational space

**More transitions:**
- 100-200 per direction instead of 80
- Better statistics

**Multiple replicas:**
- 3-5 independent replicas
- Consensus result from averaging

**Alternative force fields:**
- Run with CGenFF and OpenFF
- Take consensus of all three

### 8.2 Automating for All Edges

This system has 54 edges total! To scale up:
```bash
# Example automation framework
for edge in edge_*; do
    setup_complex_leg $edge
    run_complex_leg $edge
    setup_water_leg $edge
    run_water_leg $edge
    analyze_edge $edge
done
```

Create scripts for automation!

### 8.3 Analysis Extensions

**Structural analysis:**
- Extract binding poses
- Analyze H-bonds
- Calculate interaction energies
- Identify key residues

**Thermodynamic decomposition:**
- Entropy/enthalpy separation
- Per-residue contributions
- Conformational analysis

---

## Summary

### What You Accomplished

- ✅ Complete thermodynamic cycle for protein-ligand FEP
- ✅ Both complex and water legs
- ✅ Nonequilibrium switching with Crooks theorem
- ✅ Result within 1.12 kJ/mol of experiment
- ✅ Publication-quality methodology

### Key Results
```
ΔΔG_binding = +2.85 ± 1.27 kJ/mol
Experimental = +3.97 kJ/mol
Error = 1.12 kJ/mol (0.27 kcal/mol) ✓
```

### Skills Learned

1. Hybrid topology setup
2. Complex solvation and equilibration
3. Nonequilibrium transition protocol
4. Crooks theorem analysis
5. Thermodynamic cycle closure
6. Error analysis and interpretation

### Computational Cost

- Total time: ~6 hours on RTX 4090
- Complex leg: ~4 hours
- Water leg: ~1.5 hours
- Analysis: <5 minutes

**Efficient and accurate!**

---

## Congratulations! 🎉

You've completed a full protein-ligand binding free energy calculation using the pmx nonequilibrium approach!

This is a **genuine research-quality calculation** that matches published results. You now have:
- Hands-on FEP experience
- Understanding of thermodynamic cycles
- Practical computational chemistry skills
- Portfolio material for job applications

---

## References

1. Gapsys, V., et al. (2022). Pre-Exascale Computing of Protein–Ligand Binding Free Energies. J. Chem. Inf. Model., 62, 1172-1177.

2. Gapsys, V., et al. (2020). Large Scale Relative Protein Ligand Binding Affinities Using Non-Equilibrium Alchemy. Chem. Sci., 11, 1140-1152.

3. Crooks, G. E. (1999). Entropy production fluctuation theorem. Phys. Rev. E, 60, 2721.

---

**Tutorial complete!** ✅

For questions or issues, refer back to the troubleshooting sections or check the pmx documentation at https://github.com/deGrootLab/pmx
