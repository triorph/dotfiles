basicBashrc='
alias k=kubectl
kubens() {
  kubectl config set-context --current --namespace "$1"
}
'
basicVimrc='
set number
set relativenumber
set nocompatible
set backspace=indent,eol,start
set smarttab
colorscheme desert
set ruler
set wildmenu
set scrolloff=5
set sidescrolloff=5
set sidescroll=2
set display+=truncate
set display+=lastline
set autoread
'

kitt() {
  # Only create the KUBECONFIG if it hasn't been set already
  if [[ "$KUBECONFIG"="" ]]; then
    export KUBECONFIG=$(atlas kitt context:create --pid=$$)
  fi
	atlas kitt context "$@"
}

icLogin() {
    region="$1"
    cluster="$2"
    accountId="$3"
    echo "Getting cluster credentials ($cluster)"
    kitt -f $cluster -a admin -n default
    kubeconfig=$(cat "$KUBECONFIG")
    echo "Assuming sysadmin role ($accountId)"
    eval "$(atlas micros role assume sysadmin -a $accountId -t NOISSUE)"
    echo "Finding kitt-jumpbox"
    JUMPBOX_INSTANCE_ID=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=kitt-jumpbox" "Name=instance-state-name,Values=running" \
        --query 'Reservations[].Instances[].InstanceId' \
        --output text --region "$region" --max-items=1 | head -1)
    echo "Starting interactive session and copying commands to clipboard. Paste them once connected:"
    echo "start.sh"$'\n'\
      "mkdir -p ~/.kube"$'\n'\
      "echo '$kubeconfig' > ~/.kube/config"$'\n'\
      "echo '$basicBashrc' > ~/.bashrc"$'\n'\
      "echo '$basicVimrc' > ~/.vimrc"$'\n'\
      "source ~/.bashrc"$'\n'\
      "kubectl get node -L role" \
      | pbcopy
    echo ""
    aws ssm start-session --region "$region" --target "$JUMPBOX_INSTANCE_ID"
}

# Function to start jumpbox and set up kubeconfig for IC in dev (tkq2)
# Usage: type icDev in terminal and paste clipboard contents into jumpbox terminal
icDev() {
  icLogin "ap-southeast-2" "tkq2" "296062586264"
}

# Function to start jumpbox and set up kubeconfig for IC in staging (9kpn)
# Usage: type icStg in terminal and paste clipboard contents into jumpbox terminal
icStg() {
  icLogin "us-east-1" "9kpn" "746669234451"
}
