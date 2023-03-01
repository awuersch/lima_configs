function test { # context
  local context=$1
  kubectl --context $context run nginx --image nginx:1.22
  kubectl --context $context expose po/nginx --port 80 --type LoadBalancer
  kubectl --context $context get svc
  kubectl --context $context wait po --for condition=Ready --timeout 20s nginx
  bash ./tunnel.sh 9999 $LIMA_INSTANCE $context nginx default
  curl --max-time 21 --connect-timeout 20 -I -v localhost:9999
}

function clean-test { # context
  local context=$1
  kubectl --context $context delete svc nginx
  kubectl --context $context delete po nginx
}
