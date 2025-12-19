# 02 - Complex Leg

Calculate ΔΔG_complex: the free energy difference for transforming ligand A to B while bound to the protein.

**Time required:** ~4 hours on RTX 4090

## Overview

The complex leg simulates the ligand transformation **in the protein binding pocket**:
```
Ligand A + Protein → Ligand B + Protein
```

This captures:
- Protein-ligand interaction changes
- Conformational changes in the binding pocket
- Solvation effects around the complex

## Workflow Summary

1. **Topology Assembly** - Combine protein + hybrid ligand
2. **Solvation** - Add water box and ions
3. **Energy Minimization** - States A and B
4. **NVT Equilibration** - 100 ps, states A and B
5. **Production Equilibration** - 6 ns, states A and B
6. **Frame Extraction** - 80 frames from each equilibration
7. **Transitions** - 160 × 50 ps simulations
8. **Analysis** - Calculate ΔΔG_complex

---

## Step 1: Topology Assembly

### 1.1 Combine Protein and Ligand
```bash
cd ~/fep_tutorial/nonequilibrium_methods/cdk8_fep_test

# Combine protein + hybrid ligand (state A structure)
cat prot.pdb edge_16_14/mergedA.pdb > complex_A.pdb

# Verify
tail -20 complex_A.pdb
```

**Note:** We only use `mergedA.pdb` for structure. The topology handles both states A and B!

### 1.2 Create Complex Topology

The topology must include:
- Force field
- Ligand atomtypes (from both lig_16 and lig_14)
- Protein topology
- Hybrid ligand topology
- Water and ions
```bash
cat > topol_complex.top << 'EOF'
; Include forcefield parameters
#include "amber99sb-star-ildn-mut.ff/forcefield.itp"

; Include ligand atomtypes from both ligands
#include "../rel_ddG_MerckDataSet_JCIM/cdk8/ligands_gaff2/lig_16/ffMOL.itp"
#include "../rel_ddG_MerckDataSet_JCIM/cdk8/ligands_gaff2/lig_14/ffMOL.itp"

; Include hybrid ligand dummy atomtypes
#include "edge_16_14/ffmerged.itp"

; Include protein topology
#include "prot.itp"

; Include ligand molecule topology
#include "edge_16_14/merged.itp"

; Include water topology
#include "amber99sb-star-ildn-mut.ff/tip3p.itp"

#ifdef POSRES_WATER
; Position restraint for each water oxygen
[ position_restraints ]
;  i funct       fcx        fcy        fcz
   1    1       1000       1000       1000
#endif

; Include topology for ions
#include "amber99sb-star-ildn-mut.ff/ions.itp"

[ system ]
; Name
CDK8 Complex

[ molecules ]
; Compound        #mols
Protein_chain_A     1
MOL                 1
