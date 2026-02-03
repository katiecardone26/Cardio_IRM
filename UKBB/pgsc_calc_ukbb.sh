# create pgsc-calc docker applet
# build SAIGE applet (version on UKB is outdated grrrr)
# 1. use app wizard
dx-app-wizard
# 2. add following options into app-wizard
App Name: pgsc_calc
Title []: pgsc_calc
Summary []: Runs PGSC-CALC pipeline on UKBiobank DNAnexus, made by Katie Cardone
Version [0.0.1]:
1st input name (<ENTER> to finish): input
Label (optional human-readable name) []: 
Choose a class (<TAB> twice for choices): array:file
This is an optional parameter [y/n]: n
2nd input name (<ENTER> to finish): command
Label (optional human-readable name) []: 
Choose a class (<TAB> twice for choices): string
This is an optional parameter [y/n]: n
3rd input name (<ENTER> to finish):
1st output name (<ENTER> to finish):
Timeout policy [48h]: 7d
Programming language: bash
Will this app need access to the Internet? [y/N]: y
Will this app need access to the parent project? [y/N]: y
Choose an instance type for your app [mem1_ssd1_v2_x4]: mem1_ssd1_v2_x4
# 3. made additional edits to applet scripts in terminal (see uploaded scripts)
## use vim
# 4. build applet
dx build pgsc_calc --overwrite
# 5. upload applet scripts
dx upload -r pgsc_calc --path project-GgYky4QJj5pkv6G9P8Zp6P26:/HF_Clinical_PGS/scripts/

# extract pgs catalog variants and create plink files
# 1. run the following code from ttyd terminal
bgen_input_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/Bulk/Imputation/Imputation from genotype (TOPmed)"
variants_input_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/Cardio_IRM/input"
output_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/Cardio_IRM/output/plink"

for chr in $(seq 1 22)
do
dx run app-swiss-army-knife \
-y \
-iin="${bgen_input_dir}/ukb21007_c${chr}_b0_v1.bgen.bgi" \
-iin="${bgen_input_dir}/ukb21007_c${chr}_b0_v1.bgen" \
-iin="${bgen_input_dir}/ukb21007_c${chr}_b0_v1.sample" \
-iin="${variants_input_dir}/CAD.PGS005092.AFIB.PGS005072.var_list.txt" \
--brief \
--name "extact_pgs_vars.chr${chr}" \
-icmd="plink2 --bgen ukb21007_c${chr}_b0_v1.bgen ref-first \
                --sample ukb21007_c${chr}_b0_v1.sample \
                --extract range CAD.PGS005092.AFIB.PGS005072.var_list.txt \
                --set-all-var-ids @:#:\\\$r:\\\$a \
                --new-id-max-allele-len 1000 \
                --make-pgen \
                --out ukb21007_c${chr}_b0_v1.topmed_imputed.cad_afib_pgs_vars" \
--destination ${output_dir} \
--instance-type mem1_ssd2_v2_x8
done

# test applet
plink_input_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/Cardio_IRM/output/plink"
other_input_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/Cardio_IRM/input"
ancestry_input_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/HF_Clinical_PGS/input"
output_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/Cardio_IRM/output/pgsc_calc"

input_flags=()
for file in $(dx ls "${plink_input_dir}" --brief)
do
input_flags+=("-iinput=${plink_input_dir}/${file}")
done

for file in $(dx ls "${other_input_dir}/score_files" --brief)
do
input_flags+=("-iinput=${other_input_dir}/score_files/${file}")
done

dx run pgsc_calc \
-y \
-iinput="${other_input_dir}/UKBB.CAD.AFIB.PGSC_CALC.samplesheet.csv" \
-iinput="${ancestry_input_dir}/pgsc_HGDP+1kGP_v1.tar.zst" \
-icommand="ls input/; ls input/score_files/" \
--brief \
--name "pgsc_calc" \
--destination ${output_dir}


# submit pgsc-calc job from ukbb ttyd
# 1. run the following code in ttyd terminal
plink_input_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/Cardio_IRM/output/plink"
other_input_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/Cardio_IRM/input"
ancestry_input_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/HF_Clinical_PGS/input"
output_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/Cardio_IRM/output/pgsc_calc"

input_flags=()
for file in $(dx ls "${plink_input_dir}" --brief)
do
input_flags+=("-iinput=${plink_input_dir}/${file}")
done

for file in $(dx ls "${other_input_dir}/score_files" --brief)
do
input_flags+=("-iinput=${other_input_dir}/score_files/${file}")
done

dx run pgsc_calc \
-y \
"${input_flags[@]}" \
-iinput="${other_input_dir}/UKBB.CAD.AFIB.PGSC_CALC.samplesheet.csv" \
-iinput="${ancestry_input_dir}/pgsc_HGDP+1kGP_v1.tar.zst" \
-icommand="nextflow run pgscatalog/pgsc_calc -profile conda \
            --input input/UKBB.CAD.AFIB.PGSC_CALC.samplesheet.csv \
            --scorefile input/score_files/* \
            --target_build GRCh38 \
            --outdir output/ \
            --max_cpus 64 \
            --max_memory 256.GB \
            --min_overlap 0.0 \
            --max_time 240.h \
            --run_ancestry input/pgsc_HGDP+1kGP_v1.tar.zst \
            --keep_multiallelic True \
            --hwe_ref 0 \
            --pca_maf_target 0.05" \
--brief \
--name "pgsc_calc" \
--destination ${output_dir} \
--instance-type mem2_ssd1_v2_x64

# imputation R script
input_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/HF_Clinical_PGS/input/"
scripts_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/HF_Clinical_PGS/scripts/"
output_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/HF_Clinical_PGS/output/"

dx run app-swiss-army-knife \
-y \
-iin="${scripts_dir}/hf_clinical_pgs_imputation.R" \
-iin="${input_dir}/HF_Clinical_PGS.phenotype.csv" \
--brief \
--name "imputation" \
-icmd="Rscript hf_clinical_pgs_imputation.R \
                --input HF_Clinical_PGS.phenotype.csv \
                --output_prefix HF_Clinical_PGS.imputation" \
--destination ${output_dir} \
--instance-type mem1_ssd2_v2_x8

# training python script
input_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/HF_Clinical_PGS/input/"
scripts_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/HF_Clinical_PGS/scripts/"
output_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/HF_Clinical_PGS/output/regressions/training/"

for i in $(seq 1 1000)
do
dx run app-swiss-army-knife \
-y \
-iin="${scripts_dir}/hf_training_script.py" \
-iin="${input_dir}/HF_Clinical_PGS.phenotype.no_missing.variable_transformation.csv" \
--brief \
--name "training_${i}" \
-icmd="python hf_training_script.py \
                --input HF_Clinical_PGS.phenotype.no_missing.variable_transformation.csv \
                --iter ${i}" \
--destination ${output_dir} \
--instance-type mem1_ssd2_v2_x8
done

# test first iteration of eval python script
input_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/HF_Clinical_PGS/input/"
scripts_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/HF_Clinical_PGS/scripts/"
output_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/HF_Clinical_PGS/output/regressions/eval/"

dx run app-swiss-army-knife \
-y \
-iin="${scripts_dir}/hf_eval_script.py" \
-iin="${input_dir}/HF_Clinical_PGS.phenotype.no_missing.variable_transformation.csv" \
-iin="${input_dir}/UKBB.significant_vars_95.csv" \
-iin="${input_dir}/UKBB.important_vars_95.csv" \
-iin="${input_dir}/UKBB.LR_beta_all_iter.csv" \
--brief \
--name "eval_1" \
-icmd="python hf_eval_script.py \
                --input HF_Clinical_PGS.phenotype.no_missing.variable_transformation.csv \
                --sig UKBB.significant_vars_95.csv \
                --important UKBB.important_vars_95.csv \
                --beta UKBB.LR_beta_all_iter.csv \
                --iter 1" \
--destination ${output_dir} \
--instance-type mem1_ssd2_v2_x8

# eval python script
input_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/HF_Clinical_PGS/input/"
scripts_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/HF_Clinical_PGS/scripts/"
output_dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/HF_Clinical_PGS/output/regressions/eval/"

for i in $(seq 1 1000)
do
dx run app-swiss-army-knife \
-y \
-iin="${scripts_dir}/hf_eval_script.py" \
-iin="${input_dir}/HF_Clinical_PGS.phenotype.no_missing.variable_transformation.csv" \
-iin="${input_dir}/UKBB.significant_vars_95.csv" \
-iin="${input_dir}/UKBB.important_vars_95.csv" \
-iin="${input_dir}/UKBB.LR_beta_all_iter.csv" \
--brief \
--name "eval_${i}" \
-icmd="python hf_eval_script.py \
                --input HF_Clinical_PGS.phenotype.no_missing.variable_transformation.csv \
                --sig UKBB.significant_vars_95.csv \
                --important UKBB.important_vars_95.csv \
                --beta UKBB.LR_beta_all_iter.csv \
                --iter ${i}" \
--destination ${output_dir} \
--instance-type mem1_ssd2_v2_x8
done