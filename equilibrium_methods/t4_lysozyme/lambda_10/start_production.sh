#!/bin/bash
for i in {0..10}; do
    echo "Processing Lambda $i..."
    cd lambda_$i
    
    # tpr 생성 (상위 폴더에 있는 npt 결과물 참조)
    gmx grompp -f md_$i.mdp -c ../npt.gro -p ../topol_hybrid.top -t ../npt.cpt -o fep_$i.tpr -maxwarn 4
    
    # mdrun 실행 (GPU 사용)
    gmx mdrun -v -deffnm fep_$i -nb gpu -pme gpu
    
    cd ..
done
