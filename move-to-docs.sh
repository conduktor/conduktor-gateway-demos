#!/bin/bash

demos=~/conduktor/conduktor-docs/docs/gateway/demos
for i in `find . -type d -depth 1` ; do
  parent=`grep -m 1 'tag:' $i/Readme-doc.md | awk '{print $2}'`
  parentUpper=$(echo $parent | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
  mkdir -p $demos/$parent
  cp $i/Readme-doc.md-asciinema $demos/$parent/$i.md
done
