"""Generate manuscript tables and number macros from the saved analysis results."""
from pathlib import Path
import json
from decimal import Decimal, ROUND_HALF_UP
BASE=Path(__file__).resolve().parents[1]
r=json.loads((BASE/'results/results.json').read_text())
import csv
questions={row['variable']:row['description'] for row in csv.DictReader((BASE/'data/data_dictionary.csv').open()) if row['variable'].startswith('Q')}
OUT=BASE/'tables';OUT.mkdir(exist_ok=True)
def fmt(x,d=2):
    return format(Decimal(str(x)).quantize(Decimal(1).scaleb(-d),rounding=ROUND_HALF_UP),f'.{d}f')
def pval(p): return r'$<0.001$' if p<.001 else f'{p:.3f}'
def sci(p):
    m,e=f'{p:.3e}'.split('e')
    return '$'+m+r'\times10^{'+str(int(e))+'}$'
def esc(s):
    for a,b in [('&',r'\&'),('%',r'\%'),('_',r'\_')]:s=s.replace(a,b)
    return s
def tab(name,headers,rows,align=None):
    align=align or ('l'+'r'*(len(headers)-1))
    lines=[r'\begin{tabular}{'+align+'}',r'\toprule',' & '.join(headers)+r' \\',r'\midrule']
    lines += [' & '.join(map(str,row))+r' \\' for row in rows]
    lines += [r'\bottomrule',r'\end{tabular}']
    (OUT/name).write_text('\n'.join(lines)+'\n')

macros={}
def put(k,v):macros[k]=str(v)
put('NStudents',65);put('NEnrolled',84);put('ResponsePercent',fmt(100*65/84,1))
for i,x in enumerate(r['descriptives']):
    pref='Item'+['One','Two','Three','Four','Five','Six','Seven','Eight','Nine'][i]
    for k in ['mean','sd','median']:put(pref+k.title(),fmt(x[k]) if k in ['mean','sd'] else fmt(x[k],0))
    put(pref+'UpperN',x['upper']);put(pref+'UpperPercent',fmt(100*x['upper']/65,1))
s=r['sign'];put('PairHigher',s['positive']);put('PairEqual',s['equal']);put('PairLower',s['negative']);put('PairNonTied',s['non_tied'])
put('PairProbability',fmt(s['probability']));put('PairCiLow',fmt(s['ci'][0]));put('PairCiHigh',fmt(s['ci'][1]))
put('PairHigherPercent',fmt(100*s['positive']/65,1));put('PairEqualPercent',fmt(100*s['equal']/65,1));put('PairLowerPercent',fmt(100*s['negative']/65,1))
for i,x in enumerate(r['groups']):
    pref=['ExperienceSharing','PreferenceSharing','ExperienceSatisfaction','PreferenceSatisfaction'][i]
    for k in ['effect','ci_low','ci_high']:put(pref+{'effect':'Delta','ci_low':'Low','ci_high':'High'}[k],fmt(x[k]))
for i,x in enumerate(r['correlations']):
    pref=['SharingBenefit','ReviewingBenefit'][i]
    for k in ['rho','ci_low','ci_high']:put(pref+{'rho':'Rho','ci_low':'Low','ci_high':'High'}[k],fmt(x[k]))
(BASE/'numbers.tex').write_text('% Automatically generated; edit analysis inputs, not these values.\n'+'\n'.join('\\newcommand{\\'+k+'}{'+v+'}' for k,v in macros.items())+'\n')

demo=[]
for title,key,levels in [('Gender','gender',[('Male','Male'),('Female','Female'),('Prefer not to say','Undisclosed')]),
 ('Prior programming experience','prior_programming',[('1','Yes'),('0','No')]),
 ('Recalled initial preference','recalled_interactive',[('1','Interactive'),('0','Traditional')]),
 ('Taking the course for the first time','first_time',[('1','Yes'),('0','No')])]:
 for j,(code,label) in enumerate(levels):
  n=r['demographics'][key][code]
  demo.append([title if j==0 else '',label,n,fmt(n/65*100,1)])
tab('table1_participants.tex',['Characteristic','Category','$n$',r'\%'],demo,'llrr')

labels=['Laboratory satisfaction','Increased course interest','Usefulness of tools','Usefulness of advance materials','Shared own code','Benefit of own code being reviewed',"Reviewed peers' code",'Perceived algorithmic thinking improvement','Recommend continuation']
kind=['Evaluation']*4+['Participation','Perceived benefit','Participation','Perceived benefit','Evaluation']
tab('table2_items.tex',['Item','Content','Analytical role'],[[f'Q{i+1}',labels[i],kind[i]] for i in range(9)],'lll')

rows=[]
for i,g in enumerate(r['groups']):
    contrast=['Experience: yes vs. no','Preference: interactive vs. traditional','Experience: yes vs. no','Preference: interactive vs. traditional'][i]
    med=f"{g['median1']:g} / {g['median0']:g}"
    rows.append([contrast,g['outcome'],med,fmt(g['effect']),f"[{fmt(g['ci_low'])}, {fmt(g['ci_high'])}]",pval(g['p_holm'])])
tab('table3_groups.tex',['Contrast','Item','Medians',r'$\delta$',r'95\% CI',r'$p_{\mathrm{Holm}}$'],rows,'llrrrr')
rows=[[r'Q7 $>$ Q5 among unequal pairs','46',r'$\pi$ = '+fmt(s['probability']),f"[{fmt(s['ci'][0])}, {fmt(s['ci'][1])}]",pval(s['p_holm'])]]
for c in r['correlations']:rows.append([c['a']+'--'+c['b'],65,r'$\rho_s$ = '+fmt(c['rho']),f"[{fmt(c['ci_low'])}, {fmt(c['ci_high'])}]",pval(c['p_holm'])])
tab('table4_paired_associations.tex',['Comparison','$n$','Estimate',r'95\% CI',r'$p_{\mathrm{Holm}}$'],rows,'llrrr')

rows=[[q,esc(questions[q])] for q in questions]
tab('supp_items.tex',['Item','Verbatim statement'],rows,'lp{13.5cm}')
rows=[]
for d in r['descriptives']:
 rows.append([d['item'],*(d[f'n{i}'] for i in range(1,6)),fmt(d['mean']),fmt(d['sd']),f"{d['median']:g} [{d['q1']:g}, {d['q3']:g}]"])
tab('supp_descriptives.tex',['Item','1','2','3','4','5','Mean','SD','Median [Q1, Q3]'],rows,'lrrrrrrrr')
rows=[[g['test'].replace('_',r'\_'),g.get('U',''),pval(g['p']),pval(g['p_holm']),fmt(g['asymptotic_p'],6)] for g in r['groups']]
rows += [[c['test'].replace('_',r'\_'),'--',pval(c['p']),pval(c['p_holm']),'--'] for c in r['correlations']]
rows.insert(0,['Q7 vs. Q5 (sign)','--',sci(s['p']),sci(s['p_holm']),'--'])
tab('supp_all_tests.tex',['Test','$U$','$p$',r'$p_{\mathrm{Holm}}$','Asymptotic $p$'],rows,'lrrrr')
rows=[]
for g in r['gender']:rows.append([g['outcome'],f"{g['median1']:g} / {g['median0']:g}",fmt(g['effect']),f"[{fmt(g['ci_low'])}, {fmt(g['ci_high'])}]",pval(g['p']),pval(g['p_holm'])])
tab('supp_gender.tex',['Item','Medians F / M',r'$\delta$',r'95\% CI','$p$',r'$p_{\mathrm{Holm}}$'],rows,'lrrrrr')
rows=[]
for j,x in enumerate(r['measurement']['reliability']):
 rows.append([['Q1--Q4, Q9','Q5, Q6','Q7, Q8'][j],x['k'],fmt(x['alpha'],3),f"[{fmt(x['ci_low'],3)}, {fmt(x['ci_high'],3)}]",'--' if x['pearson_r'] is None else fmt(x['pearson_r'],3),'--' if x['spearman_brown'] is None else fmt(x['spearman_brown'],3)])
tab('supp_reliability.tex',['Items','$k$',r'$\alpha$',r'95\% CI','$r$','Spearman--Brown'],rows,'lrrrrr')
p=r['measurement']['parallel']
tab('supp_parallel.tex',['Root','PC observed','PC null 95th','FA observed','FA null 95th'],[[i+1,fmt(p['pc_observed'][i],3),fmt(p['pc_reference_95'][i],3),fmt(p['fa_observed'][i],3),fmt(p['fa_reference_95'][i],3)]for i in range(9)],'lrrrr')
fa=next(x for x in r['measurement']['common_factors'] if x['k']==3)
tab('supp_loadings.tex',['Item','F1','F2','F3','Communality','Uniqueness'],[[f'Q{i+1}',*(fmt(x,3) for x in fa['loadings'][i]),fmt(fa['communality'][i],3),fmt(fa['uniqueness'][i],3)]for i in range(9)],'lrrrrr')
tab('supp_model.tex',['Predictor',r'$\beta$','SE','OR',r'95\% Wald CI'],[[x['predictor'].replace('_',' '),fmt(x['beta'],3),fmt(x['se'],3),fmt(x['OR'],2),f"[{fmt(x['ci_low'])}, {fmt(x['ci_high'])}]"]for x in r['model']['estimates']],'lrrrr')
tab('supp_thresholds.tex',['Cutoff','Events',r'Experience $\beta$ (SE)',r'Preference $\beta$ (SE)'],[[f'Q5 $>$ {k}',next(x['events'] for x in r['model']['thresholds']if x['cutoff']==k),*(f"{fmt(next(x['beta'] for x in r['model']['thresholds']if x['cutoff']==k and x['term']==term),2)} ({fmt(next(x['se'] for x in r['model']['thresholds']if x['cutoff']==k and x['term']==term),2)})"for term in ['prior_programming','recalled_interactive'])]for k in range(1,5)],'lrrr')
tab('supp_sources.tex',['Language group','Source','$n$',r'\% of 65'],[[x['language'].replace('_',' '),x['source'],x['n'],fmt(x['percent'],1)]for x in r['experience_sources']],'llrr')
print('Generated',len(list(OUT.glob('*.tex'))),'LaTeX table files and number macros.')
