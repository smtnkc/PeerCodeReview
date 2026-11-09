"""Independent checks of the public survey data, results, and release checksums."""
from pathlib import Path
import csv, hashlib, json, math, statistics
BASE=Path(__file__).resolve().parents[1]
rows=list(csv.DictReader((BASE/'data/survey_responses.csv').open()))
r=json.loads((BASE/'results/results.json').read_text())
reference=json.loads((BASE/'reference_results/results.json').read_text())
checks=[]
def check(name,condition):
    if not condition: raise AssertionError(name)
    checks.append(name)
def vals(q):return [int(x[q]) for x in rows]
def near(a,b):return abs(a-b)<1e-10
expected=['gender','prior_programming','recalled_interactive']+[f'Q{i}' for i in range(1,10)]
check('Public schema has 12 analysis fields, no source rows or identifiers',list(rows[0])==expected)
check('65 complete ordinal response rows',len(rows)==65 and all(1<=int(x[q])<=5 for x in rows for q in expected[3:]))
for item in r['descriptives']:
    v=vals(item['item'])
    check(item['item']+' counts/mean/SD',all(item[f'n{i}']==v.count(i) for i in range(1,6)) and near(item['mean'],statistics.mean(v)) and near(item['sd'],statistics.stdev(v)))
diff=[int(x['Q7'])-int(x['Q5']) for x in rows]
p=sum(x>0 for x in diff);n=sum(x<0 for x in diff);ties=sum(x==0 for x in diff)
exact=min(1,2*sum(math.comb(p+n,k) for k in range(min(p,n)+1))/2**(p+n))
check('Paired counts and exact two-sided sign test',p==r['sign']['positive'] and n==r['sign']['negative'] and ties==r['sign']['equal'] and near(exact,r['sign']['p']))
check('Paired conditional denominator is 46',near(r['sign']['probability'],p/(p+n)) and p+n==46)
for g in r['groups']+r['gender']:
    yes,no=('Female','Male') if g['group']=='gender' else ('1','0')
    a=[int(x[g['outcome']]) for x in rows if x[g['group']]==yes]
    b=[int(x[g['outcome']]) for x in rows if x[g['group']]==no]
    wins=sum(x>y for x in a for y in b);losses=sum(x<y for x in a for y in b)
    equal=len(a)*len(b)-wins-losses
    check(g['test']+' independent dominance and U',near((wins-losses)/(len(a)*len(b)),g['effect']) and near(wins+equal/2,g['U']))
def ranks(v):
    order=sorted(range(len(v)),key=v.__getitem__);out=[0.]*len(v);i=0
    while i<len(v):
        j=i+1
        while j<len(v) and v[order[j]]==v[order[i]]:j+=1
        for k in range(i,j):out[order[k]]=(i+1+j)/2
        i=j
    return out
def rho(x,y):
    x,y=ranks(x),ranks(y);mx,my=statistics.mean(x),statistics.mean(y)
    return sum((a-mx)*(b-my) for a,b in zip(x,y))/math.sqrt(sum((a-mx)**2 for a in x)*sum((b-my)**2 for b in y))
for c in r['correlations']:check(c['test']+' independent Spearman correlation',near(rho(vals(c['a']),vals(c['b'])),c['rho']))
ps=[r['sign']['p']]+[g['p'] for g in r['groups']]+[c['p'] for c in r['correlations']]
order=sorted(range(7),key=ps.__getitem__);adj=[0.]*7;prev=0
for k,i in enumerate(order):prev=max(prev,min(1,(7-k)*ps[i]));adj[i]=prev
actual=[r['sign']['p_holm']]+[g['p_holm'] for g in r['groups']]+[c['p_holm'] for c in r['correlations']]
check('Independent seven-test Holm adjustment',all(near(a,b) for a,b in zip(adj,actual)))
for cols,a in zip([['Q1','Q2','Q3','Q4','Q9'],['Q5','Q6'],['Q7','Q8']],r['measurement']['reliability']):
    k=len(cols);vv=sum(statistics.variance(vals(q)) for q in cols)
    totals=[sum(int(x[q]) for q in cols) for x in rows]
    check('Independent alpha '+','.join(cols),near(k/(k-1)*(1-vv/statistics.variance(totals)),a['alpha']))
# JSON key order and insignificant platform round-off do not count as numerical differences.
def same(a,b):
    if isinstance(a,dict) and isinstance(b,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list) and isinstance(b,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    if isinstance(a,(float,int)) and isinstance(b,(float,int)):return math.isclose(a,b,rel_tol=1e-9,abs_tol=1e-10)
    return a==b
for key in reference:
    if key!='settings':check('Recomputed reference results: '+key,same(r[key],reference[key]))
manifest=BASE/'release_manifest.json'
if manifest.exists():
    hashes=json.loads(manifest.read_text())['sha256']
    check('All tracked release checksums',all(hashlib.sha256((BASE/p).read_bytes()).hexdigest()==h for p,h in hashes.items()))
report={'checks_passed':len(checks),'checks':checks,'entire_result_object_exactly_identical':r==reference,'comparison_tolerance':{'relative':1e-9,'absolute':1e-10},'scope':'Inferential analyses are recomputed; omitted individual background fields enter descriptive outputs only as aggregate inputs.'}
(BASE/'results/verification.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
