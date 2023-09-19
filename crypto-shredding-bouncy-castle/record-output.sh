for stepSh in $(ls step*sh | sort ) ; do
    echo "Processing $stepSh"
    step=$(echo "$stepSh" | sed "s/.sh$//" )
    sh -x $stepSh > output/$step.txt 2>&1

    awk '
      BEGIN { content = ""; tag = "'$step-OUTPUT'" }
      FNR == NR { content = content $0 ORS; next }
      { gsub(tag, content); print }
    ' output/$step.txt Readme.md > temp.txt && mv temp.txt Readme.md

done
