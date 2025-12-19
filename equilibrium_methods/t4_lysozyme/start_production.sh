#!/bin/bash
for i in {0..10}; do
    echo "Lambda $i 시작..."
    cd lambda_$i
    # 상위 폴더의 npt 결과물(gro, cpt, top)을 참조하여 tpr 생성
    gmx grompp -f md_$i.mdp -c ../npt.gro -p ../topol_hybrid.top -t ../npt.cpt -o fep_$i.tpr -maxwarn 4
    # 실행
    gmx mdrun -v -deffnm fep_$i -nb gpu -pme gpu
    cd ..
done
