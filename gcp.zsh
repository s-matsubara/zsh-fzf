#!/usr/bin/env zsh

######################### PROJECT #########################

function _gcp_check_configuration() {
  local project="$1"

  if [[ -n ${project} ]]; then
    gcloud config configurations describe "${project}" &>/dev/null
    return $?
  fi

  return $?
}

function _gcp_create_configuration() {
  local project="$1"

  account=$(gcloud config get-value account)

  if [[ -n ${project} ]]; then
    gcloud config configurations create "${project}"
    gcloud config set project "${project}"
    gcloud config set account "${account}"
  fi

  return $?
}

function _gcp_activate_configuration() {
  local project="$1"

  if [[ -z "${project}" ]]; then return 1; fi

  _gcp_check_configuration "${project}"

  if [[ $? == 1 ]];
  then
    _gcp_create_configuration "${project}"
  else
    gcloud config configurations activate "${project}"
  fi

  return $?
}

function _gcp_change_project() {
  local project force
  local -A opthash
  zparseopts -D -A opthash --f f p: -project

  if [[ -n "${opthash[(i)-p]}" ]]; then
    project="${opthash[-p]}"
  elif [[ -n "${opthash[(i)--project]}" ]]; then
    project="${opthash[--project]}"
  fi

  force=false
  if [[ -n "${opthash[(i)-f]}" ]]; then
    force=true
  fi

  if [[ -z "${prject}" ]]; then
    if "${force}" ; then
      result=$(gcloud projects list | sed 1d | fzf)

      if [[ -z "${result}" ]]; then return 1; fi

      project=$(echo "${result}" | awk '{print $1}')
    else
      result=$(gcloud config configurations list | fzf --header-lines=1)

      if [[ -z "${result}" ]]; then return 1; fi

      project=$(echo "${result}" | awk '{print $1}')
    fi
  fi

  if [[ -z "${project}" ]]; then return 1; fi

  _gcp_activate_configuration "${project}"

  return $?
}

alias gcp=_gcp_change_project

######################### GCE #########################

function _gcp_compute_ssh() {
  local project instance zone
  local -A opthash
  zparseopts -D -A opthash --f f p: -project

  project=$(gcloud config get-value project)

  result=$(gcloud compute instances list | fzf --header-lines=1)

  if [[ -z "${result}" ]]; then return 1; fi

  instance=$(echo "${result}" | awk 'print $1')
  zone=$(echo "${result}" | awk 'print $1')

  if [[ -z "${project}" ]]; then return 1; fi
  if [[ -z "${instance}" ]]; then return 1; fi
  if [[ -z "${zone}" ]]; then return 1; fi

  echo "$(tput setaf 5)gcloud compute ssh \"${instance}\" --zone=\"${zone}\" -- -A$(tput sgr0)"
  gcloud compute ssh "${instance}" --zone="${zone}" -- -A

  return $?
}

alias gcssh=_gcp_compute_ssh

######################### GKE #########################

function _gcp_kubernetes_complete() {
  line=$(gcloud container clusters list | sed 1d | awk 'print $1')
  _value cluster "${line[@]}"
}

function _gcp_kubernetes_activate() {
  local cluster="$1"
  local zone_or_region="$2"

  if echo "${zone_or_region}" | grep '[^-]*-[^-]*-[^-]*' > /dev/null; then
    echo "$(tput setaf 5)gcloud container clusters get-credentials \"${cluster}\" --zone=\"${zone_or_region}\"$(tput sgr0)"
    gcloud container clusters get-credentials "${cluster}" --zone="${zone_or_region}"
  else
    echo "$(tput setaf 5)gcloud container clusters get-credentials \"${cluster}\" --region=\"${zone_or_region}\"$(tput sgr0)"
    gcloud container clusters get-credentials "${cluster}" --region="${zone_or_region}"
  fi

  return $?
}

function _gcp_change_kubernetes() {
  local cluster="$1"

  if [[ -z "${cluster}" ]]; then
    line=$(gcloud container clusters list | fzf --header-lines=1)
    cluster=$(echo "${line}" | awk 'print $1')
  else
    line=$(gcloud container clusters list | grep "${cluster}")

    if [[ -z "${result}" ]]; then return 1; fi
  fi

  if [[ -z "${cluster}" ]]; then return 1; fi

  zone_or_region=$(echo "${line}" | awk 'print $2')

  _gcp_change_kubernetes "${cluster}" "${zone_or_region}"

  return $?
}

alias kg=_gcp_change_kubernetes
compdef _gcp_kubernetes_complete _gcp_change_kubernetes
