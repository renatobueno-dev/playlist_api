terraform {
  backend "kubernetes" {
    namespace     = "default"
    secret_suffix = "music-platform"
  }
}
