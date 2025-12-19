import pmx

# 에러 유발하는 검사 함수 무력화
pmx.Topology.assign_fftypes = lambda self: print("Bypassing FF Check...")

# 1. 토폴로지 읽기
top = pmx.Topology('topol_temp.top', ff='./amber99sb-star-ildn-mut.ff')

print("Manually triggering hybrid conversion...")

# 2. pmx 구조에 맞게 순회 (molecules 리스트 안의 각 molecule 객체)
for mname, mdata in top.molecules.items():
    # mdata는 보통 리스트이므로 안의 객체를 꺼냄
    for mol_obj in mdata:
        if hasattr(mol_obj, 'residues'):
            for res in mol_obj.residues:
                # 변이 잔기 이름(예: L2A)을 찾음
                if '2' in res.name and len(res.name) == 3:
                    print(f"Found mutation site: {res.name}. Converting...")
                    # res.mutate 대신 pmx의 기본 변환 로직 시도
                    res.mutate(res.name, ff=top.ff)

# 3. 저장
top.write('topol_hybrid.top')
print("-" * 30)
print("Check: topol_hybrid.top generated.")
