# SSM Parameter s konfigurací CloudWatch Agenta
resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  name        = "AmazonCloudWatch-${var.project_name}-agent-config"
  description = "Konfigurace CloudWatch agenta pro EC2 instanci"
  type        = "String"
  tier        = "Standard"

  value = jsonencode({
    agent = {
      metrics_collection_interval = 60
      run_as_user                 = "root"
    }

    metrics = {
      namespace = "${var.project_name}/EC2"
      metrics_collected = {
        cpu = {
          measurement = [
            "cpu_usage_idle",
            "cpu_usage_user",
            "cpu_usage_system",
            "cpu_usage_iowait"
          ]
          metrics_collection_interval = 60
          totalcpu                    = true
        }
        disk = {
          measurement = [
            "used_percent",
            "inodes_free"
          ]
          metrics_collection_interval = 60
          resources                   = ["*"]
        }
        mem = {
          measurement = [
            "mem_used_percent",
            "mem_available"
          ]
          metrics_collection_interval = 60
        }
        net = {
          measurement = [
            "bytes_sent",
            "bytes_recv",
            "packets_sent",
            "packets_recv"
          ]
          metrics_collection_interval = 60
          resources                   = ["*"]
        }
      }
    }

    logs = {
      logs_collected = {
        files = {
          collect_list = [
            {
              file_path        = "/var/log/nginx/access.log"
              log_group_name   = "/aws/ec2/${var.project_name}/nginx-access"
              log_stream_name  = "{instance_id}"
              retention_in_days = 7
            },
            {
              file_path        = "/var/log/nginx/error.log"
              log_group_name   = "/aws/ec2/${var.project_name}/nginx-error"
              log_stream_name  = "{instance_id}"
              retention_in_days = 7
            },
            {
              file_path        = "/var/log/messages"
              log_group_name   = "/aws/ec2/${var.project_name}/syslog"
              log_stream_name  = "{instance_id}"
              retention_in_days = 7
            },
            {
              file_path        = "/var/log/secure"
              log_group_name   = "/aws/ec2/${var.project_name}/secure"
              log_stream_name  = "{instance_id}"
              retention_in_days = 7
            }
          ]
        }
      }
    }
  })

  tags = {
    Name        = "${var.project_name}-cloudwatch-agent-config"
    Project     = var.project_name
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}