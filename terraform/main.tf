
provider "aws" {
  region = "eu-north-1" # Replace with your desired region
  # Optional: If assuming a role
  assume_role {
    role_arn = "arn:aws:iam::439975796198:role/terraform" # Replace with your IAM role ARN
  }
}



# Define IAM Role for Lambda Functions
resource "aws_iam_role" "dynamodb-lambda-access" {
    name = "dynamodb-lambda-access"

     assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
}

# Define AWS Lambda function
resource "aws_lambda_function" "bookFunction" {
  function_name = "bookFunction"
  handler      = "index.handler"
  runtime      = "nodejs16.x"
  role         = "arn:aws:iam::439975796198:role/dynamodb-lambda-access" # Reference to the IAM role for the Lambda function
  filename     = "terraform/lambda_functions/deployment/bookFunction-10569d13-726d-4f6b-8f1c-6da8f88648ef.zip"
}

# Define AWS API Gateway
resource "aws_api_gateway_rest_api" "crud_api" {
  name        = "crudApis"
  description = ""
}

# Define API Gateway resource
resource "aws_api_gateway_resource" "crud_api_resource" {
  parent_id   = aws_api_gateway_rest_api.crud_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.crud_api.id
  path_part   = "books"  # Replace with the desired path for your resource
}




# Define a Lambda integration for the API Gateway Post Method
resource "aws_api_gateway_integration" "POST_integration" {
  rest_api_id            = aws_api_gateway_rest_api.crud_api.id
  resource_id             = aws_api_gateway_resource.crud_api_resource.id
  http_method             = "POST"  # Change this to the HTTP method you want (e.g., "POST")
  integration_http_method = "POST"  # Change this to the desired integration HTTP method
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:execute-api:eu-north-1:439975796198:h6yo02og0c/*/POST/crud-operations"
}

# Define a Lambda integration for the API Gateway Get Method
resource "aws_api_gateway_integration" "GET_integration" {
  rest_api_id            = aws_api_gateway_rest_api.crud_api.id
  resource_id            = aws_api_gateway_resource.crud_api_resource.id
  http_method             = "GET"  # Change this to the HTTP method you want (e.g., "POST")
  integration_http_method = "GET"  # Change this to the desired integration HTTP method
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:execute-api:eu-north-1:439975796198:h6yo02og0c/*/GET/crud-operations"
}


# Define AWS DynamoDB table
resource "aws_dynamodb_table" "example_table" {
  name           = "books"
  hash_key       = "bookID"
  attribute {
    name = "bookID"
    type = "N"  # Assuming it's a number
  }

  attribute {
    name = "BookTitle"
    type = "S"  # Assuming it's a string
  }

  attribute {
    name = "Author"
    type = "S"  # Assuming it's a string
  }

  attribute {
    name = "Rating"
    type = "N"  # Assuming it's a number
  }

  attribute {
    name = "Genre"
    type = "S"  # Assuming it's a string
  }
}

