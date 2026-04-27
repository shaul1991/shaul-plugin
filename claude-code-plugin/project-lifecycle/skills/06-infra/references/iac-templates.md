# IaC (Infrastructure as Code) 템플릿

---

## 1. Terraform 기본 구조

```
infrastructure/
├── main.tf              ← 메인 리소스 정의
├── variables.tf         ← 입력 변수 정의
├── outputs.tf           ← 출력 값 정의
├── providers.tf         ← 프로바이더 설정
├── terraform.tfvars     ← 변수 값 (gitignore 대상)
├── backend.tf           ← 상태 저장소 설정
├── modules/
│   ├── networking/      ← VPC, 서브넷 등
│   ├── compute/         ← EC2, ECS, Lambda 등
│   ├── database/        ← RDS, DynamoDB 등
│   └── monitoring/      ← CloudWatch, 알림 등
└── environments/
    ├── dev/
    │   └── terraform.tfvars
    ├── staging/
    │   └── terraform.tfvars
    └── prod/
        └── terraform.tfvars
```

---

## 2. Terraform - AWS 기본 템플릿

### providers.tf
```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
```

### variables.tf
```hcl
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 (dev/staging/prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment는 dev, staging, prod 중 하나여야 합니다."
  }
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}
```

### backend.tf (S3 + DynamoDB)
```hcl
terraform {
  backend "s3" {
    bucket         = "PROJECT-terraform-state"
    key            = "ENV/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
```

---

## 3. Terraform - ECS Fargate 서비스 모듈

```hcl
# modules/compute/ecs.tf

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = var.project_name
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = var.environment_variables

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-${var.environment}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])
}

resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.project_name
    container_port   = var.container_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}
```

---

## 4. Terraform - RDS 모듈

```hcl
# modules/database/rds.tf

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-${var.environment}"
  engine         = "postgres"
  engine_version = "16"
  instance_class = var.db_instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  multi_az               = var.environment == "prod" ? true : false
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = var.environment == "prod" ? 30 : 7
  deletion_protection     = var.environment == "prod" ? true : false
  skip_final_snapshot     = var.environment == "prod" ? false : true

  performance_insights_enabled = true
}
```

---

## 5. IaC 베스트 프랙티스

| 원칙 | 설명 |
|------|------|
| **DRY** | 모듈화하여 반복 제거 |
| **환경 분리** | 환경별 tfvars로 분리, 같은 코드 재사용 |
| **상태 관리** | 원격 백엔드 (S3, GCS) + 잠금 (DynamoDB) |
| **비밀 관리** | tfvars를 .gitignore에, Secrets Manager/Vault 사용 |
| **버전 고정** | 프로바이더, 모듈 버전 명시적 고정 |
| **코드 리뷰** | `terraform plan` 결과를 PR에 첨부 |
| **점진적 적용** | 한 번에 모든 인프라를 코드화하지 않음 |
| **태깅** | 모든 리소스에 Project, Environment, ManagedBy 태그 |

---

## 6. 대안 도구 비교

| 도구 | 특징 | 적합 시나리오 |
|------|------|-------------|
| Terraform | 멀티 클라우드, 가장 넓은 생태계 | 대부분의 프로젝트 |
| Pulumi | 프로그래밍 언어로 IaC | 개발자 친화적 필요 시 |
| AWS CDK | TypeScript/Python으로 AWS IaC | AWS 전용 프로젝트 |
| CloudFormation | AWS 네이티브 | AWS 전용, 간단한 구성 |

---

*프로젝트 규모와 요구사항에 맞는 IaC 도구를 선택하되, MVP에서는 단순하게 시작하라.*
