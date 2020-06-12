#!/bin/bash

set -e

createKeyFile() {
  local SSH_PATH="$HOME/.ssh"

  mkdir -p "$SSH_PATH"
  touch "$SSH_PATH/known_hosts"

  echo "$INPUT_KEY" > "$SSH_PATH/id_rsa"

  chmod 700 "$SSH_PATH"
  chmod 600 "$SSH_PATH/known_hosts"
  chmod 600 "$SSH_PATH/id_rsa"

  eval $(ssh-agent)
  ssh-add "$SSH_PATH/id_rsa"

  ssh-keyscan -t rsa "$INPUT_HOST" >> "$SSH_PATH/known_hosts"
}

executeSSH() {
  local USEPASS=$1
  local LINES=$2
  local COMMAND=""

  # holds all commands separated by semi-colon or keep "&&"
  local COMMANDS=""

  # this while read each commands in line and
  # evaluate each line against all environment variables
  echo "TEST $LINES"
  while IFS= read -r LINE; do
    echo "TEST $LINE"
    LINE=$(echo $LINE)
    COMBINE="&&"
    LASTCOMBINE="&&"
    if [[ $LINE =~ ^.*\&\&$ ]];  then
      LINE="$LINE true"
    elif [[ $LINE =~ ^\&\&.*$ ]];  then
      LINE="true $LINE"
    elif [[ $LINE =~ ^.*\|\|$ ]]; then
      LINE="$LINE false"
      LASTCOMBINE="||"
    elif [[ $LINE =~ ^\|\|.*$ ]]; then
      LINE="false $LINE"
      COMBINE="||"
    fi
    LINE=$(eval 'echo "$LINE"')
    LINE=$(eval echo "$LINE")
    LINE="$LINE $LASTCOMBINE"

    if [ -z "$COMMANDS" ]; then
      COMMANDS="$LINE"
    else
      # ref. https://unix.stackexchange.com/questions/459923/multiple-commands-in-sshpass
      if [[ $COMMANDS =~ ^.*\&\&$ ]] || [[ $COMMANDS =~ ^.*\|\|$ ]]; then
        COMMANDS="$COMMANDS $LINE"
      else
        COMMANDS="$COMMANDS $COMBINE $LINE"
      fi
    fi
  done <<< "$LINES"

  if [[ $COMMANDS =~ ^.*\&\&$ ]];  then
    COMMANDS="$COMMANDS true"
  elif [[ $COMMANDS =~ ^.*\|\|$ ]]; then
    COMMANDS="$COMMANDS false"
  fi
  echo "$COMMANDS"

  CMD="ssh"
  if $USEPASS; then
    CMD="sshpass -p $INPUT_PASS ssh"
  fi
  $CMD -o StrictHostKeyChecking=no -o ConnectTimeout=${INPUT_CONNECT_TIMEOUT:-30s} -p "${INPUT_PORT:-22}" "$INPUT_USER"@"$INPUT_HOST" "$COMMANDS" > /dev/stdout
}

executeSCP() {
  local USEPASS=$1
  local LINES=$2
  local COMMAND=

  CMD="scp"
  if $USEPASS; then
    CMD="sshpass -p $INPUT_PASS scp"
  fi

  while IFS= read -r LINE; do
    delimiter="=>"
    LINE=`echo $LINE`
    s=$LINE$delimiter
    arr=()
    while [[ $s ]]; do
        arr+=( "${s%%"$delimiter"*}" );
        s=${s#*"$delimiter"};
    done;
    LOCAL=$(eval 'echo "${arr[0]}"')
    LOCAL=$(eval echo "$LOCAL")
    REMOTE=$(eval 'echo "${arr[1]}"')
    REMOTE=$(eval echo "$REMOTE")

    if [[ -z "${LOCAL}" ]] || [[ -z "${REMOTE}" ]]; then
      echo "LOCAL/REMOTE can not be parsed $LINE"
    else
      echo "Copying $LOCAL ---> $REMOTE"
      $CMD -r -o StrictHostKeyChecking=no -o ConnectTimeout=${INPUT_CONNECT_TIMEOUT:-30s} -P "${INPUT_PORT:-22}" $LOCAL "$INPUT_USER"@"$INPUT_HOST":$REMOTE > /dev/stdout
    fi
  done <<< "$LINES"
}


######################################################################################

echo "+++++++++++++++++++STARTING PIPELINES+++++++++++++++++++"

USEPASS=true
if [[ -z "${INPUT_KEY}" ]]; then
  echo "+++++++++++++++++++Use password+++++++++++++++++++"
else
  echo "+++++++++++++++++++Create Key File+++++++++++++++++++"
  USEPASS=false
  createKeyFile || false
fi

if ! [[ -z "${INPUT_FIRST_SSH}" ]]; then
  echo "+++++++++++++++++++Step 1: RUNNING SSH+++++++++++++++++++"
  executeSSH "$USEPASS" "$INPUT_FIRST_SSH" || false
fi

if ! [[ -z "${INPUT_SCP}" ]]; then
  echo "+++++++++++++++++++Step 2: RUNNING SCP+++++++++++++++++++"
  executeSCP "$USEPASS" "$INPUT_SCP" || false
fi

if ! [[ -z "${INPUT_LAST_SSH}" ]]; then
  echo "+++++++++++++++++++Step 3: RUNNING SSH+++++++++++++++++++"
  executeSSH "$USEPASS" "$INPUT_LAST_SSH" || false
fi

echo "+++++++++++++++++++END PIPELINES+++++++++++++++++++"
