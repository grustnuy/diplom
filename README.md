# Дипломный практикум в YandexCloud
  * [Цели:](#цели)
  * [Этапы выполнения:](#этапы-выполнения)
      * [Регистрация доменного имени](#регистрация-доменного-имени)
      * [Создание инфраструктуры](#создание-инфраструктуры)
          * [Установка Nginx и LetsEncrypt](#установка-nginx)
          * [Установка кластера MySQL](#установка-mysql)
          * [Установка WordPress](#установка-wordpress)
          * [Установка Gitlab CE, Gitlab Runner и настройка CI/CD](#установка-gitlab)
          * [Установка Prometheus, Alert Manager, Node Exporter и Grafana](#установка-prometheus)
  * [Что необходимо для сдачи задания?](#что-необходимо-для-сдачи-задания)
  * [Как правильно задавать вопросы дипломному руководителю?](#как-правильно-задавать-вопросы-дипломному-руководителю)

---
## Цели:

1. Зарегистрировать доменное имя (любое на ваш выбор в любой доменной зоне).
2. Подготовить инфраструктуру с помощью Terraform на базе облачного провайдера YandexCloud.
3. Настроить внешний Reverse Proxy на основе Nginx и LetsEncrypt.
4. Настроить кластер MySQL.
5. Установить WordPress.
6. Развернуть Gitlab CE и Gitlab Runner.
7. Настроить CI/CD для автоматического развёртывания приложения.
8. Настроить мониторинг инфраструктуры с помощью стека: Prometheus, Alert Manager и Grafana.

---
## Этапы выполнения:

### Регистрация доменного имени

На [nic.ru](https://nic.ru) зарегистрирован домен `devopsik.ru`.

Настроены DNS:
![dns](src/img/DNS.jpg)

### Создание инфраструктуры

Создан S3 bucket в YC.
 
![S3](src/img/S3.jpg)



Для развертывания инфраструктуры:
- подставляем в `providers.tf` данные для провайдера;
- подставляем в `meta.txt` login и открытый ключ;
- в `variables.tf` указывается зарезервированный ip адрес для front instance
- выполняем `terraform apply`.

![terraform](src/img/terraform.jpg)

![infrastructure](src/img/infrastructure.jpg)
---
###Description

	Используемая версия Ansible 2.9.0
	
	В файле `hosts` находится inventory для playbook и переменные для ansible ssh proxy.
	
	В каталоге [Ansible](src/Ansible/) находяться необходимые роли. Установка разделена по сервисам и выполнянться в cледующем порядке:
	
	- front.yml (Nginx, LetsEncrypt, службу proxy, Node_Exporter)
	- MySQL.yml (установка и настройка MySQL кластера)
	- wordpress.yml (Nginx, Memcached, php5, Wordpress)
	- gitlab.yml (установка Gitlab)
	- runner.yml (установка Runner Gitlab)
	- NodeExporter.yml (установка NodeExporter на все хосты)
	- monitoring.yml (разворачивание мониторинга)
	
	
Для переключения между stage и prod запросами сертификатов следует отредактировать tasks с именем Create letsencrypt certificate в файле Ansible\roles\Install_Nginx_LetsEncrypt\tasks\main.yml, добавив или удалив в них флаг --staging :

```
- name: Create letsencrypt certificate front
  shell: letsencrypt certonly -n --webroot --staging -w /var/www/letsencrypt -m {{ letsencrypt_email }} --agree-tos -d {{ domain_name }}
  args:
    creates: /etc/letsencrypt/live/{{ domain_name }}
```

### Установка Nginx и LetsEncrypt

`ansible-playbook front.yml -i hosts`

![front](src/img/front.jpg)
___
### Установка кластера MySQL

`ansible-playbook MySQL.yml -i hosts`

![mysql/mysql.jpg)

Проверка репликации

![mysql-replic](src/img/mysql-replic.jpg)

___
### Установка WordPress

`ansible-playbook wordpress.yml -i hosts`

![WordPress](src/img/WordPress.jpg)

---
### Установка Gitlab CE и Gitlab Runner


`ansible-playbook wordpress.yml -i hosts`

![gitlab](src/img/gitlab.jpg)

Подключаемся по ssh на gitlab.devopsik.ru и переcоздаем пароль для учетки root `sudo gitlab-rake "gitlab:password:reset[root]"`


Перед установкой Gitlab Runner в файле [src\Ansible\roles\gitlab-runner\defaults\main.yml](src\Ansible\roles\gitlab-runner\defaults\main.yml) указываем gitlab_runner_coordinator_url и gitlab_runner_registration_token.

![runner](src/img/runner.jpg)

`ansible-playbook runner.yml -i hosts`

![runner2](src/img/runner2.jpg)

Для выполнения автоматического деплой на сервер `app.devopsik.ru` при коммите в репозиторий с WordPressзадачи deploy из GitLab в app.zhukops.ru была разработана следующая job:

```
before_script:

  - eval $(ssh-agent -s)

  - echo "$ssh_key" | tr -d '\r' | ssh-add -

  - mkdir -p ~/.ssh
  - chmod 700 ~/.ssh

stages:         
  - deploy

deploy-job:      
  stage: deploy
  script:
    - echo "Deploying application..." 
    - ssh -o StrictHostKeyChecking=no grustnuy@app.devopsik.ru sudo chown grustnuy /var/www/wordpress/ -R
    - rsync -vz -e "ssh -o StrictHostKeyChecking=no" ./* grustnuy@app.devopsik.ru:/var/www/wordpress/
    - ssh -o StrictHostKeyChecking=no grustnuy@app.devopsik.ru rm -rf /var/www/wordpress/.git
    - ssh -o StrictHostKeyChecking=no grustnuy@app.devopsik.ru sudo chown www-data /var/www/wordpress/ -R
```	
	

Настроиваем CI/CD систему для автоматического развертывания приложения при изменении кода.

Создаем переменную с ключом для доступа к серверу.

![variables](src/img/variables.jpg)

Проверяем работу.

![pipline](src/img/pipline.jpg)

![job](src/img/job.jpg)




___
### Установка Prometheus, Alert Manager, Node Exporter и Grafana

`ansible-playbook NodeExporter.yml -i hosts

![nodeexporter](src/img/nodeexporter.jpg)

`ansible-playbook monitoring.yml -i hosts`
![monitoring](src/img/monitoring.jpg)


- Grafana
Данные для входа в Grafana admin/admin.

Настраиваем Data Sources и импортируем шаблоны из [templates_grafana](src/templates_grafana).

![data_source](src/img/data_source.jpg)


![grafana](src/img/grafana.jpg)

- Prometheus
![prometheus](src/img/prometheus.jpg)

- Alert Manager

![alert](src/img/alert.jpg)
