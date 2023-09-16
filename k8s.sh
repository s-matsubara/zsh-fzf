#!/usr/bin/env zsh

######################### kubernetes #########################

function _kube_context() {
  local context
  context=$(kubectl config get-contexts | sed 's/\*/ /' | awk '{print $1}' | fzf --select-1 --header-lines=1)

  if [[ -z "${context}" ]]; then return 1; fi

  echo "${context}"
}

function _kube_use_context() {
  local context
  context=$(_kube_context)

  if [[ -z "${context}" ]]; then return 1; fi

  kubectl config use-context "${context}"

  return $?
}
alias kc=_kube_use_context

function _kube_exec() {
  local namespace pod container
  local sh=${1:=sh}

  namespace=$(kubectl get namespaces | awk '{print $1}' | sed '1d' | fzf --header="namespace" --info=hidden --exit-0) &&

  if [[ -z "${namespace}" ]]; then return 1; fi

  pod=$(kubectl get pods --namespace "${namespace}" | awk '{print $1}' | fzf --header="namespace" --info=hidden --exit-0) &&

  if [[ -z "${pod}" ]]; then return 1; fi

  container=$(kubectl get pods "${pod}" --namespace "${namespace}" -o jsonpath="{range .spec.containers[*]}{.name}{\"\n\"}{end}" | fzf --header="container" --select-1 --info=hidden --exit-0)

  if [[ -z "${container}" ]]; then return 1; fi

  kubectl exec -it "${pod}" --container "${container}" --namespace "${namespace}" -- ${sh}

  return $?
}
alias kexec=_kube_exec

function _kube_test() {
  local namespace pod container
  local -a list
  local sh
  pod=${1:="test-pod"}

  namespace=$(kubectl get namespaces | awk '{print $1}' | sed '1d' | fzf --header="namespace" --info=hidden --exit-0) &&

  if [[ -z "${namespace}" ]]; then return 1; fi

  list=(alpine:latest centos:latest mysql:latest curlimages/curl golang:latest busybox:latest other)

  image=$(printf "%s\n" "${list[@]}" | fzf)

  if [[ "${image}" == "other" ]]; then
    echo "input docker image name: "
    read -r image
  fi

  if [[ -z "${image}" ]]; then return 1; fi

  case "${image}" in
    "alpine:latest") sh="ash" ;;
    "centos:latest") sh="bash" ;;
    "mysql:latest") sh="bash" ;;
    "curlimages/curl") sh="sh" ;;
    "golang:latest") sh="bash" ;;
    "busybox:latest") sh="sh" ;;
    *) sh="sh" ;;
  esac

  kubectl run \
    --image="${image}" \
    --restart=Never \
    --namespace="${namespace}" \
    --rm -it "${pod}" \
    -- "${sh}"

  return $?
}
alias ktest=_kube_test
