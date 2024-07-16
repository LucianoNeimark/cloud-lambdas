lambda_configs = [{
  name     = "estacionamientoCreate"
  handler  = "estacionamientoCreate.lambda_handler"
  runtime  = "python3.10"
  filename = "../lambdas/estacionamientoCreate.zip"
  variables = {
    table_name = "estacionamiento"
  }
  }, {
  name     = "estacionamientoGetByRegion"
  handler  = "estacionamientoGetByRegion.lambda_handler"
  runtime  = "python3.10"
  filename = "../lambdas/estacionamientoGetByRegion.zip"
  variables = {
    table_name = "estacionamiento",
    user_table = "users"
  }
  }, {
  name     = "estacionamientoGetById"
  handler  = "estacionamientoGetById.lambda_handler"
  runtime  = "python3.10"
  filename = "../lambdas/estacionamientoGetById.zip"
  variables = {
    table_name = "estacionamiento",
    user_table = "users"
  }
  }, {
  name     = "estacionamientoEditParking"
  handler  = "estacionamientoEditParking.lambda_handler"
  runtime  = "python3.10"
  filename = "../lambdas/estacionamientoEditParking.zip"
  variables = {
    table_name = "estacionamiento"
  }
  }, {
  name     = "estacionamientoOccupyLot"
  handler  = "estacionamientoOccupyLot.lambda_handler"
  runtime  = "python3.10"
  filename = "../lambdas/estacionamientoOccupyLot.zip"
  variables = {
    table_name = "estacionamiento",
    user_table = "users"
  }
  }, {
  name     = "estacionamientoFreeLot"
  handler  = "estacionamientoFreeLot.lambda_handler"
  runtime  = "python3.10"
  filename = "../lambdas/estacionamientoFreeLot.zip"
  variables = {
    table_name = "estacionamiento",
    user_table = "users"
  }
}]

api_endpoints = [
  {
    name                 = "estacionamientoCreate"
    method               = "POST"
    path                 = "/parking/{region}"
    lambda_name          = "estacionamientoCreate"
    authorization_scopes = []
  },
  {
    name                 = "estacionamientoGetByRegion"
    method               = "GET"
    path                 = "/parking/{region}"
    lambda_name          = "estacionamientoGetByRegion"
    authorization_scopes = []
  },
  {
    name                 = "estacionamientoGetById"
    method               = "GET"
    path                 = "/parking/{region}/{id}"
    lambda_name          = "estacionamientoGetById"
    authorization_scopes = []
  },
  {
    name                 = "estacionamientoEditParking"
    method               = "PATCH"
    path                 = "/parking/{region}/{id}"
    lambda_name          = "estacionamientoEditParking"
    authorization_scopes = []
  },
  {
    name                 = "estacionamientoOccupyLot"
    method               = "POST"
    path                 = "/parking/{region}/{id}/lot"
    lambda_name          = "estacionamientoOccupyLot"
    authorization_scopes = []
  },
  {
    name                 = "estacionamientoFreeLot"
    method               = "DELETE"
    path                 = "/parking/{region}/{id}/lot"
    lambda_name          = "estacionamientoFreeLot"
    authorization_scopes = []
  }
]

vpc = {
  vpc_cidr = "10.0.0.0/16"
  vpc_name = "estacionamiento-vpc"
  subnets = [
    {
      name       = "estacionamiento-private-1"
      cidr_block = "10.0.0.0/24"
    },
    {
      name       = "estacionamiento-private-2"
      cidr_block = "10.0.1.0/24"
    }
  ]
  public_subnets = [
    {
      name       = "estacionamiento-public-1"
      cidr_block = "10.0.2.0/24"
    },
    {
      name       = "estacionamiento-public-2"
      cidr_block = "10.0.3.0/24"
    }
  ]
}
