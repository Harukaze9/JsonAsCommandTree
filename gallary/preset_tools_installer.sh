#!/bin/bash

scipt_dir=`dirname $(realpath ${0})`
cd $scipt_dir/..
source source-jact.sh
cd gallary
jact install jj.json >/dev/null
jact install cdd.json >/dev/null
jact install store_extension.sh >/dev/null

echo "Installation finished! See \"jact list\""