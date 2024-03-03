#!/usr/bin/env bash

set -o pipefail # propogate return code in pipes
set -e # exit on error
set -u # error on unassigned variable use
#set -x # debug

# Set environment vars MAIL_USER, MAIL_FROM and MAIL_TO
source /etc/mail-gmail.conf

body_file1=$(mktemp)
body_file2=$(mktemp)

from=$MAIL_FROM
to=$MAIL_TO
unset subject
verbose=N

function egress {
  rm -f $body_file1 $body_file2
}
trap egress EXIT

function error_exit {
  echo "$1" >&2
  exit 1
}

function usage() {
cat << EOF
usage: $0 [-h] [-v] [-f from] [-t to] [-s subject] [-b body] [-i infile] [-c command] [body...]
mail information using a gmail account
    -h          - Help - print this help text
    -v          - verbose
    -f from     - from (default $from)
    -t to       - to (default $to)
    -s subject  - subject of email
    -b body     - body of email (may contain escape chars)
    -i infile   - body of email from file
    -c command  - body of email from command stdout and stderr
    body...     - zero or more lines of body text (may contain escape chars)
EOF
}

while getopts "hvf:t:s:b:i:c:" flag
do
  case "${flag}" in
    h) usage
       exit;;
    f) from="${OPTARG}";;
    v) verbose=Y;;
    t) to="${OPTARG}";;
    s) subject="${OPTARG}";;
    b) printf "${OPTARG}\n" >> $body_file1;;
    i) cat "${OPTARG}" >> $body_file1
       echo >> $body_file1
       ;;
    c) ${OPTARG} >> $body_file1 2>&1;;
    :) error_exit "$0: Must supply an argument to -$OPTARG.";;
    ?) error_exit "$0: Invalid parameter $OPTNAME";;
  esac
done
shift "$(($OPTIND -1))"

for arg ; do
  printf "$arg\n" >> $body_file1
done

[ -v subject ] || error_exit "$0: Must provide a subject for the email"

IFS="<>" myarray=($from)
if [ ${#myarray[@]} == 2 ]; then
  mail_from="${myarray[1]}"
else
  mail_from="$from"
fi

IFS="<>" myarray=($to)
if [ ${#myarray[@]} == 2 ]; then
  mail_to="${myarray[1]}"
else
  mail_to="$from"
fi

cat << EOF > $body_file2
From: $from
To: $to
Subject: $subject

EOF
cat $body_file1 >> $body_file2

if [ $verbose == Y ]; then
  cat $body_file2
  echo curl -s --url 'smtps://smtp.gmail.com:465' --ssl-reqd \
    --mail-from "$mail_from" \
    --mail-rcpt "$mail_to" \
    --user "XXXXXXXX" \
    --upload-file $body_file2
fi

curl -s --url 'smtps://smtp.gmail.com:465' --ssl-reqd \
    --mail-from "$mail_from" \
    --mail-rcpt "$mail_to" \
    --user "$MAIL_USER" \
    --upload-file $body_file2
