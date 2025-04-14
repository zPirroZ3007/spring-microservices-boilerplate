data "aws_api_gateway_rest_api" "api_gateway" {
  name = ""
}

data "aws_api_gateway_resource" "api_resource" {
  path = "/api"
  rest_api_id = data.aws_api_gateway_rest_api.api_gateway.id
}

# Crea una risorsa all'interno dell'API Gateway esistente
resource "aws_api_gateway_resource" "resource" {
  rest_api_id = data.aws_api_gateway_rest_api.api_gateway.id  # Associa alla API esistente
  parent_id   = data.aws_api_gateway_resource.api_resource.id  # Root dell'API Gateway
  path_part   = "${element(split("-", var.prefix), 1)}"  # Il percorso della risorsa nell'API
}

resource "aws_api_gateway_method" "proxy_any" {
  rest_api_id   = data.aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy_integration" {
  rest_api_id             = data.aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.proxy_any.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${data.aws_lb.alb.dns_name}/${element(split("-", var.prefix), 1)}/{proxy+}"
}
