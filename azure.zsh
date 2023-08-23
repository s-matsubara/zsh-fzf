#!/usr/bin/env zsh

######################### PROJECT #########################

function _azure_change_subscription() {
  local subscription
  local -A opthash
  zparseopts -D -A opthash -- s: -subscription:

  if [[ -n "${opthash[(i)-s]}" ]]; then
    subscription="${opthash[-s]}"
  elif [[ -n "${opthash[(i)--subscription]}" ]]; then
    subscription="${opthash[--subscription]}"
  fi

  if [[ -z "${subscription}" ]]; then
    subscription=$(az account list --all -o tsv | fzf --exit-0 | awk 'print $3')
  fi

  if [[ -z "${subscription}" ]]; then return 1; fi

  az account set --subscription "${subscription}"

  return $?
}

alias azure=_azure_change_subscription

######################### AKS #########################

function _azure_kubernetes_activate() {
  local cluster="$1"
  local group="$2"

  echo "$(tput setaf 5)az aks get-credentials --name \"${cluster}\" --resource-group \"${group}\"$(tput sgr0)"
  az aks get-credentials --name "${cluster}" --resource-group "${group}"

  return $?
}

function _azure_change_kubernetes() {
  group=$(az group list -o table | fzf --header-lines=2 --exit-0 | awk '{print $1}')

  if [[ -z "${group}" ]]; then return 1; fi

  cluster=$(az aks list -o table --resource-group "${group}" | fzf --header-lines=2 --exit-0 | awk 'print $1')

  if [[ -z "${cluster}" ]]; then return 1; fi

  az aks get-credentials --name "${cluster}" --resource-group "${group}"

  return $?
}

alias ka=_azure_change_kubernetes
