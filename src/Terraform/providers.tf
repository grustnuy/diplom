terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }

  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "<имя бакета>"
    region     = "ru-central1"
    key        = "<путь к файлу состояния в бакете>/<имя файла состояния>.tfstate"
    access_key = "<идентификатор статического ключа>"
    secret_key = "<секретный ключ>"


    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

provider "yandex" {
  token     = "<OAuth>"
  cloud_id  = "<идентификатор облака>"
  folder_id = "<идентификатор каталога>"
  zone      = "ru-central1-a"
}
