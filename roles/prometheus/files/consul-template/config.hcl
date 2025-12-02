consul {
  address = "host.docker.internal:8500"
}

template {

  source = "/prometheus/prometheus.yml.ctmpl"
  destination = "/prometheus/prometheus.yml"
  exec {
    command = ["wget", "--post-data=", "http://prometheus.docker.internal:9090/prometheus/-/reload", "-O", "-"]
  }
}
