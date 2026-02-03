# create raw phenotype csvs with table export

# run the following code from ttyd terminal
dir="project-GgYky4QJj5pkv6G9P8Zp6P26:/Cardio_IRM/input"

for num in $(seq 1 20)
do
dx run app-table-exporter \
-y \
-idataset_or_cohort_or_dashboard="${dir}/Cardio_IRM_Pt${num}" \
-ioutput="Cardio_IRM_Pt${num}" \
--brief \
--name "table_exporter${num}" \
--destination ${dir}
done