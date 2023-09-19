svg-term \
  --in asciinema/all.asciinema \
  --width 140 --height 20 \
  --out images/all.svg \
  --window true

for stepSh in $(ls step*sh | sort ) ; do
    echo "Processing asciinema for $stepSh"
    step=$(echo "$stepSh" | sed "s/.sh$//" )
    rows=20

    asciinema rec \
      --title "$step" \
      --idle-time-limit 2 \
      --cols 140 --rows $rows \
      --command "sh type.sh $step.sh" \
      asciinema/$step.asciinema

    asciinemaLines=$(asciinema play -s 1000 asciinema/$step.asciinema | wc -l)
    if [ $asciinemaLines -lt 20 ] ; then
      rows=$asciinemaLines
    fi

    svg-term \
      --in asciinema/$step.asciinema \
      --out images/$step.svg \
      --height $rows \
      --window true

    agg \
      --theme "asciinema" \
      --last-frame-duration 5 \
      asciinema/$step.asciinema \
      images/$step.gif
done

asciinema rec \
  --title "Crypto Shredding with fips" \
  --idle-time-limit 2 \
  --cols 140 --rows 40 \
  --command "sh run.sh" \
  asciinema/all.asciinema

asciinemaUid=$(asciinema upload asciinema/all.asciinema 2>&1 | grep http | awk '{print $1}' | cut -d '/' -f 5)
gsed -i "s/ASCIINEMA_UID/$asciinemaUid/g" Readme.md

