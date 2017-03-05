#!/bin/bash

i=0
domaine=()
texte=()

for file in `find /etc/letsencrypt/live -type d -links 2`;do
        #echo "$file"
        domaine[$i]=`openssl x509 -in $file/cert.pem -noout -text | grep DNS | sed 's/, /\n/g' | cut -d: -f2`
        #echo "${domaine[$i]}"

        CERT_FILE="/etc/letsencrypt/live/${domaine[$i]}/fullchain.pem"

        if [ ! -f $CERT_FILE ]; then
                echo "[ERROR] certificate file not found for domain $domaine."
        fi

        DATE_NOW=$(date -d "now" +%s)
        EXP_DATE=$(date -d "`openssl x509 -in $CERT_FILE -text -noout | grep "Not After" | cut -c 25-`" +%s)
        EXP_DAYS[$i]=$(echo \( $EXP_DATE - $DATE_NOW \) / 86400 |bc)
        #echo "${EXP_DAYS[$i]}"

        lesDates=`openssl x509 -in $file/cert.pem -dates -noout | cut -d= -f2`

        texte[$i]="
${domaine[$i]}
Dates de validité :
$lesDates
Expire dans : ${EXP_DAYS[$i]} jour(s)
        "
        #echo "${texte[$i]}"

        i=$(($i+1))
done

for j in `seq 0 $((${#texte[@]}-1))`;
do
        #echo "$j"
        texteFinal=$texteFinal${texte[$j]}
done
#echo $texteFinal

mail -a "From: Agent de certification <root@cavaud.net>" -a "Content-Type: text/plain; charset=UTF-8" -s "Renouvellement des certificats" michel@cavaud.net<< EOF
Bonjour,

Le certificat des services couvre actuellement les domaines suivants :

$texteFinal

Pour rappel, les certificats délivrés par Let's Encrypt ont toujours une validité de 3 mois. Tâchez donc de définir une période de renouvellement inférieure à cette durée.
Il est à noter également que l'autorité Let's Encrypt ne délivre qu'un maximum de 5 certificats pour le même domaine par semaine. Renouvelez donc avec précaution.

Bonne journée.
EOF
