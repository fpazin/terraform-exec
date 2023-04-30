
provider "aws" {
  region                      = "us-west-2"
  access_key                  = "access_key"
  secret_key                  = "secret_key"
   # Credenciais para autenticação no AWS, onde a skip_credentials_validation e skip_requesting_account_id são definidas como verdadeiras 
  # para ignorar a validação das credenciais e solicitar o ID da conta.
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  s3_force_path_style         = true

  endpoints {
    lambda     = "http://localhost:4566"
    s3         = "http://localhost:4566"
    iam        = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "bucket01" {
  bucket = "bucket01"
}

# Adiciona um objeto ao bucket S3 para servir como página inicial.
resource "aws_s3_bucket_object" "index_html" {
  bucket       = aws_s3_bucket.bucket01.id
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
  acl          = "public-read"
}

# Adiciona um objeto ao bucket S3 para servir como página de times.
# resource "aws_s3_bucket_object" "times_html" {
#   bucket       = aws_s3_bucket.bucket01.id
#   key          = "timesJS.html"
#   source       = "timesJS.html"
#   content_type = "text/html"
#   acl          = "public-read"
# }

# Adiciona um objeto ao bucket S3 para servir como página de confrontos entre times.
# resource "aws_s3_bucket_object" "timesConfrontos_html" {
#   bucket       = aws_s3_bucket.bucket01.id
#   key          = "timesConfrontosJS.html"
#   source       = "timesConfrontosJS.html"
#   content_type = "text/html"
#   acl          = "public-read"
# }

# Cria uma política de acesso para a função Lambda.
resource "aws_iam_role" "myrole" {
  name = "myrole"

   assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [{
    	"Action": "sts:AssumeRole",
    	"Effect": "Allow",
    	"Sid": "",
      	"Principal": {
        	"Service": "lambda.amazonaws.com"
      	}
    }]
  }
  POLICY
}

# Cria uma função Lambda na AWS com o nome Myfunction e o runtime Python 3.7.
resource "aws_lambda_function" "Myfunction" {
  filename         = "lambda_function.zip"
  function_name    = "Myfunction"
  role             = aws_iam_role.myrole.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = filebase64sha256("lambda_function.zip")
  runtime          = "python3.7"
}

# Cria uma política de acesso para a função Lambda. Esta permite que o frontend invoque a funcao
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "lambda:InvokeFunction",
        Effect = "Allow",
        Resource = aws_lambda_function.Myfunction.arn,
        Principal = "*"
      }
    ]
  })
}

# Anexa a política criada anteriormente à função Lambda.
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.myrole.name
}

# Cria uma URL publica para a função Lambda criada anteriormente, apenas para testarmos, podemos acessar diretamente essa url sem necessidade de credenciais
resource "aws_lambda_function_url" "lambda_function_url" {
  function_name      = aws_lambda_function.Myfunction.arn
  authorization_type = "NONE"
}

# expomos a url no prompt do terraform para poder copiar
output "function_url" {
  description = "Function URL."
  value       = aws_lambda_function_url.lambda_function_url.function_url
}
