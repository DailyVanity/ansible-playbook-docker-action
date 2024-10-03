#!/bin/sh

set -e

# Evaluate vaultfile
export VAULTFILE=
if [ ! -z "$INPUT_KEYFILEVAULTPASS" ]
then
  echo "Using \$INPUT_KEYFILE_VAULT_PASS to decrypt keyfile."
  mkdir -p ~/.ssh
  echo "${INPUT_KEYFILEVAULTPASS}" > ~/.ssh/vault_key
  export VAULTFILE="--vault-password-file ~/.ssh/vault_key"
  export ANSIBLE_VAULT_PASSWORD_FILE="~/.ssh/vault_key"
  echo "\$INPUT_KEYFILEVAULTPASS is set. Will use value for vault."
else
  echo "\$INPUT_KEYFILEVAULTPASS not set. No vault set."
fi

# Evaluate keyfile
export KEYFILE=
if [ ! -z "$INPUT_KEYFILE" ]
then
  echo "\$INPUT_KEYFILE is set. Will use ssh keyfile for host connections."
  if [ ! -z "$VAULTFILE" ]
  then
    echo "Using \$VAULTFILE to decrypt keyfile."
    echo ansible-vault decrypt ${INPUT_KEYFILE} ${VAULTFILE}
    ansible-vault decrypt ${INPUT_KEYFILE} ${VAULTFILE}
  fi
  export KEYFILE="--key-file ${INPUT_KEYFILE}"
else
  echo "\$INPUT_KEYFILE not set. You'll most probably only be able to work on localhost."
fi

if [ ! -z "$INPUT_KEY" ] && [ "$INPUT_KEY" != "" ]; then
  echo "🔑 Loading the ssh key..."
  mkdir -p $HOME/.ssh
  echo "$INPUT_KEY" > $HOME/.ssh/deploykey
  chmod 0600 $HOME/.ssh/deploykey
  KEYFILE="--key-file $HOME/.ssh/deploykey"
  echo "Done!! 🍻"  
fi

if ["$KEYFILE" == ""]; then
  echo "😔 key is not set, Please set key."
  exit 1
fi

# Setting remote user
export KEYUSER=
if [ ! -z "$INPUT_KEYUSER" ]
then
  echo "\$INPUT_KEYFILE is set. Will use ssh keyfile for host connections."
  export KEYUSER="--user ${INPUT_KEYUSER}"
else
  echo "\$INPUT_KEYFILE not set. You'll most probably only be able to work on localhost."
fi

# Evaluate verbosity
export VERBOSITY=
if [ -z "$INPUT_VERBOSITY" ]
then
  echo "\$INPUT_VERBOSITY not set. Will use standard verbosity."
else
  echo "\$INPUT_VERBOSITY is set. Will use verbosity level $INPUT_VERBOSITY."
  export VERBOSITY="-$INPUT_VERBOSITY"
fi

# Evaluate inventory file
export INVENTORY=
if [ -z "$INPUT_INVENTORYFILE" ]
then
  echo "\$INPUT_INVENTORYFILE not set. Won't use any inventory option at playbook call."
else
  echo "\$INPUT_INVENTORYFILE is set. Will use ${INPUT_INVENTORYFILE} as inventory file."
  export INVENTORY="-i ${INPUT_INVENTORYFILE}"
fi

# Evaluate requirements.
export REQUIREMENTS=
if [ -z "$INPUT_REQUIREMENTSFILE" ]
then
  echo "\$INPUT_REQUIREMENTSFILE not set. Won't install any additional external roles."
else
  REQUIREMENTS=$INPUT_REQUIREMENTSFILE
  export ROLES_PATH=
  if [ -z "$INPUT_ROLESPATH" ]
  then
    echo "\$INPUT_ROLESPATH not set. Will install roles in standard path."
  else
    echo "\$INPUT_ROLESPATH is set. Will install roles to ${INPUT_ROLESPATH}."
    export ROLES_PATH=$INPUT_ROLESPATH
  fi
  echo "\$INPUT_REQUIREMENTSFILE is set. Will use ${INPUT_REQUIREMENTSFILE} to install external roles."

  if [ ! -z "$INPUT_GALAXYGITHUBTOKEN" ]
  then
    if [ ! -z "$INPUT_GALAXYGITHUBUSER" ]
    then
      export GALAXYGITHUBUSER=$INPUT_GALAXYGITHUBUSER
      export GALAXYGITHUBTOKEN=$INPUT_GALAXYGITHUBTOKEN
      echo "\$INPUT_GALAXYGITHUBTOKEN and \$INPUT_GALAXYGITHUBUSER are set. Will substitue \$GALAXYGITHUBUSER and \$GALAXYGITHUBTOKEN in \$REQUIREMENTSFILE."
      envsubst < ${INPUT_REQUIREMENTSFILE} > $(dirname "${INPUT_REQUIREMENTSFILE}")/substituted_requirements.yml
      export REQUIREMENTS=$(dirname "${INPUT_REQUIREMENTSFILE}")/substituted_requirements.yml
    else
      echo "\$INPUT_GALAXYTOKEN is set. Will login to Ansible Galaxy."
      ansible-galaxy login --github-token ${INPUT_GALAXYGITHUBTOKEN} ${VERBOSITY}
    fi
  else
    echo "\$INPUT_GALAXYGITHUBTOKEN not set. Won't do any authentication for roles installation."
  fi
  cat ${REQUIREMENTS}
  ansible-galaxy install --force \
    --roles-path ${ROLES_PATH} \
    -r ${REQUIREMENTS} \
    ${VERBOSITY}
fi

# Evaluate extra vars file
export EXTRAFILE=
if [ -z "$INPUT_EXTRAFILE" ]
then
  echo "\$INPUT_EXTRAFILE not set. Won't inject any extra vars file."
else
  echo "\$INPUT_EXTRAFILE is set. Will inject ${INPUT_EXTRAFILE} as extra vars file."
  export EXTRAFILE="--extra-vars @${INPUT_EXTRAFILE}"
fi

echo "going to execute: "
echo ansible-playbook ${INVENTORY} ${KEYUSER} ${KEYFILE} ${VERBOSITY} ${EXTRAFILE} ${INPUT_EXTRAVARS} ${EXTRAVARS} ${INPUT_PLAYBOOKNAME}
pwd
ls -al ./
ls -al ./.github
ansible-playbook ${INVENTORY} ${KEYUSER} ${KEYFILE} ${VERBOSITY} ${EXTRAFILE} ${INPUT_EXTRAVARS} ${EXTRAVARS} ${INPUT_PLAYBOOKNAME}
