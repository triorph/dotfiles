kitt() {
  export KUBECONFIG=$(atlas kitt context --skip-context-pool -o kubeconfig "$@")
}

kitt-admin() {
	kitt -n default -a admin -f "$@"
}

kitt-local() {
	kitt -n default -a local -f "$@"
}

kitt-read() {
  kitt -n default -a read -f "$@"
}

