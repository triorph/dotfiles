kitt() {
  # Only create the KUBECONFIG if it hasn't been set already
	#  if [[ "$KUBECONFIG"="" ]]; then
	#    export KUBECONFIG=$(atlas kitt context:create --pid=$$)
	#  fi
	# atlas kitt context "$@"
  atlas kitt context --skip-context-pool -o kubeconfig "$@"
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

