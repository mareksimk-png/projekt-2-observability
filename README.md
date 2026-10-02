# AWS Observability Platform - Monitoring & Alerting

Portfolio projekt demonstrující observability a monitoring pro AWS infrastrukturu pomocí nativních AWS služeb.

## 🎯 Business Problem

Firma provozuje aplikaci na EC2 instanci, ale nemá žádný automatický dohled. Inženýr by musel 24/7 ručně kontrolovat servery, jestli běží, jestli nemají plný disk, nebo jestli je někdo nenapadá. To je neefektivní a náchylné k lidským chybám – problém se často zjistí, až když si zákazník stěžuje.

Tento projekt řeší tento problém **automatickým monitoringem a alertingem**: CloudWatch Agent sbírá metriky a logy z EC2 instance, CloudWatch Alarmy vyhodnocují kritické stavy a SNS posílá notifikace e-mailem. Inženýr je upozorněn **jen když se reálně něco děje**.

## 🏗️ Architektura

```
┌─────────────────────────────────────────────────────────────────┐
│                    AWS Cloud (eu-central-1)                     │
│                                                                  │
│  ┌─────────────── VPC z Projektu 1 ────────────────┐            │
│  │                                                   │            │
│  │  ┌─── Privátní podsíť ───┐                        │            │
│  │  │  ┌─────────────────┐  │                        │            │
│  │  │  │  EC2 instance   │  │ ← z Projektu 1          │            │
│  │  │  │  (s Nginxem)    │  │                        │            │
│  │  │  └────────┬────────┘  │                        │            │
│  │  │           │           │                        │            │
│  │  │           │ CloudWatch Agent posílá           │            │
│  │  │           │ metriky a logy                     │            │
│  │  └───────────┼───────────┘                        │            │
│  └──────────────┼────────────────────────────────────┘            │
│                 ↓                                                │
│         ┌────────────────────────────────────┐                   │
│         │       CloudWatch (AWS služba)      │                   │
│         │  - Metrics (CPU, RAM, disk, net)   │                   │
│         │  - Logs (Nginx, syslog, secure)    │                   │
│         │  - Alarms (CPU > 80%, disk, 5xx)   │                   │
│         │  - Dashboard                       │                   │
│         └────────────┬───────────────────────┘                   │
│                      ↓                                            │
│         ┌────────────────────────┐                                │
│         │  SNS Topic             │                               │
│         │  → E-mail notifikace   │                               │
│         └────────────────────────┘                                │
└──────────────────────────────────────────────────────────────────┘
```

## 🛠️ Použité technologie

- **Terraform** – Infrastructure as Code
- **AWS CloudWatch** – metrics, logs, alarms, dashboards
- **AWS CloudWatch Agent** – sběr metrik a logů z EC2
- **AWS SNS** – notifikace (e-mail)
- **AWS SSM Parameter Store** – centrální konfigurace CloudWatch Agenta
- **AWS IAM** – role pro CloudWatch Agent
- **S3 + Terraform remote state** – sdílený stav

## 🔑 Klíčová rozhodnutí

| Rozhodnutí | Důvod |
|-----------|-------|
| CloudWatch místo Datadog | Nativní AWS, žádná třetí strana, free tier |
| CloudWatch Agent přes SSM Parameter Store | Centrální konfigurace, lze měnit bez restartu instance |
| SNS pro notifikace | Nativní AWS, snadné rozšíření (Slack, Lambda) |
| Vlastní namespace `portfolio-iac/EC2` | Oddělení od default AWS metrik |
| 3 alarmy (CPU, Disk, Nginx 5xx) | Pokrývají klíčové signály: výkon, kapacita, chyby |
| Alarms → SNS → E-mail | Rychlá notifikace bez manuálního sledování |
| Retence logů 7 dní | Balance mezi historií a náklady |
| `treat_missing_data = "notBreaching"` | Alarm nezazvoní, když nejsou data (např. nová instance) |
| `use_lockfile` (ne DynamoDB) | Modernější, jednodušší, nižší náklady |

## 📁 Struktura projektu

```
projekt-2-observability/
├── README.md
├── versions.tf              # Terraform verze + S3 backend
├── provider.tf              # AWS provider + data sources
├── variables.tf             # Proměnné (region, e-mail, prahy)
├── terraform.tfvars.example # Vzorové hodnoty
├── main.tf                  # Propojení s Projektem 1 (terraform_remote_state)
├── sns.tf                   # SNS Topic + e-mail subscription
├── ssm.tf                   # SSM Parameter s konfigurací CloudWatch Agenta
├── cloudwatch.tf            # Log Metric Filter, Alarms, Dashboard
└── outputs.tf               # Výstupy (SNS ARN, atd.)
```

## 🚀 Jak nasadit

### Předpoklady

- **Projekt 1 musí být nasazen** (EC2 instance s Nginxem a SSM přístupem).
- Terraform >= 1.0.0
- AWS CLI nakonfigurované
- AWS účet s oprávněním vytvářet CloudWatch, SNS, IAM, SSM

### Postup

1. **Klonuj repozitář:**
   ```bash
   git clone https://github.com/TVUJ_USERNAME/projekt-2-observability.git
   cd projekt-2-observability
   ```

2. **Vytvoř `terraform.tfvars` ze šablony:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Uprav `alert_email`** na svůj e-mail (kam budou chodit notifikace).

4. **Inicializuj Terraform:**
   ```bash
   terraform init
   ```

5. **Nasaď infrastrukturu:**
   ```bash
   terraform plan
   terraform apply
   ```

6. **Potvrď SNS subscription:**
   - Zkontroluj e-mail a klikni na **„Confirm subscription"**.

7. **Nainstaluj CloudWatch Agent na EC2 instanci z Projektu 1:**
   ```bash
   # Přes SSM Run Command
   aws ssm send-command \
       --instance-ids <instance-id-z-projektu-1> \
       --document-name "AWS-ConfigureAWSPackage" \
       --parameters '{"action":["Install"],"name":["AmazonCloudWatchAgent"]}' \
       --region eu-central-1

   # Stáhni konfiguraci ze SSM
   aws ssm send-command \
       --instance-ids <instance-id> \
       --document-name "AWS-RunShellScript" \
       --parameters 'commands=["/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:AmazonCloudWatch-portfolio-iac-agent-config -s"]' \
       --region eu-central-1
   ```

8. **Ověř:**
   - **CloudWatch → Metrics → Custom Namespaces → `portfolio-iac/EC2`** (metriky).
   - **CloudWatch → Log Groups** (Nginx logy, syslog, secure).
   - **CloudWatch → Alarms** (3 alarmy).
   - **CloudWatch → Dashboards → `portfolio-iac-dashboard`** (grafy).

### Testování alarmů

**Simulace vysokého CPU** (alarm CPU > 80 %):

```bash
# Na EC2 instanci přes SSM:
for i in 1 2 3 4; do yes > /dev/null & done
# Nech běžet 5 minut, pak:
killall yes
```

**Co očekáváme:** Do 5 minut ti přijde e-mail s `ALARM: "portfolio-iac-cpu-high"`.

### Úklid

```bash
terraform destroy
```

**Pozor:** S3 bucket s remote state se nesmaže (`prevent_destroy`).

## 📊 Co projekt pokrývá

### Metriky (sbírá CloudWatch Agent)
- CPU (user, system, idle, iowait)
- Memory (used %, available)
- Disk (used %, inodes free) – pro všechny přípojné body
- Network (bytes sent/received, packets)

### Logy (sbírá CloudWatch Agent)
- `/var/log/nginx/access.log` – HTTP požadavky
- `/var/log/nginx/error.log` – chyby Nginx
- `/var/log/messages` – systémové zprávy
- `/var/log/secure` – bezpečnostní události (SSH přihlášení)

### Alarmy
| Alarm | Threshold | Akce |
|-------|-----------|------|
| CPU High | > 80 % po 5 min | SNS → e-mail |
| Disk High | > 85 % | SNS → e-mail |
| Nginx 5xx | > 10 chyb za 5 min | SNS → e-mail |

## 📚 Co jsem se naučil

- **CloudWatch Agent** – instalace, konfigurace přes SSM Parameter Store, sběr metrik a logů.
- **Log Metric Filters** – transformace logů na metriky (např. počet 5xx chyb).
- **CloudWatch Alarms** – nastavení threshold, evaluation periods, actions.
- **SNS** – topic, subscription, notifikace e-mailem.
- **IAM role pro monitoring** – `CloudWatchAgentServerPolicy`.
- **CloudWatch Dashboard** – vizualizace metrik.
- **Terraform `jsonencode`** – dynamické vytváření JSON konfigurace.
- **`terraform_remote_state`** – propojení dvou Terraform projektů.
- **Troubleshooting** – řešení problému s network metrikami (`ens5` vs `eth0`, použití `["*"]`).

## 🔗 Návaznost na Projekt 1

Tento projekt **navazuje na Projekt 1** (AWS IaC s VPC, EC2, SSM). Projekt 1 poskytuje:
- EC2 instanci s Nginxem.
- SSM přístup pro instalaci CloudWatch Agenta.
- IAM roli, ke které jsme přidali `CloudWatchAgentServerPolicy`.

Propojení je řešeno přes **`terraform_remote_state`** – Projekt 2 čte stav Projektu 1.

## 📝 Licence

MIT# projekt-2-observability
# projekt-2-observability
