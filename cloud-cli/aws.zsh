function _aws_change_profile() {
  local profile
  local -A opthash
  zparseopts -D -A opthash -- p: -profile:

  if [[ -n "${opthash[(i)-p]}" ]]; then
    profile="${opthash[-p]}"
  elif [[ -n "${opthash[(i)--profile]}" ]]; then
    profile="${opthash[--profile]}"
  fi

  profile=$(aws configure list-profiles | fzf)

  if [[ -z "${profile}" ]]; then return 1; fi

  export AWS_PROFILE="${profile}"

  return $?
}
alias aw=_aws_change_profile
