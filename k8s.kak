define-command k8s-highlights %{
  add-highlighter window/k8s-header line 1 white+bF
  add-highlighter window/k8s-pending-status regex (Waiting|Pending|Terminating|PodScheduled|PodReadyToStartContainers|ContainersReady) 1:blue
  add-highlighter window/k8s-good-status regex (Initialized|Read|Running) 1:green
  add-highlighter window/k8s-bad-status regex (Failed|ImagePullBackOff|CrashLoopBackoff) 1:red
  add-highlighter window/k8s-done-status regex (Succeded|Terminated|Unknown) 1:blue
  add-highlighter window/k8s-no-ready-pod regex (0/[0-9]+) 1:red
}

define-command k8s-get -params .. %{
  try %{
    delete-buffer %arg{1}
  }

  declare-option str k8s_fifo %sh{
    fifo="$(mktemp -d)/fifo"
    mkfifo $fifo
    echo $fifo
  }

  nop %sh{
    shift
    ( kubectl get $@ > $kak_opt_k8s_fifo & ) > /dev/null 2>&1 < /dev/null
  }

  edit -fifo %opt{k8s_fifo} %arg{1}

  hook -always -once buffer BufCloseFifo .* %{
    nop %sh{
      rm -r $(dirname $kak_opt_k8s_fifo)
    }
  }

  set-option buffer readonly true
}

define-command k8s-get-deploy -params .. %{
  k8s-get '*k8s-deploy*' deploy %arg{@}

  add-highlighter window/k8s-deployment regex '^([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+) *$)' 1:blue 2:white 3:magenta 4:magenta 5:comment
  k8s-highlights

  evaluate-commands %(map buffer normal <ret> 'git :k8s-get-pods -l "release=%reg{.}"<ret>')
}

define-command k8s-get-sts -params .. %{
  k8s-get '*k8s-sts*' sts %arg{@}

  add-highlighter window/k8s-deployment regex '^([^ ]+) +([^ ]+) +([^ ]+) *$)' 1:blue 2:white 3:comment
  k8s-highlights
}

define-command k8s-get-pods -params .. %{
  k8s-get '*k8s-pods*' pods %arg{@}

  add-highlighter window/k8s-deployment regex '^([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+) *$)' 1:blue 2:cyan 3:magenta 4:yellow 5:comment
  k8s-highlights
}

define-command kubectx -menu -shell-script-candidates 'kubectl config get-contexts -o name' -params 1 %{
  echo %sh{
    kubectl config use-context $1
  }
}

define-command kubens -menu -shell-script-candidates 'kubectl get namespaces --no-headers -o custom-columns=NAME:.metadata.name' -params 1 %{
  echo %sh{
    kubectl config set-context --current --namespace $1
  }
}
