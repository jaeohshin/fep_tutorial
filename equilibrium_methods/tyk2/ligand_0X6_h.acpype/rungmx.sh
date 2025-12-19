
echo 0 | gmx editconf -f ligand_0X6_h_GMX.gro -bt octahedron -d 10 -c -princ
gmx grompp -f em.mdp -c out.gro -p ligand_0X6_h_GMX.top -o em.tpr -v
gmx mdrun -ntmpi 1 -v -deffnm em
gmx grompp -f md.mdp -c em.gro -p ligand_0X6_h_GMX.top -o md.tpr -r em.gro
gmx mdrun -ntmpi 1 -v -deffnm md
