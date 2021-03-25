#!/usr/bin/env bash

#List all pods in the current namespace
kp() {
    kubectl get pods
}

# Quickly executes bash in the pod.
ke() {
    pod=$(choose_pod "$1")
    if [ "$pod" = "" ]; then return; fi

    echo " === Logging into $pod ==="

    container=$(choose_container "$pod" )
    echo '\033[0;32m'
    kubectl exec -it "$pod" -c "$container" -- bash
    echo '\033[0m'
}

# Edits a custom resource
kee() {
    resource_definition=$(choose_custom_resource "$1")

    if [ "$resource_definition" = "" ]; then return; fi

    resource=$(choose_resource "$resource_definition")

    kubectl edit "$resource"
}

#Get logs from pod in the current namespace
kl() {
    pod=$(choose_pod "$1")
    if [ "$pod" = "" ]; then return; fi

    container=$(choose_container "$pod" )
    kubectl logs "$pod" -c "$container" -f
}

#Changes context
kc() {
    context=$(choose_context "$1")
    if [ "$context" = "" ]; then return; fi

    kubectl config use-context "$context"
}

#Read and decodes a secret
ks() {
    secret=$(choose_secret "$1")

    if [ "$secret" = "" ]; then return; fi

    secret-read "${secret#*/}"
}

#Reads all services with an external ip, and opens the link of the selected one.
ksvc() {
    svc=$(choose_svc "$1")

    if [ "$svc" = "" ]; then return; fi

    port=$(echo "$svc" | awk '{print $5}' | cut -d':' -f 1)
    url=$(echo "$svc" | awk '{str = sprintf("http://%s", $4)} END {print str}')
    open "$url":"$port"

}

#Chooses a resource (only those that show up with kubectl get all)
# and runs "describe" on it
kd() {
    res=$(choose_all "$1")
    if [ "$res" = "" ]; then return; fi

    kubectl describe "$res"
}

#Chooses a resource (only those that show up with kubectl get all)
# and runs "delete" on it, asking for confirmation
kdd() {
    res=$(choose_all "$1")
    if [ "$res" = "" ]; then return; fi

    ans="n"
    read -r  "ans?Are you sure you want to delete $res? [y/N] "
    if [[ "$ans" =~ ^[Yy]$ ]]
    then
        kubectl delete "$res"
    fi
}


#Chooses a resource (only those that show up with kubectl get all)
# and runs "get -o yaml" on it
#TODO Support other formats than yaml
ko() {
    res=$(choose_all "$1")
    if [ "$res" = "" ]; then return; fi

    kubectl get "$res" -o yaml
}
kj() {
    res=$(choose_all "$1")
    if [ "$res" = "" ]; then return; fi

    kubectl get "$res" -o json
}



# Deletes a resource (if shown by kubectl all)
# and deletes it with --grace-period=0 --force
kdf() {
    res=$(choose_all "$1")
    if [ "$res" = "" ]; then return; fi

    kubectl delete "$res" --grace-period=0 --force
}

choose_pod() {
    if [ -n "$1" ]; then
        echo "$1"
        return
    else
        kubectl get pods --no-headers | fzf | awk '{ print $1 }'
    fi
}

choose_context() {
    if [ -n "$1" ]; then
        echo "$1"
        return
    else
        kubectl config get-contexts --no-headers -o name | fzf | awk '{ print $1 }'
    fi
}

choose_secret() {
    if [ -n "$1" ]; then
        echo "$1"
        return
    else
        kubectl get secrets -o name | fzf | awk '{ print $1 }'
    fi
}


choose_svc() {
    if [ -n "$1" ]; then
        echo "$1"
        return
    else
        k get svc --no-headers | grep "<none>" -v | fzf
    fi
}

choose_all(){
    if [ -n "$1" ]; then
        echo "$1"
        return
    else
        kubectl get all --no-headers -o name | fzf | awk '{ print $1 }'
    fi
}


secret-read() {
    kubectl get secret "$1" -o json | jq -r '.data | with_entries(.value |= @base64d)';
}


choose_custom_resource() {
    if [ -n "$1" ]; then
        echo "$1"
        return
    else
        resources=(); for crd in $(kubectl get crds -o name); do resources+=("${crd##*/}"); resources+=('\n'); done
        echo "${resources[@]}" | fzf | awk '{ print $1 }'
    fi
}

choose_resource() {
    kubectl get "$1" -o name | fzf | awk '{ print $1 }'
}


choose_api_resource() {
    kubectl api-resources --verbs=list -o name | fzf | awk '{ print $1 }'
}

choose_container() {
    pod="$1"
    containers=$(/bin/bash -c "kubectl get po \"$pod\" -o jsonpath={.spec.containers[*].name}")
    number_containers=$(awk -F" " '{print NF-1}' <<< "$containers")
    if [ "$number_containers" = "0" ]; then
        echo ""
        return
    else
        echo "$containers" | tr " " "\n" | fzf | awk '{ print $1 }'
    fi
}
