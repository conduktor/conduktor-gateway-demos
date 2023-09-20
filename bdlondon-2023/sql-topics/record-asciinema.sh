docker rm -f $(docker ps -aq)
docker compose up -d --wait

for stepSh in $(ls step*sh | sort ) ; do
    echo "Processing asciinema for $stepSh " `date`
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
  --title "SQL topics" \
  --idle-time-limit 2 \
  --cols 140 --rows 40 \
  --command "sh run.sh" \
  asciinema/all.asciinema

svg-term \
  --in asciinema/all.asciinema \
  --width 140 --height 20 \
  --out images/all.svg \
  --window true

asciinemaUid=$(asciinema upload asciinema/all.asciinema 2>&1 | grep http | awk '{print $1}' | cut -d '/' -f 5)
gsed -i "s/ASCIINEMA_UID/$asciinemaUid/g" Readme.md

markers=""
step=1
for time in $(grep "#" asciinema/all.asciinema | cut -d "." -f 1 | sed "s/\[//g") ; do
  stepTitle=`grep "execute.*sh" run.sh | awk "NR==$step" |cut -d '"' -f 4 | tr -d '\'`
  echo $stepTitle
  markers="""$markers
$time.0 - $step - $stepTitle"""
  step=$((step+1))
done


curl "https://asciinema.org/a/$asciinemaUid" \
  -H 'authority: asciinema.org' \
  -H 'content-type: application/x-www-form-urlencoded' \
  -H 'cookie: a608749=1; a608760=1; a608768=1; auth_token=E1WbYRLAwFWjtpBumGG5; a608770=1; a608897=1; a608906=1; _asciinema_key=SFMyNTY.g3QAAAACbQAAAAtfY3NyZl90b2tlbm0AAAAYRTNXN1cteG1hT1h4T1l5amFFZkN2Y0lZbQAAAAd1c2VyX2lkYgABp3M.00p16kmv-MCNeoQG_CCcdMNEIcbeoX7Sz4LW9f-gwcQ' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36' \
  --data-raw '_method=put&_csrf_token=I0cIAgAZEzQ1GwArGCAdXA4uI3sQAS4gft_5W4kYTTXSWyd6okE8fbgy' \
  --data-urlencode "asciicast[markers]=$markers"

