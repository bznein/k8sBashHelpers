
kp() {
    k get pods
}

# Quickly executes bash in the pod.
ke() {
    pod=$(choose_pod "$1")
    if [ "$pod" = "" ]; then return; fi

    echo " === Logging into $pod ==="

    echo '\033[0;32m'
    k exec -it "$pod" -- bash
    echo '\033[0m'
}

kl() {
    pod=$(choose_pod "$1")
    if [ "$pod" = "" ]; then return; fi

    k logs "$pod" -f
}

kc() {
    context=$(choose_context "$1")
    if [ "$context" = "" ]; then return; fi

    k config use-context "$context"
}

ks() {
    secret=$(choose_secret "$1")

    if [ "$secret" = "" ]; then return; fi

    secret-read "${secret#*/}"
}

kd() {
    res=$(choose_all "$1")
    if [ "$res" = "" ]; then return; fi

    k describe "$res"
}

#Support other formats than yam;
ko() {
    res=$(choose_all "$1")
    if [ "$res" = "" ]; then return; fi

    k get "$res" -o yaml
}

choose_pod() {
    if [ -n "$1" ]; then
        echo "$1"
        return
    else
        k get pods --no-headers | fzf | awk '{ print $1 }'
    fi
}

choose_context() {
    if [ -n "$1" ]; then
        echo "$1"
        return
    else
        k config get-contexts --no-headers -o name | fzf | awk '{ print $1 }'
    fi
}

choose_secret() {
    if [ -n "$1" ]; then
        echo "$1"
        return
    else
        k get secrets -o name | fzf | awk '{ print $1 }'
    fi
}

choose_all(){
    if [ -n "$1" ]; then
        echo "$1"
        return
    else
        k get all --no-headers -o name | fzf | awk '{ print $1 }'
    fi
}


secret-read() {
    kubectl get secret $1 -o json | jq -r '.data | with_entries(.value |= @base64d)';
}
