
terraform {
  cloud {
    organization = "example-org-193bbd"

    workspaces {
      name = "aws-main"
    }
  }
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "AWS Secret Access Key"
}

variable "AWS_ACCESS_KEY_ID" {
  description = "AWS Access Key ID"
}


provider "aws" {
  region     = "eu-north-1" # Replace with your desired region

  # Optional: If assuming a role
}


# Define AWS DynamoDB table
resource "aws_dynamodb_table" "example_table" {
  name     = "books"
  hash_key = "bookID"

  # Specify read and write capacity units for the table
  read_capacity  = 5
  write_capacity = 5
  attribute {
    name = "bookID"
    type = "N" # Assuming it's a number
  }

  attribute {
    name = "BookTitle"
    type = "S" # Assuming it's a string
  }

  global_secondary_index {
    name            = "Book_Title-index" # Use the correct index name
    projection_type = "ALL"              # Use the appropriate projection type (e.g., "ALL" or "INCLUDE")
    read_capacity   = 1                  # Set the read capacity units for the index
    write_capacity  = 1                  # Set the write capacity units for the inde
    hash_key        = "BookTitle"        # Use the correct attribute name for the index hash key

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
  handler       = "index.handler"
  runtime       = "nodejs16.x"
  role          = "arn:aws:iam::439975796198:role/dynamodb-lambda-access" # Reference to the IAM role for the Lambda function
  filename      = "lambda_functions/deployment/bookFunction-10569d13-726d-4f6b-8f1c-6da8f88648ef.zip"
}



# Define AWS API Gateway
resource "aws_api_gateway_rest_api" "book_api" {
  name        = "BookCatalogAPI"
  description = "API for managing book catalog data"
}



# Define API Gateway resource
resource "aws_api_gateway_resource" "book_api_resource" {
  parent_id   = aws_api_gateway_rest_api.book_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.book_api.id
  path_part   = "books" # Replace with the desired path for your resource
}


# Define a GET method for the /books resource
resource "aws_api_gateway_method" "get_books" {
  rest_api_id   = aws_api_gateway_rest_api.book_api.id
  resource_id   = aws_api_gateway_resource.book_api_resource.id
  http_method   = "GET"
  authorization = "NONE" # Or use a different authorization type if needed
}

# Define a POST method for the /books resource
resource "aws_api_gateway_method" "post_books" {
  rest_api_id   = aws_api_gateway_rest_api.book_api.id
  resource_id   = aws_api_gateway_resource.book_api_resource.id
  http_method   = "POST"
  authorization = "NONE" # Or use a different authorization type if needed
}

# Define a Lambda integration for the API Gateway Post Method
resource "aws_api_gateway_integration" "POST_integration" {
  rest_api_id             = aws_api_gateway_rest_api.book_api.id
  resource_id             = aws_api_gateway_resource.book_api_resource.id
  http_method             = aws_api_gateway_method.post_books.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.bookFunction.invoke_arn
}

# Define a Lambda integration for the API Gateway Get Method
resource "aws_api_gateway_integration" "GET_integration" {
  rest_api_id             = aws_api_gateway_rest_api.book_api.id
  resource_id             = aws_api_gateway_resource.book_api_resource.id
  http_method             = aws_api_gateway_method.get_books.http_method
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.bookFunction.invoke_arn
}


