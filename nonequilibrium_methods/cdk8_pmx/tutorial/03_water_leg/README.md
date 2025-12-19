# 03 - Water Leg

Calculate ΔΔG_water: the free energy difference for transforming ligand A to B in solution.

**Time required:** ~1.5 hours (much faster than complex!)

## Overview

The water leg simulates the ligand transformation **in pure solvent**:
```
Ligand A (water) → Ligand B (water)
```

This captures the **intrinsic stability difference** between the two ligands, independent of protein interactions.

### Why Do We Need This?

The complex leg gives us:
```
ΔΔG_complex = Change in (protein-ligand + intrinsic ligand stability)
```

The water leg isolates:
```
ΔΔG_water = Change in (intrinsic ligand stability only)
```

**The binding free energy difference:**
```
ΔΔG_binding = ΔΔG_complex - ΔΔG_water
```

This removes the intrinsic stability contribution, leaving only the binding contribution!

---

## Workflow Summary

Same as complex leg, but **simpler** (no protein!):

1. **Topology Setup** - Ligand only
2. **Solvation** - Smaller water box
3. **Energy Minimization** - States A and B
4. **NVT Equilibration** - 100 ps, states A and B
5. **Production Equilibration** - 6 ns, states A and B
6. **Frame Extraction** - 80 frames from each
7. **Transitions** - 160 × 50 ps
8. **Analysis** - Calculate ΔΔG_water

---

## Step 1: Setup Water Leg Directory
```bash
# Create water leg directory
mkdir -p ~/fep_tutorial/nonequilibrium_methods/cdk8_fep_test/water
cd ~/fep_tutorial/nonequilibrium_methods/cdk8_fep_test/water

# Copy hybrid ligand structures
cp ../edge_16_14/mergedA.pdb .
cp ../edge_16_14/mergedB.pdb .
```

**Note:** We copy both structures, but like before, only use mergedA.pdb for the actual simulation.

---

## Step 2: Create Water Topology

The topology is similar to complex, but **without protein**!
```bash
cat > topol_water.top << 'EOF'
; Include forcefield parameters
#include "../amber99sb-star-ildn-mut.ff/forcefield.itp"

; Include ligand atomtypes
#include "../../rel_ddG_MerckDataSet_JCIM/cdk8/ligands_gaff2/lig_16/ffMOL.itp"
#include "../../rel_ddG_MerckDataSet_JCIM/cdk8/ligands_gaff2/lig_14/ffMOL.itp"

; Include hybrid ligand dummy atomtypes
#include "../edge_16_14/ffmerged.itp"

; Include ligand molecule topology
#include "../edge_16_14/merged.itp"

; Include water topology
#include "../amber99sb-star-ildn-mut.ff/tip3p.itp"

; Include topology for ions
#include "../amber99sb-star-ildn-mut.ff/ions.itp"

[ system ]
; Name
Ligand in Water

[ molecules ]
; Compound        #mols
MOL                 1
